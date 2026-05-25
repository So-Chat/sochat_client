import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sochat_client/modules/users/user.dart';
import 'package:sochat_client/modules/websocket/message_packet.dart';
import 'package:sochat_client/modules/websocket/web_socket_service.dart';

import '../common/auth_service.dart';
import '../keys/key_service.dart';

final userServiceProvider = StateNotifierProvider<UserService, UserState>(
      (ref) => UserService(ref.read(webSocketProvider.future), ref.read(keyServiceProvider.notifier), ref.read(authServiceProvider), ref.read(currentUserProvider), ref),);


class UserState {

}

class UserService extends StateNotifier<UserState> {
  late final WebSocketService _webSocket;
  final KeyService _keyService;
  final AuthService _authService;
  final User? currentUser;

  final Ref ref;

  final Map<int, User> userBuffer = {};
  StreamSubscription? _subscription;

  UserService(Future<WebSocketService> webSocketFuture, this._keyService, this._authService, this.currentUser, this.ref)
      : super(UserState()) {
    webSocketFuture.then((ws) {
      _webSocket = ws;
      startListen();
    }).catchError((error) {
      throw Exception("WebSocket initialization in ChatService fall in error!\nstacktrace: $error");
    });
  }

  void startListen() {
    _subscription = _webSocket.usersMessages.listen((message) {

    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<User> getUser({String? username, int? id, bool? forceUpdate = true}) async {
    if (currentUser!.id == id){
      return currentUser!;
    }
    if (id != null) {
      return await _getUserById(id, forceUpdate: forceUpdate);
    } else if (username != null) {
      return await _getUserByUsername(username, forceUpdate: forceUpdate);
    }
    throw ArgumentError('Either id or username must be provided');
  }

  Future<User> _getUserByUsername(String username, {bool? forceUpdate = true}) async {
    if (userBuffer.values.any((u) => u.username != username) && forceUpdate == false){
      return userBuffer.values.firstWhere((u) => u.username == username);
    }

    MessagePacket message = MessagePacket(type: "user_get", payload: {
      "username": username,
    });


    MessagePacket request = await _webSocket.sendRequest(message);
    final userMap = jsonDecode(request.payload["user"]) as Map<String, dynamic>;
    User user = User.fromJson(userMap);
    user.x25519PublicKey = userMap["x25519PublicKey"];

    userBuffer[user.id] = user;

    return user;
  }
  Future<User> _getUserById(int id, {bool? forceUpdate = true}) async {
    if (userBuffer[id] != null && forceUpdate == false){
      return userBuffer[id]!;
    }

    MessagePacket message = MessagePacket(type: "user_get", payload: {
      "id": id,
    });

    MessagePacket request = await _webSocket.sendRequest(message);
    final userMap = jsonDecode(request.payload["user"]) as Map<String, dynamic>;
    User user = User.fromJson(userMap);
    user.x25519PublicKey = userMap["x25519PublicKey"];

    userBuffer[user.id] = user;

    return user;
  }

  Future<void> changeProfile(String? nickname, String? username, String? description) async {

    MessagePacket message = MessagePacket(type: "user_update_profile", payload: {
      "nickname": nickname,
      "username": username,
      "description": description,
    });

    MessagePacket request = await _webSocket.sendRequest(message);
    if (request.payload["success"] == true){
      ref.read(currentUserProvider.notifier).state = currentUser!.copyWith(
        username: request.payload["username"],
        nickname: request.payload["nickname"],
        description: request.payload["description"],
      );
    }
  }
}
