
import 'package:sochat_client/modules/chats/participant.dart';
import 'package:sochat_client/modules/chats/sender_key.dart';
import 'package:sochat_client/modules/messages/message.dart';

import 'chat_type.dart';

class Chat {
  int id;
  String title;
  ChatType type;

  List<Message> messages = [];

  List<SenderKey> chatKeys = [];
  List<Participant> participants = [];


  Chat({
    required this.id,
    required this.title,
    required this.type,
  });

  SenderKey? findChatKeyByVersion(int version) {
    for (var sk in chatKeys) {
      if (sk.keyVersion == version) return sk;
    }
    return null;
  }
  SenderKey? findLatestChatKey() {
    if (chatKeys.isEmpty) return null;

    SenderKey latest = chatKeys.first;
    for (var sk in chatKeys) {
      if (sk.keyVersion > latest.keyVersion) {
        latest = sk;
      }
    }
    return latest;
  }

  Chat copyWith({
    int? id,
    String? title,
    ChatType? type,
    List<Participant>? participants,
    List<SenderKey>? chatKeys,
    Message? lastMessage,
  }) {
    Chat chat = Chat(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
    );

    chat.participants = participants ?? List<Participant>.from(this.participants);
    chat.chatKeys = chatKeys ?? this.chatKeys;

    return chat;
  }
  @override
  bool operator ==(Object other) =>
      identical(this, other);

  @override
  int get hashCode => id.hashCode;

}