import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/modules/keys/key_service.dart';
import 'package:sochat_client/modules/media/media_service.dart';
import 'package:sochat_client/modules/users/user.dart';
import 'package:sochat_client/modules/websocket/message_packet.dart';
import 'package:sochat_client/modules/websocket/web_socket_service.dart';

import '../common/auth_service.dart';

final userServiceProvider = Provider<UserService>(
  (ref) => UserService(
    ref.read(webSocketProvider.future),
    ref.read(mediaServiceProvider),
    ref.read(authServiceProvider.notifier),
    ref,
  ),
);

class UserService {
  late final WebSocketService _webSocket;
  late final MediaService _mediaService;
  late final AuthService _authService;

  final Ref ref;

  get currentUser => _authService.currentUser;

  final Map<int, User> userBuffer = {};
  StreamSubscription? _subscription;

  UserService(
    Future<WebSocketService> webSocketFuture,
    MediaService mediaService,
    AuthService authService,
    this.ref,
  ) {
    ref.onDispose(() {
      _subscription?.cancel();
    });

    webSocketFuture
        .then((ws) {
          _webSocket = ws;
          startListen();
        })
        .catchError((error) {
          throw Exception(
            "WebSocket initialization in ChatService fall in error!\nstacktrace: $error",
          );
        });

    _mediaService = mediaService;
    _authService = authService;
  }

  void startListen() {
    _subscription = _webSocket.usersMessages.listen((message) {});
  }

  Future<User> getUser({
    String? username,
    int? id,
    bool? forceUpdate = true,
    bool withAvatar = true,
  }) async {
    if (currentUser!.id == id) {
      return currentUser!;
    }
    if (id != null) {
      User user = await _getUserById(id, forceUpdate: forceUpdate, withAvatar: withAvatar);
      return user;
    } else if (username != null) {
      User user = await _getUserByUsername(username, forceUpdate: forceUpdate, withAvatar: withAvatar);
      return user;
    }
    throw ArgumentError('Either id or username must be provided');
  }

  Future<User> _getUserByUsername(
    String username, {
    bool? forceUpdate = true,
    bool withAvatar = true,
  }) async {
    if (userBuffer.values.any((u) => u.username != username) &&
        forceUpdate == false) {
      return userBuffer.values.firstWhere((u) => u.username == username);
    }

    MessagePacket message = MessagePacket(
      type: "user_get",
      payload: {"username": username},
    );

    MessagePacket request = await _webSocket.sendRequest(message);
    final userMap = jsonDecode(request.payload["user"]) as Map<String, dynamic>;

    User user = await resolveUser(userMap, withAvatar: withAvatar);
    return user;
  }

  Future<User> _getUserById(int id, {bool? forceUpdate = true, bool withAvatar = true}) async {
    if (userBuffer[id] != null && forceUpdate == false) {
      return userBuffer[id]!;
    }

    MessagePacket message = MessagePacket(
      type: "user_get",
      payload: {"id": id},
    );

    MessagePacket request = await _webSocket.sendRequest(message);
    final userMap = jsonDecode(request.payload["user"]) as Map<String, dynamic>;

    User user = await resolveUser(userMap, withAvatar: withAvatar);
    return user;
  }

  Future<void> changeProfile(
    String? nickname,
    String? username,
    String? description,
    String? avatarId,
    {bool withAvatar = true}
  ) async {
    MessagePacket message = MessagePacket(
      type: "user_update_profile",
      payload: {
        "nickname": nickname,
        "username": username,
        "description": description,
        "avatar_id": avatarId,
      },
    );

    MessagePacket request = await _webSocket.sendRequest(message);
    if (request.payload["success"] == true) {
      ref
          .read(authServiceProvider.notifier)
          .setCurrentUser(
            currentUser!.copyWith(
              username: request.payload["username"],
              nickname: request.payload["nickname"],
              description: request.payload["description"],
              avatarId: request.payload["avatar_id"],
            ),
          );
      await loadAvatar(currentUser!);
    }
  }

  Future<User> resolveUser(Map<String, dynamic> userMap, {bool withAvatar = true}) async {
    User user = User.fromJson(userMap);
    user.x25519PublicKey = userMap["x25519PublicKey"];

    if (withAvatar) {
      await loadAvatar(user);
    }

    userBuffer[user.id] = user;
    return user;
  }

  Future<List<User>> searchUser(String query) async {
    final request = await _webSocket.sendRequest(
      MessagePacket(type: "search_user", payload: {"username": query}),
    );

    if (request.payload["success"] != false) {
      final List<User> users = [];

      //return request.payload["users"];
      final usersMap = jsonDecode(request.payload["users"]);
      for (var value in usersMap) {
        User user = await resolveUser(value);
        users.add(user);
      }
      return users;
    } else {
      return [];
    }
  }

  Future<void> loadAvatar(User user) async {
    final avatarId = user.avatarId;

    if (avatarId == null || avatarId.isEmpty) {
      return;
    }
    final ip = ref.read(keyServiceProvider).servers.entries.toList()[ref.read(keyServiceProvider).selectedServer].value;
    user.avatarBytes = await _mediaService.resolveMediaBytes(ip, avatarId);
  }

  Future<void> deleteUser() async {
    final request = await _webSocket.sendRequest(
      MessagePacket(type: "user_delete", payload: {}),
    );
  }
}
