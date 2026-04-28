import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sochat_client/context/notifications/inapp_notifications_manager.dart';
import 'package:sochat_client/modules/chats/chat.dart';
import 'package:sochat_client/modules/chats/chat_service.dart';
import 'package:sochat_client/modules/chats/participant.dart';
import 'package:sochat_client/modules/common/auth_service.dart';
import 'package:sochat_client/modules/friends/friends_service.dart';
import 'package:sochat_client/modules/media/media.dart';
import 'package:sochat_client/modules/messages/message.dart';
import 'package:sochat_client/modules/messages/message_service.dart';
import 'package:sochat_client/so_ui/notifications/so_notification.dart';

final chatControllerProvider = StateNotifierProvider<ChatController, ChatControllerState>((ref) {
  final chatService = ref.read(chatsServiceProvider.notifier);
  final authService = ref.read(authServiceProvider);
  final messageService = ref.read(messageServiceProvider.notifier);
  final friendsService = ref.read(friendsServiceProvider.notifier);

  return ChatController(chatService, authService, messageService, friendsService ,ref);
});

final selectedChatProvider = StateProvider<Chat?>((ref) => null);
final isInCallProvider = StateProvider<bool>((ref) => false);
final chatMessagesProvider = StateProvider<Map<int,List<Message>>>((ref) => {});

final selectedMediaProvider = StateProvider<List<Media>>((ref) => []);

final chatsListProvider = Provider<List<Chat>>((ref) {
  final chats = ref.watch(chatsServiceProvider).chatList;
  return chats;
});

class ChatControllerState {

}

class ChatController extends StateNotifier<ChatControllerState> {
  ChatService _chatService;
  MessageService _messageService;
  FriendsService _friendsService;
  AuthService _authService;
  Ref ref;

  ChatController(this._chatService, this._authService, this._messageService, this._friendsService, this.ref) : super(ChatControllerState());

  Future<void> getFriendsList() async {
    await _friendsService.getRelativesList();
  }

  Future<void> getChatList() async {
    _chatService.getChatList();
  }

  
  Future<void> loadRecentMessages() async {
    final selectedChat = ref.read(selectedChatProvider.notifier).state;
    if (selectedChat != null) {
      final chatMessages = ref
          .read(chatMessagesProvider.notifier)
          .state[selectedChat.id];

      await _messageService.getRecentMessages(selectedChat, chatMessages!.length, atStart: false);
    }
  }

  Future<void> loadFriendList() async {
    await ref.read(chatControllerProvider.notifier).getFriendsList();
  }

  Future<void> openChat(Chat chat) async{
    if (ref.read(selectedChatProvider) != null && ref.read(selectedChatProvider)!.id == chat.id && chat.participants.length > 1){
      return;
    }


    final selectedChat = await _chatService.getChatById(chat.id);
    await _messageService.getRecentMessages(selectedChat, 0);

    ref.read(selectedChatProvider.notifier).state = selectedChat;
  }

  Future<void> sendMessage(String content) async {
    if (["", " "].any((c) => c == content)) { return; }

    final selectedChat = ref.read(selectedChatProvider.notifier).state;
    await _messageService.sendMessage(content, null, selectedChat!);
  }

  Future<void> setLastReadMessage(int id, int chatId) async {
    await _messageService.readLastMessage(id);
  }

}