import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/context/notifications/inapp_notifications_manager.dart';
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
    socket = await Socket.connect(
        socketIp.split(":")[0], int.parse(socketIp.split(":")[1])
    );

    // Maybe delete pinging later, i will use low-level pings
    //_startPing();

    socket!.listen((data) {
      // TODO: MAKE ACTUALLY LISTENING BYTES
      //debugPrint("RAW BYTE MESSAGE: $data");
      String message = utf8.decode(data.sublist(4));
      debugPrint("RAW MESSAGE: $message");
      MessagePacket messagg = MessagePacket.fromJson(jsonDecode(message));

      debugPrint("PACKET RECEIVED: ${messagg.type}");
      debugPrint("PAYLOAD TYPE: ${messagg.payload.runtimeType}");

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
  }



  void addToSink(Map<String, dynamic> message) {
    if (socket == null) {
      return;
    }
    Uint8List messageBytes = utf8.encode(jsonEncode(message));
    int length = messageBytes.length;

    Uint8List lengthBuffer = Uint8List(4);
    ByteData.view(lengthBuffer.buffer).setInt32(0, length, Endian.big);

    socket!.add(lengthBuffer);
    socket!.add(messageBytes);
  }

  Future<dynamic> sendRequest(MessagePacket messagePacket, {int duration = 5}) {
    final requestId = _requestIdGenerator.nextId();
    final completer = Completer();
    _pendingRequests[requestId] = completer;

    // Use only if need to debug what client sends to server, cuz it makes a mess from logs
    //print(messagePacket.toJson().toString());

    messagePacket.payload["requestId"] = requestId;

    addToSink(messagePacket.toJson());
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
}

class RequestIdGenerator {
  int _counter = 0;

  String nextId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    _counter++;
    return '$timestamp-$_counter';
  }
}
