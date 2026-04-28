import 'package:sochat_client/modules/media/media.dart';
import 'package:sochat_client/modules/users/user.dart';

class Message {
  final int id;
  final int chatId;

  final User sender;
  final int? replyMessageId;
  final String content;
  final DateTime timestamp;

  final List<Media>? mediaFiles;

  final int keyVersion;

  const Message({
    required this.id,
    required this.chatId,
    required this.sender,
    this.replyMessageId,
    this.keyVersion = 0,
    required this.content,
    required this.timestamp,
    this.mediaFiles,
  });


  factory Message.fromJson(Map<String, dynamic> json, User sender) {
    final ts = json['timestamp'];
    DateTime dateTime = DateTime(
      ts[0],
      ts[1],
      ts[2],
      ts[3],
      ts[4],
      ts[5],
      (ts[6] / 1000000).round(),
    );

    return Message(
      id: json['id'] as int,
      chatId: json['chatId'] as int,
      sender: sender,
      replyMessageId: json['replyMessageId'] != null ? json['replyMessageId'] as int : null,
      content: json['content'] as String,
      timestamp: dateTime,
      keyVersion: json['keyVersion'] as int,
    );
  }

}