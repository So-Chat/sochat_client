import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/context/context_menu.dart';
import 'package:sochat_client/context/context_window.dart';
import 'package:sochat_client/context/menus.dart';

import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/extenstions/utils.dart';
import 'package:sochat_client/modules/chats/chat.dart';
import 'package:sochat_client/modules/chats/chat_service.dart';
import 'package:sochat_client/modules/chats/chat_type.dart';
import 'package:sochat_client/modules/friends/friends_service.dart';
import 'package:sochat_client/modules/messages/message.dart';
import 'package:sochat_client/modules/users/user.dart';
import 'package:sochat_client/modules/users/user_service.dart';
import 'package:sochat_client/so_ui/common/input.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';
import 'package:sochat_client/so_ux/chat_controller.dart';

class SearchWindow extends ConsumerStatefulWidget {
  const SearchWindow();

  @override
  ConsumerState<SearchWindow> createState() => _SearchWindowState();
}

class _SearchWindowState extends ConsumerState<SearchWindow> {
  TextEditingController usernameController = TextEditingController();
  List<User> users = [];

  late final friendShipService;
  late final chatService;
  late final userService;

  @override
  void initState() {
    super.initState();

    friendShipService = ref.read(friendsServiceProvider.notifier);
    chatService = ref.read(chatsServiceProvider.notifier);
    userService = ref.read(userServiceProvider.notifier);
  }

  Future<void> _search(String query) async {
    final result = await userService.searchUser(query);

    setState(() {
      users = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sortedChats = ref.watch(sortedChatsProvider);
    final chatMessages = ref.watch(chatMessagesProvider);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide.none,
          left: BorderSide.none,
          right: BorderSide.none,
          bottom: BorderSide(color: context.colors.outline, width: 1),
        ),
        color: context.colors.foreground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        spacing: 8,
        children: [
          SoCommonInput(
            textEditingController: usernameController,
            onChanged: (text) async {
              await _search(text);
            },
          ),

          ///
          ///  DEBUG TOOLS
          ///
          if (kDebugMode)
            Container(
              child: Row(
                children: [
                  SoButton(
                    height: 30,
                    width: 30,
                    onPressed: () {
                      friendShipService.sendFriendRequest(
                        usernameController.text,
                      );
                    },
                    color: context.colors.caution,
                    child: Icon(Icons.send),
                  ),
                  SoButton(
                    height: 30,
                    width: 30,
                    onPressed: () {
                      friendShipService.getRelativesList();
                    },
                    color: context.colors.caution,
                    child: Icon(Icons.smart_button),
                  ),
                  SoButton(
                    height: 30,
                    width: 30,
                    onPressed: () {
                      chatService.getChatList();
                    },
                    color: context.colors.caution,
                    child: Icon(Icons.error),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return SoButton(
                  alignment: Alignment.centerLeft,
                  height: 40,
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          child: users[index].nickname != users[index].username
                              ? Text(users[index].nickname[0])
                              : Text(users[index].username[0]),
                        ),
                        const SizedBox(width: 8),

                        Expanded(
                          child: Row(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    users[index].nickname,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),

                                  if (users[index].nickname !=
                                      users[index].username) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      users[index].username,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelMedium,
                                    ),
                                  ],
                                ],
                              ),

                              const Spacer(),

                              buildChatInfoIfContains(
                                users[index],
                                sortedChats,
                                chatMessages,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  onPressed: Menus.userProfile(context, ref, users[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildChatInfoIfContains(
    User user,
    List<Chat> chatList,
    Map<int, List<Message>> chatMessages,
  ) {
    Chat? chat;

    try {
      chat = chatList.firstWhere(
        (chat) =>
            chat.participants.any((p) => p.user.id == user.id) &&
            chat.type == ChatType.PRIVATE,
      );
    } catch (_) {
      chat = null;
    }
    if (chat == null) return const SizedBox.shrink();

    List<Message> messages = chatMessages[chat.id] ?? [];

    if (messages.isEmpty) return Container();

    return Row(
      spacing: 8,
      children: [
        Text(
          messages.first.content,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          Utils.buildDateString(messages.first.timestamp),
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}
