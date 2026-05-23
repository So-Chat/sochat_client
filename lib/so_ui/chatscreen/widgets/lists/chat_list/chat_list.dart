import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/context/menus.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/extenstions/utils.dart';
import 'package:sochat_client/modules/common/auth_service.dart';
import 'package:sochat_client/so_ui/common/base_panel.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';
import 'package:sochat_client/so_ux/chat_controller.dart';
import 'chat_item.dart';

class ChatList extends ConsumerWidget {

  final Color? borderColor;
  final double? borderRadius;
  final EdgeInsets? padding;

  const ChatList({
    super.key, this.borderColor, this.borderRadius, this.padding
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatListProvider = ref.watch(chatsListProvider);
    final chatController = ref.watch(chatControllerProvider.notifier);
    final authService = ref.watch(authServiceProvider);
    final messageMap = ref.watch(chatMessagesProvider);
    final currentUser = ref.watch(currentUserProvider);

    final sortedChats = [...chatListProvider]..sort((a, b) {
      final messagesA = messageMap[a.id] ?? [];
      final messagesB = messageMap[b.id] ?? [];

      DateTime lastA = messagesA.isNotEmpty ? messagesA.first.timestamp : DateTime.now();
      DateTime lastB = messagesB.isNotEmpty ? messagesB.first.timestamp : DateTime.now();

      return lastB.compareTo(lastA);
    });

    return BasePanel(
      flex: 1,
      borderColor: borderColor,
      borderRadius: borderRadius ?? 10,
      padding: EdgeInsets.all(0),
      backgroundColor: context.colors.surface,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: padding ?? const EdgeInsets.all(8.0),
            child: ListView(
              children: [
                ...sortedChats.map((e) {
                  final messageMap = ref.read(chatMessagesProvider);
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

                  final myParticipant = e.participants.firstWhere(
                        (p) => p.user.id == currentUser!.id,
                  );

                  final lastReadId = myParticipant.lastReadMessageId;

                  final unReadMessageCount = messages
                      .where((m) =>
                  m.id > lastReadId &&
                      m.sender.id != currentUser!.id)
                      .length;

                  return ChatItem(
                    chatId: e.id,
                    clientId: currentUser!.id,
                    description: "No description",
                    lastMessage: lastMessage,
                    isRead: isRead,
                    time: hasMessages
                        ? Utils.buildDateString(lastMessage!.timestamp)
                        : "",
                    onPressed: () async {
                      await chatController.openChat(e);
                    },
                    unReadMessageCount: unReadMessageCount,
                  );
                }),
              ],
            ),
          ),

          Positioned(
            bottom: 10,
            right: 10,
            child: SoButton(
              width: 60,
              height: 60,
              color: context.colors.primary,
              onPressed: Menus.createChatDialog(context, ref),
              child: Icon(Icons.add, size: 45, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}