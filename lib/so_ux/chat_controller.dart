import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/modules/chats/chat.dart';
import 'package:sochat_client/modules/chats/chat_service.dart';
import 'package:sochat_client/modules/chats/chat_type.dart';
import 'package:sochat_client/modules/common/auth_service.dart';
import 'package:sochat_client/modules/friends/friends_service.dart';
import 'package:sochat_client/modules/keys/key_service.dart';
import 'package:sochat_client/modules/media/media.dart';
import 'package:sochat_client/modules/media/media_service.dart';
import 'package:sochat_client/modules/messages/message.dart';
import 'package:sochat_client/modules/messages/message_service.dart';
import 'package:sochat_client/modules/users/user.dart';

import '../modules/websocket/web_socket_service.dart';

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);

final chatsListProvider = Provider<List<Chat>>((ref) {
  final chats = ref.watch(chatsServiceProvider).chatList;
  return chats;
});

final chatMessagesProvider = Provider<Map<int, List<Message>>>((ref) {
  final messages = ref.watch(messageServiceProvider).messageMap;
  return messages;
});

final sortedChatsProvider = Provider<List<Chat>>((ref) {
  final chats = ref.watch(chatsListProvider);
  final messageMap = ref.watch(messageServiceProvider.notifier).messageMap;

  final sorted = [...chats]
    ..sort((a, b) {
      final messagesA = messageMap[a.id] ?? [];
      final messagesB = messageMap[b.id] ?? [];

      final lastA = messagesA.isNotEmpty
          ? messagesA.first.timestamp
          : DateTime.fromMillisecondsSinceEpoch(0);

      final lastB = messagesB.isNotEmpty
          ? messagesB.first.timestamp
          : DateTime.fromMillisecondsSinceEpoch(0);

      return lastB.compareTo(lastA);
    });

  return sorted;
});

const _unset = Object();

class ChatState {
  final Chat? selectedChat;
  final List<Media> selectedMedia;
  final List<Media> mediaCache;

  final int activeList;

  ChatState({
    this.selectedChat,
    this.selectedMedia = const [],
    this.mediaCache = const [],
    this.activeList = 0
  });

  ChatState copyWith({
    Object? selectedChat = _unset,
    List<Media>? selectedMedia,
    List<Media>? mediaCache,
    int? activeList,
  }) {
    return ChatState(
      selectedChat: selectedChat == _unset
          ? this.selectedChat
          : selectedChat as Chat?,
      selectedMedia: selectedMedia ?? this.selectedMedia,
      mediaCache: mediaCache ?? this.mediaCache,
      activeList: activeList ?? this.activeList,
    );
  }
}

class ChatController extends Notifier<ChatState> {
  late final ChatService _chatService;
  late final MessageService _messageService;
  late final FriendsService _friendsService;
  late final MediaService _mediaService;
  late final KeyService _keyService;

  Chat? get selectedChat => state.selectedChat;
  List<Media> get selectedMedia => state.selectedMedia;
  List<Media> get mediaCache => state.mediaCache;

  @override
  ChatState build() {
    _chatService = ref.read(chatsServiceProvider.notifier);
    _messageService = ref.read(messageServiceProvider.notifier);
    _friendsService = ref.read(friendsServiceProvider.notifier);
    _mediaService = ref.read(mediaServiceProvider);
    _keyService = ref.read(keyServiceProvider.notifier);
    return ChatState();
  }

  void setSelectedChatChat(Chat? chat) {
    state = state.copyWith(selectedChat: chat);
  }

  void setSelectedChat(List<Media>? media) {
    state = state.copyWith(selectedMedia: media);
  }

  void setActiveList(int activeList) {
    state = state.copyWith(activeList: activeList);
  }

  Future<void> loadFriendsList() async {
    await ref.read(webSocketProvider.future);
    await _friendsService.getRelativesList();
  }

  Future<void> loadChatList() async {
    await ref.read(webSocketProvider.future);
    _chatService.getChatList();
  }

  Future<void> loadRecentMessages() async {
    final selectedChat = state.selectedChat;
    if (selectedChat != null) {
      final chatMessages = ref
          .read(messageServiceProvider)
          .messageMap[selectedChat.id];

      await _messageService.getRecentMessages(
        selectedChat,
        chatMessages!.length,
        atStart: false,
      );
    }
  }

