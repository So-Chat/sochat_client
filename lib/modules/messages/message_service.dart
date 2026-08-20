import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/modules/chats/chat.dart';
import 'package:sochat_client/modules/chats/chat_service.dart';
import 'package:sochat_client/modules/media/media.dart';
import 'package:sochat_client/modules/media/media_service.dart';
import 'package:sochat_client/modules/users/user_service.dart';
import 'package:sochat_client/modules/websocket/message_packet.dart';
import 'package:sochat_client/modules/users/user.dart';
import 'package:sochat_client/modules/websocket/web_socket_service.dart';

import '../keys/key_service.dart';
import 'message.dart';


final messageServiceProvider = NotifierProvider<MessageService, MessagesState>(
  MessageService.new,
);



class MessagesState {
  final Map<int, List<Message>> messageMap;

  MessagesState({required this.messageMap});

  MessagesState copyWith({Map<int, List<Message>>? messages}) {
    return MessagesState(messageMap: messages ?? messageMap);
  }
}

class MessageService extends Notifier<MessagesState> {
  late final WebSocketService _webSocket;
  late final KeyService _keyService;
  late final ChatService _chatService;
  late final UserService _userService;
  late final MediaService _mediaService;

  StreamSubscription? _subscription;

  Map<int, List<Message>> get messageMap => state.messageMap;

  @override
  MessagesState build() {
    _keyService = ref.read(keyServiceProvider.notifier);
    _chatService = ref.read(chatsServiceProvider.notifier);
    _userService = ref.read(userServiceProvider);
    _mediaService = ref.read(mediaServiceProvider);

    ref.onDispose(() {
      _subscription?.cancel();
    });

    ref.watch(webSocketProvider.future).then((ws) {
      _webSocket = ws;
      startListen();
    });

    return MessagesState(messageMap: {});
  }


  void startListen() {
    _subscription = _webSocket.messagesMessages.listen((message) {
      switch(message.type){
        case "message_edit":
        case "message_send":{
          if (message.payload["success"] == "true"){
            break;
          }
          Chat chat = ref.read(chatsServiceProvider).chatList.firstWhere((c) => c.id == jsonDecode(message.payload["message"] as String)["chatId"]);

          receiveMessage(message, chat);
          break;
        }
        case "message_delete":{
          handleDeleteMessage(message);
          break;
        }
        case "message_read":{
          receiveLastReadMessage(message);
          break;
        }
      }
    });
  }

  Future<void> getRecentMessages(Chat chat, int offset, {atStart = true}) async {
    /*if (offset == 0 && ref.read(chatMessagesProvider).containsKey(chat.id) && ref.read(chatMessagesProvider)[chat.id]!.length > 2){
      return;
    }
    */

    MessagePacket message = MessagePacket(type: "message_list", payload: {
      "offset": offset,
      "chatId": chat.id,
    });
    final request = await _webSocket.sendRequest(message);

    List<dynamic> messageList = jsonDecode(request.payload["messages"]);


    for (final messageJson in messageList.reversed){
      try {
        messageJson['content'] = await _keyService.decryptWithAes(messageJson['content'], chat.findChatKeyByVersion(messageJson['keyVersion'])!.key);

        User user = chat.participants.any((p) => p.user.id == messageJson["senderId"])
            ? chat.participants.firstWhere((p) => p.user.id == messageJson["senderId"]).user
            : ((await _userService.getUser(id: messageJson["senderId"])));

        final List<dynamic> mediasJson = messageJson['mediaFiles'];
        final List<Media> medias = [];
        for (final mediaJson in mediasJson){
          final ip = _keyService.servers.entries.toList()[ref.read(keyServiceProvider).selectedServer].value;

          final media = Media.fromJson(mediaJson);
          _mediaService.resolveMediaBytes(ip, media);
          medias.add(media);
        }
        Message message = Message.fromJsonWithMedia(messageJson, user, medias);

        addMessage(message, atStart: atStart);
      }catch (e){
        rethrow;
      }
    }
  }

  Future<void> getMessage(int messageId, Chat? chat) async {
    MessagePacket message = MessagePacket(type: "message_get", payload: {
      "messageId": messageId,
    });
    final request = await _webSocket.sendRequest(message);
    receiveMessage(request, chat);
  }


