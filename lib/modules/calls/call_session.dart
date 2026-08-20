import 'package:sochat_client/modules/users/user.dart';

class CallSession {
  final int chatId;

  final List<User> inCallUsers;
  final bool isVideo;

  const CallSession({
    required this.chatId,
    required this.inCallUsers,
    this.isVideo = false,
  });

  CallSession changeVideo() {
    return copyWith(isVideo: !isVideo);
  }

  CallSession copyWith({int? chatId, List<User>? inCallUsers, bool? isVideo}) {
    return CallSession(
      chatId: chatId ?? this.chatId,
      inCallUsers: inCallUsers ?? this.inCallUsers,
      isVideo: isVideo ?? this.isVideo,
    );
  }
}
