import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/context/notifications/inapp_notifications_manager.dart';
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

  final _pendingRequests = <String, Completer>{};
  Timer? _pingTimer;
  final Ref _ref;
  final KeyService _keyService;

  SecretKey? aesKey;
  Completer handshakeCompleter = Completer();

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

    socket!.listen((dataWithLength) async {
      // TODO: MAKE ACTUALLY LISTENING BYTES
      Uint8List data = dataWithLength.sublist(4);

      debugPrint("RAW BYTE MESSAGE: $data");
      if (data.length <= 64) {
        handshakeCompleter.complete(Uint8List.fromList(data));
        return;
      }
      if (aesKey == null) return;

      final decryptData = await _keyService.decryptWithAes(data, aesKey!);

      String message = utf8.decode(decryptData);

      debugPrint("RAW MESSAGE: $message");
      MessagePacket messagg = MessagePacket.fromJson(jsonDecode(message));

      final requestId = messagg.payload["requestId"];
      if (requestId != null && _pendingRequests.containsKey(requestId)) {
        final safePayload = Map<String, dynamic>.from(messagg.payload);

        messagg = MessagePacket(
          type: messagg.type,
          payload: safePayload,
        );
        _pendingRequests[requestId]!.complete(messagg);
        _pendingRequests.remove(requestId);
      }

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
    },
        onDone: () {
      debugPrint("Connection done");
    }, onError: (e, st) {
          debugPrint("WS ERROR: $e");
        });

    aesKey = SecretKey(await handshake());
  }

  Future<void> addBytesToSink(Uint8List bytes, {withLength = true}) async {
    if (socket == null) {
      return;
    }
    if (withLength) {
      int length = bytes.length;
      Uint8List lengthBuffer = Uint8List(4);
      ByteData.view(lengthBuffer.buffer).setInt32(0, length, Endian.big);

      socket!.add(lengthBuffer);
    }
    socket!.add(bytes);
  }

  Future<void> addToSink(Map<String, dynamic> message) async {
    if (socket == null) {
      return;
    }
    Uint8List messageBytes = utf8.encode(jsonEncode(message));

    debugPrint("Sending map: $message");

    final cipherMessageBytes = await _keyService.encryptWithAes(messageBytes, aesKey!);
    await addBytesToSink(Uint8List.fromList(cipherMessageBytes));
  }


  Future<dynamic> sendRequest(MessagePacket messagePacket, {int duration = 5}) async {
    final requestId = _requestIdGenerator.nextId();
    final completer = Completer();
    _pendingRequests[requestId] = completer;

    // Use only if need to debug what client sends to server, cuz it makes a mess from logs
    //print(messagePacket.toJson().toString());

    messagePacket.payload["requestId"] = requestId;

    await addToSink(messagePacket.toJson());
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

  Future<List<int>> handshake() async {
    final ephermalKeyPair = await KeyP.generate();

    final completer = Completer<Uint8List>();
    handshakeCompleter = completer;

    await addBytesToSink(
      Uint8List.fromList(ephermalKeyPair.publicKeyX!),
      withLength: true,
    );

    final serverPublicKeyBytes = await completer.future.timeout(
      const Duration(seconds: 5),
    );

    final algorithm = X25519();

    final sharedSecret = await algorithm.sharedSecretKey(
      keyPair: await ephermalKeyPair.getX25519KeyPair(),
      remotePublicKey: SimplePublicKey(serverPublicKeyBytes, type: KeyPairType.x25519),
    );

    final sharedSecretBytes = await sharedSecret.extractBytes();

    return await _keyService.deriveAesKey(sharedSecretBytes);
  }
}

class RequestIdGenerator {
  int _counter = 0;

  String nextId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    _counter++;
    return '$timestamp-$_counter';
  }
}
