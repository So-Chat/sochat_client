 
import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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
import 'package:sochat_client/so_ui/common/so_exception.dart';
import 'package:sochat_client/so_ux/chat_controller.dart';

import '../common/auth_service.dart';
import '../keys/key_service.dart';

final chatsServiceProvider = StateNotifierProvider<ChatService, ChatsState>(
      (ref) => ChatService(ref.read(webSocketProvider), ref.read(keyServiceProvider.notifier), ref.read(authServiceProvider), ref.read(userServiceProvider.notifier), ref.read(currentUserProvider), ref),);



class ChatsState {
  final List<Chat> chatList;

  ChatsState({required this.chatList});

  ChatsState copyWith({
    List<Chat>? chats,
  }) {
    return ChatsState(
      chatList: chats ?? chatList,
    );
  }

}

class ChatService extends StateNotifier<ChatsState> {
  final WebSocketService _webSocket;
  final KeyService _keyService;
  final AuthService _authService;
  final UserService _userService;
  final User? currentUser;

  final Ref _ref;

  ChatService(this._webSocket, this._keyService, this._authService, this._userService, this.currentUser, this._ref)
      : super(ChatsState(chatList: [])) {
    startListen();
  }

  List<Chat> get chatList =>
      state.chatList;

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
            remove((await receiveChat(jsonDecode(message.payload["chat"]))).title);
            break;
          }
        case ("chat_leave"):
          {
            Chat chat = await receiveChat(jsonDecode(message.payload["chat"]));
            if (!chat.participants.any((p) => p.user.id == currentUser!.id)){
              remove(chat.title);
            }
            break;
          }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void remove(String chatName) {
    final newList = List<Chat>.from(chatList);

    newList.removeWhere((chat) => chat.title == chatName);

    _ref.read(selectedChatProvider.notifier).state = null;

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

    print(request);

    final List<Map<String, dynamic>> chatList =
    (jsonDecode(request.payload['chats']) as List)
        .cast<Map<String, dynamic>>();
    print("chatList: $chatList");


    for (var c in chatList) {
      addUpdate(await receiveChat(c));
    }
  }

  Future<Chat> getChatByName(String username) async {
    if (chatList.any((c) => c.title == username)){
      Chat localChat = chatList.firstWhere((c) => c.title == username);
      if (_ref.read(chatMessagesProvider)[localChat.id]!.length > 1) {
        return localChat;
      }
    }

    MessagePacket message = MessagePacket(
        type: "chat_get", payload: {"participant_username": username});
    MessagePacket request = await _webSocket.sendRequest(message);

    Chat chat = await receiveChat(jsonDecode(request.payload["chat"]));

    addUpdate(chat);
    return chat;
  }

  Future<Chat> getChatById(int id) async {
    if (chatList.any((c) => c.id == id)){
      Chat localChat = chatList.firstWhere((c) => c.id == id);
      if (_ref.read(chatMessagesProvider).containsKey(id) && _ref.read(chatMessagesProvider)[id]!.length > 1) {
        return localChat;
      }
    }

    MessagePacket message = MessagePacket(
        type: "chat_get", payload: {"id": id});
    MessagePacket request = await _webSocket.sendRequest(message);

    Chat chat = await receiveChat(jsonDecode(request.payload["chat"]));

    addUpdate(chat);
    return chat;
  }

  Future<void> createChat(List<int> userIds, ChatType chatType, String? title) async {
    final SecretKey secretKey = _keyService.decodeAes(
        await _keyService.generateAes());

    String fromEncryptKey = await _keyService.encryptAesWithX25519(
        _keyService.profiles.entries.toList()[_ref.read(
            selectedProfileProvider)].
        value.x25519PublicKeyBase64(), secretKey);

    Map<String, String> users = {};

    for (int userId in userIds) {
      User user = await _userService.getUser(id: userId);

      users[userId.toString()] = await _keyService.encryptAesWithX25519(
        user.x25519PublicKey,
        secretKey,
      );
    }

    MessagePacket message = MessagePacket(type: "chat_create", payload: {
      "title": title,
      "chatType": chatType.name,
      "fromEncryptedKey": fromEncryptKey,
      "users": users
    });

    MessagePacket request = await _webSocket.sendRequest(message);
    if (request.payload["success"] == true) {
      addUpdate(await receiveChat(jsonDecode(request.payload["chat"])));
    } else {
      throw SoException(request.payload["server_message"]);
    }
  }

  Future<void> deleteChat(int chatId) async {
    MessagePacket message = MessagePacket(type: "chat_delete", payload: {
      "id": chatId,
    });

    MessagePacket request = await _webSocket.sendRequest(message);
    remove((await receiveChat(jsonDecode(request.payload["chat"]))).title);
  }


  Future<Chat> receiveChat(Map<String, dynamic> chatMap) async {
    Chat chat = Chat(id: chatMap['id'], title: chatMap["title"], type: ChatType.values.byName(chatMap["chatType"]));

    if (chatMap["participants"] != null) {
      List<dynamic> participantsJson = chatMap["participants"];
      for (Map<String, dynamic> participantJson in participantsJson){
        User user = (await _userService.getUser(id: participantJson["userId"]));

        Participant participant = Participant(user: user,
            chatRole: ChatRole.values.byName(participantJson["chatRole"]),
            lastReadMessageId: participantJson["lastMessageId"]);
        if (chat.participants.any((p) => p.user.id == user.id)) {
          chat.participants[chat.participants.indexWhere((p) => p.user.id == participant.user.id)] = participant;
        } else {
          chat.participants.add(participant);
        }
      }
    }

    if (chatMap["senderKeys"] != null) {
      List<dynamic> senderKeysJson = chatMap["senderKeys"];
      for (Map<String, dynamic> senderKeyJson in senderKeysJson){
        SenderKey senderKey = SenderKey(keyVersion: senderKeyJson["keyVersion"], key: (await _keyService.decryptAesWithX25519(storedString: senderKeyJson["chatKey"], keyBytes: _keyService.profiles.entries.toList()[_ref.read(selectedProfileProvider)].value.privateKeyX!)));

        chat.chatKeys.add(senderKey);
      }
      print(chat.chatKeys.length);
      print(chat.chatKeys);

      print(senderKeysJson.length);
      print(senderKeysJson);
    }

    if (chatMap["lastSenderKey"] != null || chatMap["lastMessage"].runtimeType == String){
      final senderKeyJson = chatMap["lastSenderKey"];
      SenderKey senderKey = SenderKey(keyVersion: senderKeyJson["keyVersion"], key: (await _keyService.decryptAesWithX25519(storedString: senderKeyJson["chatKey"], keyBytes: _keyService.profiles.entries.toList()[_ref.read(selectedProfileProvider)].value.privateKeyX!)));
      chat.chatKeys.add(senderKey);
    }
    if (chatMap["lastMessage"] != null || chatMap["lastMessage"].runtimeType == String) {
      final messageJson = chatMap["lastMessage"];

      messageJson['content'] = await _keyService.decryptWithAes(messageJson['content'], chat.findChatKeyByVersion(messageJson['keyVersion'])!.key);

      late Message message;
      if (chat.participants.any((p) => p.user.id == messageJson["senderId"]!)){
        message = Message.fromJson(messageJson, chat.participants.firstWhere((p) => p.user.id == messageJson["senderId"]!).user);
      }
      else {
        User sender = (await _userService.getUser(id: messageJson["senderId"]));
        message = Message.fromJson(
            messageJson, sender);
      }
      _ref.read(messageServiceProvider.notifier).addMessage(message);
    }

    return chat;
  }

  Future<void> addParticipant(int userId, Chat chat) async {

    Map<String, String> users = {};
    User user = await _userService.getUser(id: userId);

    if (chat.type == ChatType.GROUP_INSECURE) {
      users[userId.toString()] = await _keyService.encryptAesWithX25519(
        user.x25519PublicKey,
        chat.chatKeys.last.key,
      );
    }
    else {
      final SecretKey secretKey = _keyService.decodeAes(
          await _keyService.generateAes());

      for (User participant in chat.participants.map((p) => p.user).toList()) {

        users[user.id.toString()] = await _keyService.encryptAesWithX25519(
          user.x25519PublicKey,
          secretKey,
        );

        User participantFull = await _userService.getUser(id: participant.id);
        users[participant.id.toString()] = await _keyService.encryptAesWithX25519(
          participantFull.x25519PublicKey,
          secretKey,
        );
      }
    }


    MessagePacket message = MessagePacket(type: "chat_add_participant", payload: {
      "userId": userId,
      "chatId": chat.id,
      "users": users
    });

    MessagePacket request = await _webSocket.sendRequest(message);

    Chat newChat = await (jsonDecode(request.payload["chat"]));

    addUpdate(newChat);

    final selectedChat = _ref.read(selectedChatProvider);

    if (selectedChat != null && selectedChat.id == newChat.id) {
      _ref.read(selectedChatProvider.notifier).state = newChat;
    }
    if (selectedChat != null && selectedChat.id == chat.id) {
      final updatedChat = state.chatList.firstWhere((c) => c.id == chat.id);
      _ref.read(selectedChatProvider.notifier).state = updatedChat;
    }
  }

  Future<List<User>> _getUsersByChat(int chatId) async {


    MessagePacket message = MessagePacket(type: "chat_get_users", payload: {
      "id": chatId,
    });

    MessagePacket request = await _webSocket.sendRequest(message);

    List<User> userList = [];

    final users = jsonDecode(request.payload["users"]) as List<dynamic>;
    for (String userJson in users){
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      User user = User.fromJson(userMap);
      user.x25519PublicKey = userMap["x25519PublicKey"];
      userList.add(user);

      _userService.userBuffer[user.id] = user;
    }
    return userList;
  }

  void leaveChat(int userId, int chatId) async {
    MessagePacket message = MessagePacket(type: "chat_leave", payload: {
      "chatId": chatId,
      "userId": userId
    });

    MessagePacket request = await _webSocket.sendRequest(message);

    if (userId == currentUser!.id) {
      remove((await receiveChat(jsonDecode(request.payload["chat"]))).title);
    }
  }

  void updateParticipantLastRead(
      int chatId,
      int userId,
      int lastMessageId,
      ) {
    final updatedChats = state.chatList.map((chat) {
      if (chat.id != chatId) { return chat;}

      final updatedParticipants = chat.participants.map((p) {
        if (p.user.id == userId) {
          debugPrint("Edited participant: ${p.user.username}, ${p.lastReadMessageId}");
          return p.copyWith(lastReadMessageId: lastMessageId);
        }
        return p;
      }).toList();

      return chat.copyWith(
        participants: updatedParticipants,
      );
    }).toList();

    state = state.copyWith(chats: List<Chat>.from(updatedChats));

    final updated =
      state.chatList.firstWhere((c) => c.id == chatId);

    final selectedChat = _ref.read(selectedChatProvider);

    if (selectedChat != null && selectedChat.id == chatId) {
      _ref
          .read(selectedChatProvider.notifier)
          .state = updated;
    }
  }
}