  Future<void> sendMessage(String content, int? replyMessageId, List<Media> mediaFiles, Chat chat) async{
    String encryptedContent = await _keyService.encryptStringWithAesToString(content, chat.findLatestChatKey()!.key);

    MessagePacket message = MessagePacket(type: "message_send", payload: {
      "content": encryptedContent,
      "replyMessageId": replyMessageId,
      "media_files": jsonEncode(mediaFiles.map((m) => m.mediaId).toList()),
      "chatId": chat.id
    });
    final request = await _webSocket.sendRequest(message);

    if (request.payload["success"] == "true"){
      receiveMessage(request, chat);
    }
  }

  Future<void> editMessage(String content, int id, Chat chat) async {
    String encryptedContent = await _keyService.encryptStringWithAesToString(content, chat.findLatestChatKey()!.key);
    MessagePacket packet = MessagePacket(type: "message_edit", payload: {
      "content": encryptedContent,
      "id": id
    });
    final request = await _webSocket.sendRequest(packet);

    if (request.payload["success"] == "true"){
      receiveMessage(request, chat);
    }
  }


  Future<void> receiveMessage(MessagePacket requestPacket, Chat? chat) async{

    chat ??= await _chatService.getChatById(int.parse(requestPacket.payload["chatId"]));
    if (chat.chatKeys == []){
      _chatService.getChatById(chat.id);
    }

    final messageJson = jsonDecode(requestPacket.payload["message"]);

    messageJson['content'] = await _keyService.decryptWithAes(messageJson['content'], chat.findChatKeyByVersion(messageJson['keyVersion'])!.key);

    final List<dynamic> mediasJson = messageJson['mediaFiles'] ?? [];
    final List<Media> medias = [];
    for (final mediaJson in mediasJson){
      final ip = _keyService.servers.entries.toList()[ref.read(keyServiceProvider).selectedServer].value;

      final media = Media.fromJson(mediaJson);
      _mediaService.resolveMediaBytes(ip, media);
      medias.add(media);
    }

    late Message message;
    if (chat.participants.any((p) => p.user.id == messageJson["senderId"]!)){
      message = Message.fromJsonWithMedia(messageJson, chat.participants.firstWhere((p) => p.user.id == messageJson["senderId"]!).user, medias);
    }
    else {
      User sender = (await _userService.getUser(username: messageJson["senderId"]));
      message = Message.fromJsonWithMedia(
          jsonDecode(requestPacket.payload["message"]), sender, medias);
    }



    addMessage(message);

  }

  void addMessage(Message message, {bool atStart = true}) {
    final currentMessages = List<Message>.from(
      messageMap[message.chatId] ?? [],
    );

    final messageIndex = currentMessages.indexWhere((m) => m.id == message.id);

    if (messageIndex != -1) {
      currentMessages[messageIndex] = message;
    } else {
      currentMessages.add(message);
    }

    currentMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final updatedMap = {
      ...messageMap,
      message.chatId: currentMessages,
    };

    state = state.copyWith(messages: updatedMap);
  }

  void removeMessage(int id, int chatId) {
    final currentMessages = List<Message>.from(
      messageMap[chatId] ?? [],
    );

    if (!currentMessages.any((m) => m.id == id)) return;

    currentMessages.removeWhere((message) => message.id == id);

    final updatedMap = {
      ...messageMap,
      chatId: currentMessages,
    };

    state = state.copyWith(messages: updatedMap);
  }

  Future<void> receiveLastReadMessage(MessagePacket requestPacket) async {
    Map<String, dynamic> participantJson = jsonDecode(requestPacket.payload["participant"]);
    _chatService.updateParticipantLastReadInChat(participantJson["chatId"], participantJson["userId"], participantJson["lastMessageId"]);
  }

  Future<void> readLastMessage(int id) async {

    MessagePacket message = MessagePacket(type: "message_read", payload: {
      "id": id,
    });
    final request = await _webSocket.sendRequest(message);
    receiveLastReadMessage(request);
  }

  Future<void> handleDeleteMessage(MessagePacket requestPacket) async {
    Map<String, dynamic> messageJson = jsonDecode(requestPacket.payload["message"]);

    final id = messageJson["id"];
    final chatId = messageJson["chatId"];

    removeMessage(id, chatId);
  }

  Future<void> deleteMessage(int id) async {
    MessagePacket message = MessagePacket(type: "message_delete", payload: {
      "id": id,
    });
    final request = await _webSocket.sendRequest(message);
    handleDeleteMessage(request);
  }

}
