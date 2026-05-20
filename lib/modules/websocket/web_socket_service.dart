import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/context/notifications/inapp_notifications_manager.dart';
import 'package:sochat_client/modules/common/auth_service.dart';
import 'package:sochat_client/modules/keys/key_service.dart';
import 'package:sochat_client/modules/users/user.dart';
import 'package:sochat_client/modules/websocket/message_packet.dart';
import 'package:sochat_client/so_ui/notifications/so_notification.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

final webSocketProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService(ref, ref.read(keyServiceProvider.notifier));

  ref.onDispose(() {
    service.dispose();
  });
  return service;
});


class WebSocketService{
  IOWebSocketChannel? channel;

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
  Ref _ref;
  KeyService _keyService;

  WebSocketService(this._ref, this._keyService);

  void dispose() {
    _pingTimer?.cancel();
    _pendingRequests.clear();

    _friendsController.close();
    _chatsController.close();
    _usersController.close();
    _messagesController.close();
    _callController.close();

    channel?.sink.close(1000);
    channel = null;
  }

  void disconnect() {
    if (channel != null) {
      channel!.sink.close(1000);

    }
    if (_pingTimer != null && _pingTimer!.isActive){
      _pingTimer!.cancel();
    }
    channel = null;

  }

  Future<void> connect() async {

    String webSocketIp = "ws${_keyService.servers.entries.toList()[_ref.read(selectedServerProvider)].value.substring(4)}/ws";

    channel = IOWebSocketChannel.connect(
        Uri.parse(webSocketIp), pingInterval: Duration(seconds: 10)
    );

    await channel!.ready;

    // Maybe delete pinging later, i will use low-level pings
    //_startPing();

    channel!.stream.listen((message) {
      MessagePacket messagg = MessagePacket.fromJson(jsonDecode(message));

      if (messagg.type != "pong") print("WS RAW MESSAGE: $message");

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

      if (messagg.payload["success"] == "false"){
        _ref.read(inAppNotificationsManagerProvider.notifier).addUpdate(
          SoNotification(
            icon: Icons.error_outline,
            title: "Unhandled request Error",
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
          print("Необработанный тип: ${messagg.type}");
      }
    });
  }



  void addToSink(WebSocketChannel? channel, Map<String, dynamic> message) {
    if (channel == null) {
      return;
    }
    channel.sink.add(jsonEncode(message));
  }

  Future<dynamic> sendRequest(MessagePacket messagePacket, {int duration = 5}) {
    final requestId = _requestIdGenerator.nextId();
    final completer = Completer();
    _pendingRequests[requestId] = completer;

    print(messagePacket.toJson().toString());

    messagePacket.payload["requestId"] = requestId;

    addToSink(channel!, messagePacket.toJson());
    return completer.future.timeout(
      Duration(minutes: duration),
      onTimeout: () {
        _pendingRequests.remove(requestId);
        throw TimeoutException("Request $requestId timed out after 5 minutes");
      },
    );
  }


  void _startPing() async {
    if (channel == null) return;

    _pingTimer = Timer.periodic(
      const Duration(seconds: 10),
          (_) async {
        MessagePacket message = MessagePacket(type: "ping", payload: {});
        Stopwatch stopwatch = Stopwatch()..start();

        try {
          await sendRequest(message, duration: 1);
          stopwatch.stop();
          if (stopwatch.elapsed.inSeconds >= 10) {
            print("Ping took longer than 10 seconds, freezing...");

            Timer(Duration(minutes: 4), () {
              print("4 minutes passed, unfreezing system...");
            });
          } else {
            print("Ping was successful in ${stopwatch.elapsed.inSeconds} seconds");
          }
        } catch (e) {
          stopwatch.stop();
          print("Ping failed or timed out: $e");
        }
      },
    );
  }


  Future<void> authenticate(String token) async {
    MessagePacket message = MessagePacket(type: "authenticate", payload: {
      "token": token,
    });
    MessagePacket request = await sendRequest(message);

    var user = jsonDecode(request.payload["user"]) as Map<String, dynamic>;
    _ref.read(currentUserProvider.notifier).state = User(id: user["id"],
        nickname: user["nickname"],
        username: user["username"],
        description: user["description"],
        x25519PublicKey: user["x25519PublicKey"]);

    _friendsController.add(request);
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