  Future<void> loadFriendList() async {
    await loadFriendsList();
  }

  Future<void> openChat(Chat chat) async {
    if (selectedChat != null &&
        selectedChat!.id == chat.id &&
        chat.participants.length > 1) {
      return;
    }

    final selChat = await _chatService.getChatById(chat.id);
    await _messageService.getRecentMessages(chat, 0);

    state = state.copyWith(selectedChat: selChat);
  }

  Future<void> sendMessage(String content) async {
    final selectedMedia = state.selectedMedia;

    if (["", " "].any((c) => c == content) && selectedMedia.isEmpty ||
        !selectedMedia.every((m) => m.isLoaded)) {
      return;
    }

    await _messageService.sendMessage(
      content,
      null,
      selectedMedia,
      selectedChat!,
    );
    state = state.copyWith(selectedMedia: []);
  }

  Future<void> editMessage(String content, int id) async {
    final selectedMedia = state.selectedMedia;

    if (["", " "].any((c) => c == content) && selectedMedia.isEmpty ||
        !selectedMedia.every((m) => m.isLoaded)) {
      return;
    }

    final selectedChat = state.selectedChat;

    await _messageService.editMessage(content, id, selectedChat!);
    state = state.copyWith(selectedMedia: []);
  }

  Future<void> requestMedia() async {
    // Get files, converting them to my type for Media that contains ids
    final files = await _mediaService.getFiles();
    final mediaFiles = files.map((f) => Media(file: f)).toList();

    state = state.copyWith(selectedMedia: mediaFiles);

    // Upload media
    final ip = _keyService.servers.entries
        .toList()[ref.read(keyServiceProvider).selectedServer]
        .value;
    for (var mediaFile in mediaFiles) {
      _mediaService.uploadMedia(
        ip,
        mediaFile,
        aesKey: selectedChat?.chatKeys.last.key,
      );
    }
    state = state.copyWith(selectedMedia: mediaFiles);
  }

  Future<void> setLastReadMessage(int id, int chatId) async {
    await _messageService.readLastMessage(id);
  }

  Future<void> saveFile(Media media) async {
    String? outputFile = await FilePicker.saveFile(
      lockParentWindow: true,
      dialogTitle: 'Select where to save your file',
      fileName: media.fileName,
    );
    if (outputFile == null) return;

    final ip = _keyService.servers.entries
        .toList()[ref.read(keyServiceProvider).selectedServer]
        .value;
    _mediaService.downloadMedia(
      ip,
      media,
      outputFile,
      aesKey: selectedChat?.chatKeys.last.key,
    );
  }

  Future<void> deleteMessage(int id) async {
    await ref.read(messageServiceProvider.notifier).deleteMessage(id);
  }

  Future<void> deleteMedia(Media media) async {
    final ip = _keyService.servers.entries
        .toList()[ref.read(keyServiceProvider).selectedServer]
        .value;
    _mediaService.deleteMedia(ip, media);
  }

  void startEditing(Message message) {
    if (selectedChat != null) {
      updateChat(
        selectedChat!.copyWith(
          editMessage: message,
          callState: selectedChat!.callState,
        ),
      );
    }
  }

  void stopEditing() {
    if (selectedChat != null) {
      updateChat(
        selectedChat!.copyWith(
          editMessage: null,
          callState: selectedChat!.callState,
        ),
      );
    }
  }

  Future<void> exitChat(
    Chat chat,
    String? editContent,
    String? uncompletedContent,
  ) async {
    final editMessage = chat.editMessage?.copyWith(content: editContent);

    updateChat(
      chat.copyWith(
        editMessage: editMessage,
        uncompletedContent: uncompletedContent,
        callState: chat.callState,
      ),
    );
  }

  void updateChat(Chat chat) {
    ref.read(chatsServiceProvider.notifier).addUpdate(chat);

    if (selectedChat == null) return;
    if (selectedChat?.id == chat.id) {
      state = state.copyWith(selectedChat: chat);
    }
  }

