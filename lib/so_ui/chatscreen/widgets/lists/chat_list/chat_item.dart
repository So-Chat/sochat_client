import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/context/menus.dart';
import 'package:sochat_client/context/context_menu.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/context/context_menu_button.dart';
import 'package:sochat_client/modules/chats/chat.dart';
import 'package:sochat_client/modules/chats/chat_type.dart';
import 'package:sochat_client/modules/messages/message.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';
import 'package:sochat_client/so_ux/chat_controller.dart';

class ChatItem extends ConsumerWidget {
  ChatItem({
    super.key,
    required this.chatId,
    this.clientId = 0,
    this.lastMessage,
    this.time = "", this.isRead = false,
    this.description = "",
    this.onPressed,
    this.unReadMessageCount = 0,
  });

  final int chatId;
  final Message? lastMessage;

  final String time;
  final bool? isRead;

  int unReadMessageCount;

  final String description;
  final GestureTapCallback? onPressed;

  int clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chat = ref.watch(
      chatsListProvider.select(
            (state) => state.firstWhere((c) => c.id == chatId, orElse: () {return Chat(id: 0, title: '', type: ChatType.PRIVATE);}),
      ),
    );
      return Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(10),
        child: SoButton(
          height: 75,
          color: Colors.transparent,
          width: double.infinity,
          onPressed: onPressed,
          onSecondaryTapDown: (details) {
            List<ContextMenuButton> menuItems = Menus.userContext(context, ref, chat, description, lastMessage?.id);
            showContextMenu(context, details, items: menuItems, ref);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Row(
              children: [
                CircleAvatar(radius: 25, child: Text(chat.title[0])),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              spacing: 4,
                              children: [
                                chat.type != ChatType.PRIVATE ? Icon(Icons.group) : chat.type == ChatType.PRIVATE ? Icon(Icons.person) : Icon(Icons.groups),
                                Expanded(
                                  child: Text(
                                    chat.title,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            flex: 1,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              spacing: 4,
                              children: [
                                Flexible(
                                  child: Text(
                                    (isRead != null && isRead!) ? "Read" : "Unread",
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ),
                                Flexible(child: Text(
                                  time,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: lastMessage != null ? Text(
                              (lastMessage!.sender.id == clientId
                                  ? "You: ${lastMessage!.content}"
                                  : "${lastMessage!.sender.username}: ${lastMessage!.content}") +
                                  (lastMessage!.mediaFiles != null && lastMessage!.mediaFiles!.isNotEmpty
                                      ? "${lastMessage!.mediaFiles!.first.fileName}" : ""),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: Theme.of(context).textTheme.labelMedium,
                            ) : Text(
                                "No messages",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          if (unReadMessageCount > 0)
                            Container(
                              margin: EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: context.colors.primary,
                              ),
                              width: 25,
                              height: 25,
                              child: Center(
                                child: Text(
                                  unReadMessageCount.toString(),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
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
