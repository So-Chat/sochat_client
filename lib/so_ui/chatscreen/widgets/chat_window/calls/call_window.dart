import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/modules/calls/call_service.dart';
import 'package:sochat_client/so_ui/chatscreen/widgets/chat_window/calls/user_in_call.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';
import 'package:sochat_client/so_ux/call_controller.dart';

import '../../../../../so_ux/chat_controller.dart';

class CallWindow extends ConsumerStatefulWidget {
  const CallWindow({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => CallWindowState();
}

class CallWindowState extends ConsumerState<CallWindow> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final selectedChat = ref.watch(chatControllerProvider).selectedChat;
    final callController = ref.watch(callControllerProvider.notifier);
    final mediaState = ref.watch(mediaStateProvider);

    return Expanded(
      flex: 2,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.outline, width: 1.0),
          color: Colors.black,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            spacing: 8,
            children: [
              Row(
                spacing: 10,
                children: [
                  SoButton(
                    height: 30,
                    width: 30,
                    color: Colors.transparent,
                    onPressed: () {
                      ref.read(callControllerProvider.notifier).setIsInCall(false);
                    },
                    child: Icon(
                      Icons.arrow_back,
                      color: context.colors.textPrimary,
                      size: 25,
                    ),
                  ),
                  CircleAvatar(
                    radius: 20,
                    child: Text(selectedChat!.title[0]),
                  ),
                  Text(selectedChat.title),
                  ValueListenableBuilder<String?>(
                    valueListenable: callController.lastRTCState,
                    builder: (context, value, child) {
                      return Text(value ?? '');
                    },
                  ),
                ],
              ),
              Expanded(
                flex: 5,
                child: (mediaState != null)
                    ? Row(
                        spacing: 8,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          UserInCall(
                            //user: callSession!.inCallUsers.firstWhere((u) => u.id == currentUser!.id),
                            user: selectedChat.participants.firstWhere((p) => p.user.nickname != selectedChat.title).user,
                            rtcVideo: mediaState.localRenderer,
                            hasVideo:
                                mediaState.hasLocalVideo == true &&
                                mediaState.localRenderer != null,
                          ),
                          UserInCall(
                            //user: callSession!.inCallUsers.firstWhere((u) => u.id != currentUser!.id),
                            user: selectedChat.participants.firstWhere((p) => p.user.nickname == selectedChat.title).user,
                            rtcVideo: mediaState.remoteRenderer,
                            hasVideo:
                                mediaState.hasRemoteVideo == true &&
                                mediaState.remoteRenderer != null,
                          ),
                        ],
                      )
                    : Container(),
              ),
              Flexible(
                flex: 1,
                child: Row(
                  spacing: 8,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SoButton(
                      height: 50,
                      width: 50,
                      color: context.colors.surface,
                      onPressed: () {},
                      child: Icon(
                        Icons.screen_share_outlined,
                        color: context.colors.textPrimary,
                        size: 25,
                      ),
                    ),
                    SoButton(
                      height: 50,
                      width: 50,
                      color: context.colors.surface,
                      onPressed: () {
                        setState(() {
                          callController.setMediaInputs(
                            video: !callController.userVideo,
                            audio: callController.userAudio,
                          );
                        });
                      },
                      child: Icon(
                        callController.userVideo
                            ? Icons.videocam_rounded
                            : Icons.videocam_off_rounded,
                        color: context.colors.textPrimary,
                        size: 25,
                      ),
                    ),
                    SoButton(
                      height: 50,
                      width: 50,
                      color: context.colors.surface,
                      onPressed: () {
                        setState(() {
                          callController.setMediaInputs(
                            video: callController.userVideo,
                            audio: !callController.userAudio,
                          );
                        });
                      },
                      child: Icon(
                        callController.userAudio
                            ? Icons.mic
                            : Icons.mic_off,
                        color: context.colors.textPrimary,
                        size: 25,
                      ),
                    ),
                    SoButton(
                      height: 50,
                      width: 50,
                      color: context.colors.critical,
                      onPressed: () {
                        callController.callEnd();
                      },
                      child: Icon(
                        Icons.call_end,
                        color: context.colors.textPrimary,
                        size: 25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