  Future<void> openChatWithUser(User user) async {
    final chatList = ref.read(chatsServiceProvider).chatList;

    Chat? chat;

    for (final c in chatList) {
      if (c.type == ChatType.PRIVATE &&
          c.participants.any((p) => p.user.id == user.id)) {
        chat = c;
        break;
      }
    }

    chat ??= await _chatService.createChat([user.id], ChatType.PRIVATE, null);

    state = state.copyWith(selectedChat: chat);
  }

  // Checks chat state through ref.listen if it's current every rebuild in chat_window.dart
  void syncSelectedChat() {
    final chats = ref.read(chatsListProvider);

    if (selectedChat != null) {
      if (!chats.any((chat) => chat.id == selectedChat?.id)) {
        setSelectedChatChat(null);
      } else {
        final selectedChatFromList = chats.firstWhere(
          (chat) => chat.id == selectedChat?.id,
        );
        if (selectedChat != selectedChatFromList) {
          state = state.copyWith(selectedChat: selectedChatFromList);
        }
      }
    }
  }

  void onChatChanged(
    Chat? previous,
    Chat? next,
    TextEditingController messageInput,
  ) {
    if (previous == null) return;
    if (next?.id == previous.id) return;

    if (previous.editMessage != null) {
      exitChat(previous, messageInput.text, previous.uncompletedContent);
    } else {
      exitChat(previous, null, messageInput.text);
    }

    if (next == null) return;

    if (next.editMessage != null) {
      messageInput.text = next.editMessage!.content;
    } else {
      messageInput.text = next.uncompletedContent ?? "";
    }
  }

  void onMessageMapChange(
    Map<int, List<Message>>? prev,
    Map<int, List<Message>> next,
  ) async {
    final currentUser = ref.read(authServiceProvider).currentUser!;

    for (final entry in next.entries) {
      final chatId = entry.key;

      if (chatId == selectedChat?.id) continue;

      final previousMessages = prev?[chatId] ?? const [];
      final currentMessages = entry.value;

      if (identical(previousMessages, currentMessages)) {
        continue;
      }

      final previousIds = previousMessages.map((m) => m.id).toSet();

      final chat = await _chatService.getChatById(chatId);

      final newMessages = currentMessages
          .where((m) => !previousIds.contains(m.id))
          .toList();

      if (newMessages.isEmpty) continue;
    }

    /*if (ref.read(selectedChatProvider) != null && ref.read(selectedChatProvider)!.id != message.chatId){
      _notificationsService.show(message.id, "${message.sender.nickname} : ${ref.read(currentUserProvider)!.nickname}", message.content);
    }

    final messages = messageMap[e.id] ?? [];
    final hasMessages = messages.isNotEmpty;
    final lastMessage = hasMessages ? messages.first : null;

    final isCurrentUser = lastMessage != null &&
        currentUser!.id == lastMessage.sender.id;

    final isRead = lastMessage != null
        ? e.participants.any((p) =>
    p.lastReadMessageId >= lastMessage.id &&
        p.user.id == currentUser!.id)
        : null;

    final unReadMessageCount = messages
        .where((m) =>
    m.id > lastReadId &&
        m.sender.id != currentUser!.id)
        .length;
    */
  }

  Future<void> addParticipant(int userId, Chat chat) async {
    final chatList = ref.read(chatsListProvider);
    final newChat = await _chatService.addParticipantToChat(userId, chat);

    if (selectedChat != null && selectedChat?.id == newChat.id) {
      if (selectedChat?.id == newChat.id) {
        state = state.copyWith(selectedChat: newChat);
      } else if (selectedChat?.id == chat.id) {
        final updatedChat = chatList.firstWhere((c) => c.id == chat.id);
        state = state.copyWith(selectedChat: updatedChat);
      }
    }
  }

  void updateParticipantLastRead(
    int chatId,
    int userId,
    int lastMessageId,
  ) async {
    Chat updatedChat = _chatService.updateParticipantLastReadInChat(
      chatId,
      userId,
      lastMessageId,
    );

    if (selectedChat != null && selectedChat?.id == chatId) {
      state = state.copyWith(selectedChat: updatedChat);
    }
  }
}
