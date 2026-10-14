import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/context/notifications/inapp_notifications_manager.dart';
import 'package:sochat_client/extenstions/utils.dart';
import 'package:sochat_client/modules/keys/key.dart';
import 'package:sochat_client/modules/keys/key_service.dart';
import 'package:sochat_client/modules/users/user.dart';
import 'package:sochat_client/modules/users/user_service.dart';
import 'package:sochat_client/modules/network/message_packet.dart';
import 'package:sochat_client/so_ui/notifications/so_notification.dart';

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

  final _pendingRequests = <int, Completer>{};
  Timer? _pingTimer;
  final Ref _ref;
  final KeyService _keyService;

  SecretKey? aesKey;

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
    // pingInterval: Duration(seconds: 10)
    if (socket != null) { return; }

    socket = await Socket.connect(
        socketIp.split(":")[0], int.parse(socketIp.split(":")[1])
    );

    // Maybe delete pinging later, i will use low-level pingsr
    //_startPing();

    socket!.listen((fullData) async {
      // TODO: MAKE ACTUALLY LISTENING BYTES
      final rawDataLength = fullData.length - 4;
      final rawDataWithRequestId = fullData.sublist(4);

      if (aesKey == null) {
        final data = rawDataWithRequestId.sublist(0, rawDataLength - 4);
        final requestId = ByteData.sublistView(rawDataWithRequestId.sublist(rawDataLength - 4)).getUint32(0);

        if (requestId != 0 && _pendingRequests.containsKey(requestId)) {
          if (_pendingRequests[requestId] is Completer<Uint8List>) {
            _pendingRequests[requestId]!.complete(data);
            _pendingRequests.remove(requestId);
            return;
          }
        } else {
          final pending = _pendingRequests.remove(requestId);
          if (pending != null && !pending.isCompleted) {
            pending.completeError(
              StateError('Unexpected response type for request $requestId'),
            );
          }
          return;
        }
      } else {
        final decryptDataWithRequestId = await _keyService.decryptWithAes(rawDataWithRequestId, aesKey!);
        final decryptData = Uint8List.fromList(decryptDataWithRequestId);

        if (decryptData.length < 4) {
          throw const FormatException('Packet too short');
        }
        debugPrint("$decryptData");
        final dataLength = decryptData.length - 4;
        final data = decryptData.sublist(0, dataLength);

        final requestId = ByteData.sublistView(
          decryptData,
          dataLength,
        ).getUint32(0, Endian.big);

        MessagePacket? messagg;

        if (requestId != 0 && _pendingRequests.containsKey(requestId)) {
          if (_pendingRequests[requestId] is Completer<MessagePacket>) {
            final message = utf8.decode(data);
            debugPrint("RAW MESSAGE: $message");
            messagg = MessagePacket.fromJson(jsonDecode(message));
            debugPrint("got packet with request: ${messagg.toJson()}");
            final safePayload = Map<String, dynamic>.from(messagg.payload);

            messagg = MessagePacket(
              requestId: requestId,
              type: messagg.type,
              payload: safePayload,
            );
            _pendingRequests[requestId]!.complete(messagg);
            _pendingRequests.remove(requestId);
          } else if (_pendingRequests[requestId] is Completer<Uint8List>) {
            _pendingRequests[requestId]!.complete(data);
            _pendingRequests.remove(requestId);
            return;
          } else {
            final pending = _pendingRequests.remove(requestId);
            if (pending != null && !pending.isCompleted) {
              pending.completeError(
                StateError('Unexpected response type for request $requestId'),
              );
            }
            return;
          }
        } else {
          final message = utf8.decode(data);
          messagg = MessagePacket.fromJson(jsonDecode(message));

          debugPrint("packet $message");
          if (messagg.payload["success"] == false){
            _ref.read(inAppNotificationsManagerProvider.notifier).addUpdate(
              SoNotification(
                icon: Icons.error_outline,
                title: "Error",
                content: messagg.payload["server_message"],
              ),
            );
          }

          switch (messagg.type) {
            case "friend_request":
            case "friend_accept":
            case "friend_decline":
            case "friend_remove":
            case "block": {
              _friendsController.add(messagg);
              break;
            }
            case "authenticate":
            case "chat_create":
            case "chat_add_participant":
            case "chat_delete": {
              _chatsController.add(messagg);
              break;
            }
            case "message_send":
            case "message_edit":
            case "message_read":
            case "message_delete":{
              _messagesController.add(messagg);
              break;
            }
            case "call_end":
            case "call_ice":
            case "call_offer":
            case "call_answer":
            case "call_accept":{
                _callController.add(messagg);
                break;
            }
            default:
              //debugPrint("Unhandled type: ${messagg.type}");
          }
        }
      }
    },
        onDone: () {
      debugPrint("Connection done");
    }, onError: (e, st) {
          debugPrint("WS ERROR: $e");
        });

    aesKey = SecretKey(await handshake());
  }

  Future<void> addBytesToSink(Uint8List bytes) async {
    if (socket == null) return;

    final lengthBuffer = Uint8List(4);
    ByteData.sublistView(lengthBuffer).setUint32(0, bytes.length, Endian.big);

    socket!.add(lengthBuffer);
    socket!.add(bytes);
  }

  Future<void> addToSink(MessagePacket messagePacket) async {
    if (socket == null) {
      return;
    }

    final messageBytes = utf8.encode(jsonEncode(messagePacket.toJson()));
    final requestIdBytes = Utils.encodeRequestId(messagePacket.requestId);



    final bytes = Uint8List.fromList([
      ...messageBytes,
      ...requestIdBytes,
    ]);

    final cipherMessageBytes = await _keyService.encryptWithAes(bytes, aesKey!);
    await addBytesToSink(Uint8List.fromList(cipherMessageBytes));
  }


  Future<Uint8List> sendBytesRequest(Uint8List bytes, {int duration = 1, bool encryption = false}) async {
    final requestId = _requestIdGenerator.nextId();
    final completer = Completer<Uint8List>();
    _pendingRequests[requestId] = completer;

    final requestIdBytes = Utils.encodeRequestId(requestId);

    debugPrint("sent bytes $bytes");

    final packet = Uint8List.fromList([
      ...bytes,
      ...requestIdBytes
    ]);
    if (encryption) {
      final cipherMessageBytes = await _keyService.encryptWithAes(packet, aesKey!);
      await addBytesToSink(Uint8List.fromList(cipherMessageBytes));
    }
    else {
      await addBytesToSink(packet);
    }

    return completer.future.timeout(
      Duration(minutes: duration),
      onTimeout: () {
        _pendingRequests.remove(requestId);
        throw TimeoutException("Request $requestId timed out after 5 minutes");
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
