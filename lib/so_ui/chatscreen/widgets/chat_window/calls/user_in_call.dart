import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/modules/users/user.dart';

class UserInCall extends ConsumerWidget {
  final User user;
  final RTCVideoRenderer? rtcVideo;
  final bool hasVideo;

  const UserInCall({
    super.key,
    required this.user,
    required this.rtcVideo,
    this.hasVideo = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 293,
      height: 214,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.foreground,
          border: Border.all(),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: !hasVideo ? CircleAvatar(
            radius: 40,
            backgroundColor: context.colors.primary,
            child: Text(
              user.username[0],
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ) : RTCVideoView(rtcVideo!),
        ),
      ),
    );
  }
}
