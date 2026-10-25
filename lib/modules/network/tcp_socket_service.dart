import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/context/notifications/inapp_notifications_manager.dart';
import 'package:sochat_client/extenstions/utils.dart';
import 'package:sochat_client/modules/keys/key.dart';
import 'package:sochat_client/modules/keys/key_service.dart';
import 'package:sochat_client/modules/network/packet_handler.dart';
import 'package:sochat_client/modules/network/tcp_frame_handler.dart';
import 'package:sochat_client/modules/users/user.dart';
import 'package:sochat_client/modules/users/user_service.dart';
import 'package:sochat_client/modules/network/message_packet.dart';

final tcpSocketProvider = FutureProvider<TcpSocketService>((ref) {
  final service = TcpSocketService(ref, ref.read(keyServiceProvider.notifier));

  ref.onDispose(() {
    service.dispose();
  });
  return service;
});


class TcpSocketService{
  Socket? socket;

  final RequestIdGenerator _requestIdGenerator = RequestIdGenerator();

  final _friendsController = StreamController<MessagePacket>.broadcast();
  Stream<MessagePacket> get friendsMessages => _friendsController.stream;

  final _chatsController = StreamController<MessagePacket>.broadcast();
  Stream<MessagePacket> get chatsMessages => _chatsController.stream;

  final _usersController = StreamController<MessagePacket>.broadcast();
  Stream<MessagePacket> get usersMessages => _usersController.stream;

  final _messagesController = StreamController<MessagePacket>.broadcast();
  Stream<MessagePacket> get messagesMessages => _messagesController.stream;

  final _callController = StreamController<MessagePacket>.broadcast();
  Stream<MessagePacket> get callMessages => _callController.stream;

  final _pingPongController = StreamController<int>.broadcast();
  Stream<int> get pingPongMessages => _pingPongController.stream;

  final _pendingRequests = <int, Completer>{};
  Timer? _pingTimer;
  final Ref _ref;
  final KeyService _keyService;

  TcpSocketService(this._ref, this._keyService);

  void dispose() {
    _pingTimer?.cancel();
    _pendingRequests.clear();

    _friendsController.close();
    _chatsController.close();
    _usersController.close();
    _messagesController.close();
    _callController.close();

    socket?.destroy();
    socket = null;
  }

  void disconnect() {
    if (socket != null) {
      socket?.destroy();

    }
    if (_pingTimer != null && _pingTimer!.isActive){
      _pingTimer!.cancel();
    }
    socket = null;

  }

  Future<void> connect() async {
    String socketIp = "${_keyService.servers.entries.toList()[_ref.read(keyServiceProvider).selectedServer].value}";
    if (socket != null) { return; }

    try {
      socket = await Socket.connect(
          socketIp.split(":")[0], int.parse(socketIp.split(":")[1])
      );

      final packetHandler = PacketHandler(
        friendsController: _friendsController,
        chatsController: _chatsController,
        messagesController: _messagesController,
        callController: _callController,
        pingPongController: _pingPongController,
        notificationsManager: _ref.read(inAppNotificationsManagerProvider.notifier),
        pendingRequests: _pendingRequests,
        keyService: _keyService
      );

      pingPongMessages.listen((id) {
        switch (id) {
          case 0x01: addBytesToSink(Uint8List.fromList([0x02]), encryption: true); break;
          case 0x02: //addBytesToSink(Uint8List.fromList([0x01])); break;
        }
      });

      final tcpFrameHandler = TcpFrameHandler(socket!);
      tcpFrameHandler.packetStream.listen((rawData) async {
        packetHandler.handleIncomingData(rawData);
      }, onDone: () {
        socket?.destroy;
        socket = null;
        debugPrint("Connection done");
      }, onError: (e, st) {
        socket?.destroy;
        socket = null;
        debugPrint("WS ERROR: $e");
      });
    } catch (e) {
      socket?.destroy;
      socket = null;
    }
  }


  Future<void> addBytesToSink(Uint8List bytes, {bool encryption = false}) async {
    if (socket == null) return;

    final lengthBuffer = Uint8List(4);
    List<int> finalBytes = bytes;

    if (encryption) {
      if (_keyService.sessionKey == null) {
        _keyService.updateSessionKey(await handshake());
      }
      finalBytes = await _keyService.encryptWithAes(bytes, _keyService.sessionKey!);
    }

    ByteData.sublistView(lengthBuffer).setUint32(0, finalBytes.length, Endian.big);

    socket!.add(lengthBuffer);
    socket!.add(finalBytes);
  }

  Future<void> addToSink(MessagePacket messagePacket) async {
    if (socket == null) {
      return;
    }

    final messageBytes = utf8.encode(jsonEncode(messagePacket.toJson()));
    final requestIdBytes = Utils.encodeRequestId(messagePacket.requestId);

    final bytes = Uint8List.fromList([
      0x03,
      ...messageBytes,
      ...requestIdBytes,
    ]);
    await addBytesToSink(bytes, encryption: true);
  }


  Future<Uint8List> sendBytesRequest(Uint8List bytes, {int duration = 1, bool encryption = false}) async {
    final requestId = _requestIdGenerator.nextId();
    final completer = Completer<Uint8List>();
    _pendingRequests[requestId] = completer;

    final requestIdBytes = Utils.encodeRequestId(requestId);

    final packet = Uint8List.fromList([
      ...bytes,
      ...requestIdBytes
    ]);
    await addBytesToSink(packet, encryption: encryption);

    return completer.future.timeout(
      Duration(minutes: duration),
      onTimeout: () {
        _pendingRequests.remove(requestId);
        throw TimeoutException("Request $requestId timed out after $duration minutes");
      },
    );

  }

  Future<MessagePacket> sendRequest(MessagePacket messagePacket, {int duration = 1}) async {
    final requestId = _requestIdGenerator.nextId();
    final completer = Completer<MessagePacket>();
    _pendingRequests[requestId] = completer;

    // Use only if need to debug what client sends to server, cuz it makes a mess from logs
    //print(messagePacket.toJson().toString());

    messagePacket.requestId = requestId;

    await addToSink(messagePacket);
    return completer.future.timeout(
      Duration(minutes: duration),
      onTimeout: () {
        _pendingRequests.remove(requestId);
        throw TimeoutException("Request $requestId timed out after 5 minutes");
      },
    );
  }

  Future<User> authenticate(String token) async {
    MessagePacket message = MessagePacket(type: "authenticate", payload: {
      "token": token,
    });
    MessagePacket request = await sendRequest(message);

    var userMap = jsonDecode(request.payload["user"]) as Map<String, dynamic>;
    User user = await _ref.read(userServiceProvider).resolveUser(userMap);

    _friendsController.add(request);
    return user;
  }

  /*
    TODO: Manage handshake without creating a variable for it
  */
  Future<List<int>> handshake() async {
    final ephermalKeyPair = await KeyP.generate();

    final serverPublicKeyBytes = await sendBytesRequest(
      Uint8List.fromList(ephermalKeyPair.publicKeyX!),
    );
    debugPrint("success handshake");
    return _keyService.confirmHandshake(ephermalKeyPair, serverPublicKeyBytes);

  }
}

class RequestIdGenerator {
  int _currentId = 1;

  int nextId() {
    if (_currentId >= 0x7FFFFFFF) {
      _currentId = 1;
    }
    return ++_currentId;
  }
}
