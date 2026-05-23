import 'package:flutter/material.dart';
import 'package:sochat_client/context/menus.dart';
import 'package:sochat_client/modules/chats/chat_type.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';
import 'package:sochat_client/so_ux/chat_controller.dart';

class ChatTop extends ConsumerWidget {

  final double borderRadius;

  const ChatTop({super.key, this.borderRadius = 10});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatController = ref.read(chatControllerProvider.notifier);
    final chatList = ref.watch(chatsListProvider);
    final selectedChat = ref.watch(selectedChatProvider);

    return Container(
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide.none,
          left: BorderSide.none,
          right: BorderSide.none,
          bottom: BorderSide(
            color: context.colors.outline,
            width: 1,
          ),
        ),
        color: context.colors.foreground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      ),

      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              spacing: 10,
              children: [
                SoButton(height: 30, width: 30,  color: Colors.transparent, onPressed: () {ref.read(selectedChatProvider.notifier).state = null;},
                  child: Icon(Icons.arrow_back, color: context.colors.textPrimary, size: 25),),
                CircleAvatar(radius: 20, child: Text(chatList.firstWhere((chat) => chat.id == selectedChat!.id).title[0])),
                Text(chatList.firstWhere((chat) => chat.id == selectedChat!.id).title),
                chatList.firstWhere((chat) => chat.id == selectedChat!.id).type == ChatType.GROUP_SECURE ? Icon(Icons.enhanced_encryption, color: context.colors.textSecondary, size: 20,)
                    : chatList.firstWhere((chat) => chat.id == selectedChat!.id).type == ChatType.GROUP_INSECURE ? Icon(Icons.no_encryption, color: context.colors.textSecondary, size: 20) : Container()
              ],
            ),

            Row(
              spacing: 10,
              children: [
                selectedChat?.type == ChatType.GROUP_INSECURE || selectedChat?.type == ChatType.GROUP_SECURE  ?
                SoButton(
                  height: 40,
                  width: 40,
                  onPressed: Menus.addParticipantDialog(context, ref),
                  color: context.colors.foreground,
                  child: Icon(Icons.person_add)) : Container(),
                SoButton(
                  height: 40,
                  width: 40,
                  onPressed: (){
                    {
                      ref.read(isInCallProvider.notifier).state = true;
                    }},
                  color: context.colors.foreground,
                  child: Icon(Icons.call),),
                SoButton(
                  height: 40,
                  width: 40,
                  onPressed: (){
                    {
                      ref.read(selectedChatProvider.notifier).state = null;
                    }},
                  color: context.colors.foreground,
                  child: Icon(Icons.video_call),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}