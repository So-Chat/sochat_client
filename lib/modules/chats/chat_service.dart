import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/so_exception.dart';
import 'package:sochat_client/modules/calls/call_state.dart';
import 'package:sochat_client/modules/chats/chat.dart';
import 'package:sochat_client/modules/chats/chat_role.dart';
import 'package:sochat_client/modules/chats/chat_type.dart';
import 'package:sochat_client/modules/chats/participant.dart';
import 'package:sochat_client/modules/chats/sender_key.dart';
import 'package:sochat_client/modules/messages/message.dart';
import 'package:sochat_client/modules/messages/message_service.dart';
import 'package:sochat_client/modules/users/user_service.dart';
import 'package:sochat_client/modules/websocket/message_packet.dart';
import 'package:sochat_client/modules/users/user.dart';
import 'package:sochat_client/modules/websocket/web_socket_service.dart';

import '../common/auth_service.dart';
import '../keys/key_service.dart';

final chatsServiceProvider =
    NotifierProvider<ChatService, ChatsState>(
  ChatService.new,
);

class ChatsState {
  final List<Chat> chatList;

  const ChatsState({required this.chatList});

  ChatsState copyWith({List<Chat>? chats}) {
    return ChatsState(chatList: chats ?? chatList);
  }
}

class ChatService extends Notifier<ChatsState> {
  late final WebSocketService _webSocket;
  late final KeyService _keyService;
  late final UserService _userService;

  User? get currentUser => ref.read(authServiceProvider).currentUser;

  List<Chat> get chatList => state.chatList;

