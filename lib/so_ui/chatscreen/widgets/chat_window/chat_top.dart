import 'package:flutter/material.dart';
import 'package:sochat_client/context/menus.dart';
import 'package:sochat_client/modules/calls/call_state.dart';
import 'package:sochat_client/modules/chats/chat_type.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/modules/common/auth_service.dart';
import 'package:sochat_client/modules/friends/friends_service.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';
import 'package:sochat_client/so_ux/call_controller.dart';
import 'package:sochat_client/so_ux/chat_controller.dart';

class ChatTop extends ConsumerWidget {
  final double borderRadius;

  const ChatTop({super.key, this.borderRadius = 10});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatController = ref.read(chatControllerProvider);

    final chatList = ref.watch(chatsListProvider);

    final selectedChat = chatController.selectedChat;

    final friendsList = ref.watch(friendsListProvider);
    final callController = ref.watch(callControllerProvider.notifier);
    final selectedChatFromList = chatList.firstWhere(
      (chat) => chat.id == selectedChat!.id,
    );

    final otherUser = selectedChatFromList.participants.firstWhere(
      (participant) => participant.user.id != ref.read(authServiceProvider).currentUser!.id,
    );
    final bool isFriends = friendsList.any((u) => u.id == otherUser.user.id);

    return Container(
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide.none,
          left: BorderSide.none,
          right: BorderSide.none,
          bottom: BorderSide(color: context.colors.outline, width: 1),
        ),
        color: context.colors.foreground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      ),

      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              spacing: 10,
              children: [
                SoButton(
                  height: 30,
                  width: 30,
                  color: Colors.transparent,
                  onPressed: () {
                    ref.read(chatControllerProvider.notifier).setSelectedChatChat(null);
                  },
                  child: Icon(
                    Icons.arrow_back,
                    color: context.colors.textPrimary,
                    size: 25,
                  ),
                ),
                SoButton(
                  onPressed: selectedChatFromList.type == ChatType.PRIVATE
                      ? Menus.userProfile(context, ref, otherUser.user)
                      : Menus.openProfile(context, ref, selectedChatFromList),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Row(
                      spacing: 10,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          child: Text(selectedChatFromList.title[0]),
                        ),
                        Text(selectedChatFromList.title),
                        selectedChatFromList.type == ChatType.GROUP_SECURE
                            ? Icon(
                                Icons.enhanced_encryption,
                                color: context.colors.textSecondary,
                                size: 20,
                              )
                            : selectedChatFromList.type ==
                                  ChatType.GROUP_INSECURE
                            ? Icon(
                                Icons.no_encryption,
                                color: context.colors.textSecondary,
                                size: 20,
                              )
                            : Container(),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Row(
              spacing: 10,
              children: [
                selectedChat?.type == ChatType.GROUP_INSECURE ||
                        selectedChat?.type == ChatType.GROUP_SECURE
                    ? SoButton(
                        height: 40,
                        width: 40,
                        onPressed: Menus.addParticipantDialog(context, ref),
                        color: context.colors.foreground,
                        child: Icon(Icons.person_add),
                      )
                    : Container(),
                if (selectedChatFromList.type == ChatType.PRIVATE && isFriends)
                  Row(
                    children: [
                      SoButton(
                        height: 40,
                        width: 40,
                        onPressed: () {
                          {
                            if (isFriends) {
                              callController.callStart();
                            }
                          }
                        },
                        color: selectedChat!.callState == CallState.INCOMING
                            ? context.colors.positive
                            : selectedChat.callState == CallState.IN_CALL
                            ? context.colors.primary
                            : selectedChat.callState == CallState.CALLING
                            ? context.colors.caution
                            : context.colors.foreground,
                        child: Icon(Icons.call),
                      ),
                      SoButton(
                        height: 40,
                        width: 40,
                        onPressed: () {
                          {
                            if (isFriends) {
                              callController.callStart(video: true);
                            }
                          }
                        },
                        color: context.colors.foreground,
                        child: Icon(Icons.video_call),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
