
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sochat_client/modules/chats/chat.dart';
import 'package:sochat_client/modules/chats/chat_service.dart';
import 'package:sochat_client/modules/common/auth_service.dart';
import 'package:sochat_client/modules/friends/friends_service.dart';
import 'package:sochat_client/modules/keys/key_service.dart';
import 'package:sochat_client/modules/media/media.dart';
import 'package:sochat_client/modules/media/media_service.dart';
import 'package:sochat_client/modules/messages/message.dart';
import 'package:sochat_client/modules/messages/message_service.dart';

import '../modules/websocket/web_socket_service.dart';

final chatControllerProvider = StateNotifierProvider<ChatController, ChatControllerState>((ref) {
  final chatService = ref.read(chatsServiceProvider.notifier);
  final authService = ref.read(authServiceProvider);
  final messageService = ref.read(messageServiceProvider.notifier);
  final friendsService = ref.read(friendsServiceProvider.notifier);
  final mediaService = ref.read(mediaServiceProvider);
  final keyService = ref.read(keyServiceProvider.notifier);

  return ChatController(chatService, authService, messageService, friendsService, mediaService, keyService, ref);
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
  final ChatService _chatService;
  final MessageService _messageService;
  final FriendsService _friendsService;
  final AuthService _authService;
  final MediaService _mediaService;
  final KeyService _keyService;
  Ref ref;

  ChatController(this._chatService, this._authService, this._messageService, this._friendsService, this._mediaService, this._keyService, this.ref) : super(ChatControllerState());

  Future<void> getFriendsList() async {
    await ref.read(webSocketProvider.future);
    await _friendsService.getRelativesList();
  }

  Future<void> getChatList() async {
    await ref.read(webSocketProvider.future);
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
    final selectedMedia = ref.read(selectedMediaProvider);

    if (["", " "].any((c) => c == content) && selectedMedia.isEmpty || !selectedMedia.every((m) => m.isLoaded)) { return; }

    final selectedChat = ref.read(selectedChatProvider.notifier).state;

    
    await _messageService.sendMessage(content, null, selectedMedia, selectedChat!);
    ref.read(selectedMediaProvider.notifier).state = [];
  }

  Future<void> requestMedia() async {
    // Get files, converting them to my type for Media that contains ids
    final files = await _mediaService.getFiles();
    final mediaFiles = files.map((f) => Media(file: f)).toList();
    ref.read(selectedMediaProvider.notifier).state = mediaFiles;

    // Upload media
    final ip = _keyService.servers.entries.toList()[ref.read(selectedServerProvider)].value;
    for (var mediaFile in mediaFiles) {
      _mediaService.uploadMedia(ip, mediaFile, aesKey: ref.read(selectedChatProvider.notifier).state?.chatKeys.last.key);
    }
    ref.read(selectedMediaProvider.notifier).state = mediaFiles;
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

    final ip = _keyService.servers.entries.toList()[ref.read(selectedServerProvider)].value;
    _mediaService.downloadMedia(ip, media, outputFile, aesKey: ref.read(selectedChatProvider.notifier).state?.chatKeys.last.key);
  }

  Future<void> deleteMedia(Media media) async {
    final ip = _keyService.servers.entries.toList()[ref.read(selectedServerProvider)].value;
    _mediaService.deleteMedia(ip, media);
  }

}