  @override
  ChatsState build() {
    _keyService = ref.read(keyServiceProvider.notifier);
    _userService = ref.read(userServiceProvider);

    ref.watch(webSocketProvider.future).then((ws) {
      _webSocket = ws;
      startListen();
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return const ChatsState(
      chatList: [],
    );
  }

  StreamSubscription? _subscription;

  void startListen() {
    _subscription = _webSocket.chatsMessages.listen((message) async {
      switch (message.type) {
        case ("authenticate"):
          getChatList();
          break;
        case ("chat_add_participant"):
        case ("chat_create"):
          {
            addUpdate(await receiveChat(jsonDecode(message.payload["chat"])));
            break;
          }
        case ("chat_delete"):
          {
            remove(
              (await receiveChat(jsonDecode(message.payload["chat"]))).title,
            );
            break;
          }
        case ("chat_leave"):
          {
            Chat chat = await receiveChat(jsonDecode(message.payload["chat"]));
            if (!chat.participants.any((p) => p.user.id == currentUser!.id)) {
              remove(chat.title);
            }
            break;
          }
      }
    });
  }

  void remove(String chatName) {
    final newList = List<Chat>.from(chatList);

    newList.removeWhere((chat) => chat.title == chatName);

    state = state.copyWith(chats: newList);
  }

  void addUpdate(Chat chat) {
    final newList = List<Chat>.from(chatList);
    final index = newList.indexWhere((c) => c.id == chat.id);

    if (index >= 0) {
      newList[index] = chat;
    } else {
      newList.add(chat);
    }

    state = state.copyWith(chats: newList);
  }

  Future<void> getChatList() async {
    MessagePacket message = MessagePacket(type: "chat_list", payload: {});
    MessagePacket request = await _webSocket.sendRequest(message);

    final List<Map<String, dynamic>> chatList =
        (jsonDecode(request.payload['chats']) as List)
            .cast<Map<String, dynamic>>();

    for (var c in chatList) {
      addUpdate(await receiveChat(c));
    }
  }

  Future<Chat> getChatByName(String username) async {
    if (chatList.any((c) => c.title == username)) {
      Chat localChat = chatList.firstWhere((c) => c.title == username);
      if (ref.read(messageServiceProvider).messageMap[localChat.id]!.length > 1) {
        return localChat;
      }
    }

    MessagePacket message = MessagePacket(
      type: "chat_get",
      payload: {"participant_username": username},
    );
    MessagePacket request = await _webSocket.sendRequest(message);

    Chat chat = await receiveChat(jsonDecode(request.payload["chat"]));

    addUpdate(chat);
    return chat;
  }

  Future<Chat> getChatById(int id) async {
    if (chatList.any((c) => c.id == id)) {
      Chat localChat = chatList.firstWhere((c) => c.id == id);
      if (ref.read(messageServiceProvider).messageMap.containsKey(id) &&
          ref.read(messageServiceProvider).messageMap[id]!.length > 1) {
        return localChat;
      }
    }

    MessagePacket message = MessagePacket(
      type: "chat_get",
      payload: {"id": id},
    );
    MessagePacket request = await _webSocket.sendRequest(message);

    Chat chat = await receiveChat(jsonDecode(request.payload["chat"]));

    addUpdate(chat);
    return chat;
  }

  Future<Chat> createChat(
    List<int> userIds,
    ChatType chatType,
    String? title,
  ) async {
    final SecretKey secretKey = _keyService.decodeAes(
      await _keyService.generateAes(),
    );

    String fromEncryptKey = await _keyService.encryptAesWithX25519(
      _keyService.profiles.entries
          .toList()[ref.read(keyServiceProvider).selectedProfile]
          .value
          .x25519PublicKeyBase64(),
      secretKey,
    );

    Map<String, String> users = {};

    for (int userId in userIds) {
      User user = await _userService.getUser(id: userId);

      users[userId.toString()] = await _keyService.encryptAesWithX25519(
        user.x25519PublicKey,
        secretKey,
      );
    }

    MessagePacket message = MessagePacket(
      type: "chat_create",
      payload: {
        "title": title,
        "chatType": chatType.name,
        "fromEncryptedKey": fromEncryptKey,
        "users": users,
      },
    );

    MessagePacket request = await _webSocket.sendRequest(message);
    if (request.payload["success"] == true) {
      Chat chat = await receiveChat(jsonDecode(request.payload["chat"]));
      addUpdate(chat);
      return chat;
    } else {
      throw SoException(request.payload["server_message"]);
    }
  }

  Future<void> deleteChat(int chatId) async {
    MessagePacket message = MessagePacket(
      type: "chat_delete",
      payload: {"id": chatId},
    );

    MessagePacket request = await _webSocket.sendRequest(message);
    remove((await receiveChat(jsonDecode(request.payload["chat"]))).title);
  }

  Future<Chat> receiveChat(Map<String, dynamic> chatMap) async {
    try {
      Chat chat = Chat(
        id: chatMap['id'],
        title: chatMap["title"],
        type: ChatType.values.byName(chatMap["chatType"]),
      );

      chat.callState = CallState.values.byName(chatMap['callState']);

      if (chatMap["participants"] != null) {
        List<dynamic> participantsJson = chatMap["participants"];
        for (Map<String, dynamic> participantJson in participantsJson) {
          User user = (await _userService.getUser(
            id: participantJson["userId"],
          ));

          Participant participant = Participant(
            user: user,
            chatRole: ChatRole.values.byName(participantJson["chatRole"]),
            lastReadMessageId: participantJson["lastMessageId"],
          );
          if (chat.participants.any((p) => p.user.id == user.id)) {
            chat.participants[chat.participants.indexWhere(
                  (p) => p.user.id == participant.user.id,
                )] =
                participant;
          } else {
            chat.participants.add(participant);
          }
        }
      }

      if (chatMap["senderKeys"] != null) {
        List<dynamic> senderKeysJson = chatMap["senderKeys"];
        for (Map<String, dynamic> senderKeyJson in senderKeysJson) {
          if (senderKeyJson["userId"] != currentUser!.id) continue;

          SenderKey senderKey = SenderKey(
            keyVersion: senderKeyJson["keyVersion"],
            key: (await _keyService.decryptAesWithX25519(
              storedString: senderKeyJson["chatKey"],
              keyBytes: _keyService.profiles.entries
                  .toList()[ref.read(keyServiceProvider).selectedProfile]
                  .value
                  .privateKeyX!,
            )),
          );

          chat.chatKeys.add(senderKey);
        }
      }

      if (chatMap["lastSenderKey"] != null ||
          chatMap["lastMessage"].runtimeType == String) {
        final senderKeyJson = chatMap["lastSenderKey"];
        SenderKey senderKey = SenderKey(
          keyVersion: senderKeyJson["keyVersion"],
          key: (await _keyService.decryptAesWithX25519(
            storedString: senderKeyJson["chatKey"],
            keyBytes: _keyService.profiles.entries
                .toList()[ref.read(keyServiceProvider).selectedProfile]
                .value
                .privateKeyX!,
          )),
        );
        chat.chatKeys.add(senderKey);
      }
      if (chatMap["lastMessage"] != null ||
          chatMap["lastMessage"].runtimeType == String) {
        final messageJson = chatMap["lastMessage"];

        if (chat.findChatKeyByVersion(chat.chatKeys.last.keyVersion) != null) {
          messageJson['content'] = await _keyService.decryptWithAes(
            messageJson['content'],
            chat.findChatKeyByVersion(chat.chatKeys.last.keyVersion)!.key,
          );

          late Message message;
          if (chat.participants.any(
            (p) => p.user.id == messageJson["senderId"]!,
          )) {
            message = Message.fromJson(
              messageJson,
              chat.participants
                  .firstWhere((p) => p.user.id == messageJson["senderId"]!)
                  .user,
            );
          } else {
            User sender = (await _userService.getUser(
              id: messageJson["senderId"],
            ));
            message = Message.fromJson(messageJson, sender);
          }
          ref.read(messageServiceProvider.notifier).addMessage(message);
        }
      }

      return chat;
    } on Exception catch (e) {
      debugPrint("Error loading chat, chatmap: $chatMap");
      throw Exception(e);
    }
  }

  Future<Chat> addParticipantToChat(int userId, Chat chat) async {
    Map<String, String> users = {};
    User user = await _userService.getUser(id: userId);

    if (chat.type == ChatType.GROUP_INSECURE) {
      users[userId.toString()] = await _keyService.encryptAesWithX25519(
        user.x25519PublicKey,
        chat.chatKeys.last.key,
      );
    } else {
      final SecretKey secretKey = _keyService.decodeAes(
        await _keyService.generateAes(),
      );

      for (User participant in chat.participants.map((p) => p.user).toList()) {
        users[user.id.toString()] = await _keyService.encryptAesWithX25519(
          user.x25519PublicKey,
          secretKey,
        );

        User participantFull = await _userService.getUser(id: participant.id);
        users[participant.id.toString()] = await _keyService
            .encryptAesWithX25519(participantFull.x25519PublicKey, secretKey);
      }
    }

    MessagePacket message = MessagePacket(
      type: "chat_add_participant",
      payload: {"userId": userId, "chatId": chat.id, "users": users},
    );

    MessagePacket request = await _webSocket.sendRequest(message);

    Chat newChat = await (jsonDecode(request.payload["chat"]));

    addUpdate(newChat);

    return newChat;
  }

  Future<List<User>> _getUsersByChat(int chatId) async {
    MessagePacket message = MessagePacket(
      type: "chat_get_users",
      payload: {"id": chatId},
    );

    MessagePacket request = await _webSocket.sendRequest(message);

    List<User> userList = [];

    final users = jsonDecode(request.payload["users"]) as List<dynamic>;
    for (String userJson in users) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      User user = User.fromJson(userMap);
      user.x25519PublicKey = userMap["x25519PublicKey"];
      userList.add(user);

      _userService.userBuffer[user.id] = user;
    }
    return userList;
  }

  void leaveChat(int userId, int chatId) async {
    MessagePacket message = MessagePacket(
      type: "chat_leave",
      payload: {"chatId": chatId, "userId": userId},
    );

    MessagePacket request = await _webSocket.sendRequest(message);

    if (userId == currentUser!.id) {
      remove((await receiveChat(jsonDecode(request.payload["chat"]))).title);
    }
  }

  Chat updateParticipantLastReadInChat(int chatId, int userId, int lastMessageId,) {
    final updatedChats = state.chatList.map((chat) {
      if (chat.id != chatId) {
        return chat;
      }

      final updatedParticipants = chat.participants.map((p) {
        if (p.user.id == userId) {
          return p.copyWith(lastReadMessageId: lastMessageId);
        }
        return p;
      }).toList();

      return chat.copyWith(
        participants: updatedParticipants,
        callState: chat.callState,
      );
    }).toList();

    state = state.copyWith(chats: List<Chat>.from(updatedChats));

    final updated = state.chatList.firstWhere((c) => c.id == chatId);

    return updated;
  }
}
