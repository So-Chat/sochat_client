import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:sochat_client/context/context_menu.dart';
import 'package:sochat_client/context/menus.dart';
import 'package:sochat_client/extenstions/hex_color.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/extenstions/utils.dart';
import 'package:sochat_client/modules/common/auth_service.dart';
import 'package:sochat_client/modules/keys/key_service.dart';
import 'package:sochat_client/modules/messages/message.dart';
import 'package:sochat_client/so_ui/common/sub_buttons/downloadable_file.dart';
import 'package:sochat_client/so_ux/chat_controller.dart';


class MessageList extends ConsumerStatefulWidget {
  MessageList(this.textFieldFocusNode, {super.key});
  final FocusNode textFieldFocusNode;
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => MessageListState();
}

class MessageListState extends ConsumerState<MessageList>{
  final ScrollOffsetController _scrollOffsetController = ScrollOffsetController();
  final ScrollOffsetListener _scrollOffsetListener = ScrollOffsetListener.create();

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();

    final chatController = ref.read(chatControllerProvider.notifier);

    final authService = ref.read(authServiceProvider);

    final currentUser = ref.read(currentUserProvider);

    _itemPositionsListener.itemPositions.addListener(() {
      final selectedChat = ref.read(selectedChatProvider);

      if (isAtBottom(ref.read(chatMessagesProvider)[selectedChat!.id]!)){
          chatController.loadRecentMessages();
      }

      final messages = ref.read(chatMessagesProvider)[selectedChat!.id]!;

      final positions = _itemPositionsListener.itemPositions.value;

      if (positions.isNotEmpty) {
        final index = positions.first.index;

        if (index >= 0 && index < messages.length) {
          final message = messages[index];

          final myParticipant = selectedChat.participants
              .firstWhere((p) => p.user.id == currentUser!.id);

          if (message.id > myParticipant.lastReadMessageId && message.sender.id != myParticipant.user.id) {
            chatController.setLastReadMessage(message.id, message.chatId);
          }
        }
      }
    });

  }

  bool isAtBottom(List<Message> messages) {
    final positions = _itemPositionsListener.itemPositions.value;

    if (positions.isEmpty) return false;

    final maxVisibleIndex = positions
        .where((p) => p.itemLeadingEdge < 1 && p.itemTrailingEdge > 0)
        .map((p) => p.index)
        .fold<int>(-1, (a, b) => a > b ? a : b);

    return maxVisibleIndex >= messages.length - 1;
  }



  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messageMap = ref.watch(chatMessagesProvider);
    final selectedChat = ref.watch(selectedChatProvider);
    final authService = ref.watch(authServiceProvider);
    final currentUser = ref.watch(currentUserProvider);

    messageMap[selectedChat!.id] ??= [];
    return Expanded(
        child: SelectionArea(
          contextMenuBuilder: (context, editableTextState) {
            return const SizedBox.shrink();
          },
          child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                widget.textFieldFocusNode.requestFocus();
              },

              child: ScrollablePositionedList.builder(
                scrollOffsetController: _scrollOffsetController,
                scrollOffsetListener: _scrollOffsetListener,
                itemPositionsListener: _itemPositionsListener,
                itemScrollController: _itemScrollController,
                reverse: true, itemCount: messageMap[selectedChat.id]!.length, itemBuilder: (context, index) {
              final message = messageMap[selectedChat.id]![index];

              return GestureDetector(
                onSecondaryTapDown: (details) { showContextMenu(context, details.globalPosition, ref, items: Menus.messageContextMenu(context, ref, message)); },
                child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.transparent,
                          ),
                        ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          CircleAvatar(
                            radius: 19,
                            child: Text(message.sender.username[0]),
                          ),
                          Expanded(
                            child: Column(
                              spacing: 4,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  spacing: 4,
                                  children: [
                                    Text(
                                      message.sender.nickname,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    Text(
                                      Utils.buildDateString(message.timestamp),
                                      style: Theme.of(context).textTheme.labelSmall,
                                    ),
                                    if (message.sender.id == currentUser!.id)
                                    Text(selectedChat.participants.any((p) => p.lastReadMessageId >= message.id && p.user.id != currentUser!.id) ? "Read" : "Unread", style: Theme.of(context).textTheme.labelSmall,),
                                  ],
                                ),
                                if (!["", " "].any((c) => c == message.content)) Text(
                                  message.content,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),

                                if (message.mediaFiles != null && message.mediaFiles!.isNotEmpty)
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: message.mediaFiles!.length,
                                    itemBuilder: (context, index) {
                                      final file = message.mediaFiles![index];
                                      if (file.mimeType!.contains("image")) {
                                          return Image.network(
                                              "${ref.read(keyServiceProvider.notifier).servers.entries.toList()[ref.read(selectedServerProvider)].value}/media/${file.mediaId!}",
                                              alignment: Alignment.topLeft,
                                              width: 160, height: 160);
                                      }
                                      else {
                                        return DownloadableFile(file);
                                      }
                                    },
                                  )

                              ],
                            ),
                          ),
                        ],
                      )
                    ),
                ),
              );
            }
            ),
          ),
        ),
    );
  }
}