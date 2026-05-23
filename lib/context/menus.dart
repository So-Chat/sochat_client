import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/modules/chats/chat.dart';
import 'package:sochat_client/modules/chats/chat_role.dart';
import 'package:sochat_client/modules/chats/chat_service.dart';
import 'package:sochat_client/modules/chats/chat_type.dart';
import 'package:sochat_client/modules/common/auth_service.dart';
import 'package:sochat_client/modules/friends/friendship.dart';
import 'package:sochat_client/modules/keys/key.dart';
import 'package:sochat_client/modules/messages/message.dart';
import 'package:sochat_client/modules/users/user.dart';
import 'package:sochat_client/context/context_manager.dart';
import 'package:sochat_client/modules/friends/friends_service.dart';
import 'package:sochat_client/modules/keys/key_service.dart';
import 'package:sochat_client/modules/users/user_service.dart';
import 'package:sochat_client/so_ui/chatscreen/widgets/lists/friend_list/friend_item.dart';
import 'package:sochat_client/so_ui/common/input.dart';
import 'package:sochat_client/so_ui/chatscreen/widgets/search/search_list.dart';
import 'package:sochat_client/context/context_menu_button.dart';
import 'package:sochat_client/context/context_window.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';
import 'package:sochat_client/so_ui/common/so_exception.dart';
import 'package:sochat_client/so_ui/loginscreen/widgets/settings_button.dart';
import 'package:sochat_client/so_ux/chat_controller.dart';
import 'package:sochat_client/so_ux/login_controller.dart';

class Menus {

  static VoidCallback openSearchWindow(
      BuildContext context,
      WidgetRef ref)
  {
    final friendShipService = ref.read(friendsServiceProvider.notifier);
    final chatService = ref.read(chatsServiceProvider.notifier);

    TextEditingController usernameController = TextEditingController();

    return () {
      showContextWindow(
        context,
        ref,
        height: 500,
        width: 720,
        child: Column(
          spacing: 8,
          children: [
            SoCommonInput(textEditingController: usernameController,),


            ///
            ///  DEBUG TOOLS
            ///
            Row(
              children: [
                SoButton(height: 30, width: 30, onPressed: () {
                  friendShipService.sendFriendRequest(usernameController.text);
                }, color: context.colors.caution, child: Icon(Icons.send)),
                SoButton(height: 30, width: 30, onPressed: () {
                  friendShipService.getRelativesList();
                }, color: context.colors.caution, child: Icon(Icons.smart_button)),
                SoButton(height: 30, width: 30, onPressed: () {
                  chatService.getChatList();
                }, color: context.colors.caution,child: Icon(Icons.error),),
              ],
            ),

            Expanded(child: SearchList()),
          ],
        ),
      );
    };
  }

  static VoidCallback openProfile(
      BuildContext context,
      WidgetRef ref,
      Chat chat,
      ) {
    final userService = ref.read(userServiceProvider.notifier);
    final chatService = ref.read(chatsServiceProvider.notifier);
    final currentUser = ref.read(currentUserProvider);

    if (chat.type == ChatType.PRIVATE) {
      return () {
        userService.getUser(username: chat.participants.firstWhere((p) => p.user.id != currentUser!.id).user.username).then((user) {
          final callback = userProfile(context, ref, user);
          callback();
        });
      };
    } else {
      return ()  {
        if (chat.participants.length <= 1 && chat.participants[0].user.id == currentUser!.id) {
          chatService.getChatById(chat.id).then((chat) {
            final callback = chatProfile(context, ref, chat);
            callback();
          });
        } else {
          chatService.getChatById(chat.id).then((chat) {
            final callback = chatProfile(context, ref, chat);
            callback();
          });
        }


      };
    }
  }

  static VoidCallback userProfile(
      BuildContext context,
      WidgetRef ref, User user)
  {
    return showProfileWindow(context, ref, title: user.username, avatarLetter: user.username[0],
        child: Padding(padding: EdgeInsetsGeometry.all(8),
        child: Text(user.description != null ? user.description! : "No description")));
  }

  static VoidCallback chatProfile(
      BuildContext context,
      WidgetRef ref, Chat chat) {

    return showProfileWindow(
        context, ref, title: chat.title, avatarLetter: chat.title[0],

        child: ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              ...chat.participants.map((e) =>
                  FriendItem(user: e.user, color: Colors.transparent,))
            ]));
  }

  static VoidCallback showProfileWindow(
      BuildContext context,
      WidgetRef ref, {
        required String title,
        required String avatarLetter,
        Widget? child,
      }) {
    child ??= Container();
    return () {
      showContextWindow(
        context,
        ref,
        height: 600,
        width: 400,
        child: Container(
          padding: EdgeInsets.all(8),
          child: Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.fromBorderSide(
                    BorderSide(
                      color: context.colors.outline,
                      width: 1,
                    ),
                  ),
                  color: context.colors.foreground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:

                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(radius: 30, child: Text(avatarLetter)),
                      Text(title),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.fromBorderSide(
                      BorderSide(
                        color: context.colors.outline,
                        width: 1,
                      ),
                    ),
                    color: context.colors.foreground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: child
                ),
              ),
              Expanded(
                child: Column(
                  children: [],
                ),
              ),
            ],
          ),
        ),
      );
    };
  }

  static VoidCallback serverEditorWindow(
      BuildContext context,
      int index,
      WidgetRef ref)
  {
    return () {

      var server = ref.read(keyServiceProvider).servers.entries.toList()[index];

      TextEditingController nameController = TextEditingController();
      TextEditingController ipController = TextEditingController();

      nameController.text = server.key;
      ipController.text = server.value;

      String oldKey = server.key;

      showContextWindow(
        context,
        ref,
        height: 220,

        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              spacing: 8,
              children: [
                SoCommonInput(textEditingController: nameController, decoration: InputDecoration(
                  hintText: "Server name",
                ),),
                SoCommonInput(textEditingController: ipController, decoration: InputDecoration(
                  hintText: "Server ip",
                ),),
              ],
            ),

            Row(
              spacing: 8,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SoButton(width: 40, height: 40, borderColor: context.colors.outline,
                  onPressed: () {
                    ref.watch(keyServiceProvider.notifier).updateServerName(oldKey, nameController.text);
                    ref.watch(keyServiceProvider.notifier).updateServerIp(oldKey, ipController.text);

                    ref.read(contextManagerProvider).hideWindow();
                  },child: Icon(Icons.check),),
                SoButton(width: 40, height: 40, borderColor: context.colors.outline,
                  onPressed: () {
                    ref.read(contextManagerProvider).hideWindow();
                  },child: Icon(Icons.close),),
              ],
            ),

          ],
        ),
      );
    };
  }

  static VoidCallback addServerEditorWindow(
      BuildContext context,
      WidgetRef ref)
  {
    return () {
      TextEditingController nameController = TextEditingController();
      TextEditingController ipController = TextEditingController();

      showContextWindow(
        context,
        ref,
        height: 200,

        child: Column(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SoCommonInput(textEditingController: nameController, decoration: InputDecoration(
              hintText: "Server name",
            ),),
            SoCommonInput(textEditingController: ipController, decoration: InputDecoration(
              hintText: "Server ip",
            ),),
            Row(
              spacing: 16,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SettingsButton(Icons.check, size: 40,
                  onPressed: () {
                    ref.watch(keyServiceProvider.notifier).addServer(nameController.text, ipController.text);
                    ref.read(contextManagerProvider).hideMenu();
                  },),
                SettingsButton(Icons.close, size: 40,
                  onPressed: () {
                    ref.read(contextManagerProvider).hideMenu();
                  },)
              ],
            ),

          ],
        ),
      );
    };
  }

  static VoidCallback keyEditorWindow(
      BuildContext context,
      int index,
      WidgetRef ref)
  {
    return () {

      var profile = ref.read(keyServiceProvider).profiles.entries.toList()[index];
      TextEditingController nameController = TextEditingController();
      nameController.text = profile.key;

      String oldKey = profile.key;

      showContextWindow(
        context,
        ref,
        height: 200,

        child: Column(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SoCommonInput(textEditingController: nameController, decoration: InputDecoration(
              hintText: "Profile name",
            ),),
            Row(
              spacing: 16,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SettingsButton(Icons.check, size: 40,
                  onPressed: () {
                    ref.watch(keyServiceProvider.notifier).updateProfileName(oldKey, nameController.text);
                    ref.read(contextManagerProvider).hideWindow();
                  },),
                SettingsButton(Icons.close, size: 40,
                  onPressed: () {
                    ref.read(contextManagerProvider).hideWindow();
                  },)
              ],
            ),
          ],
        ),
      );
    };
  }

  static VoidCallback createChatDialog(
      BuildContext context,
      WidgetRef ref)
  {
    return () async {
      TextEditingController chatNameController = TextEditingController();


      ChatService chatService = ref.read(chatsServiceProvider.notifier);

      await ref.read(chatControllerProvider.notifier).getFriendsList();
      final friendsList = ref.read(friendsListProvider);

      final selectedButtons = ValueNotifier<List<int>>([]);
      final isNotSecure = ValueNotifier<bool>(false);

      final errorText = ValueNotifier<String>("");

      final contextService = ref.read(contextManagerProvider);

      showContextWindow(
        context,
        ref,
        height: 500,
        width: 450,

          child: Column(
            spacing: 8,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SoCommonInput(
                    textEditingController: chatNameController,
                    decoration: InputDecoration(
                      hintText: "Type chat name",
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: errorText,
                    builder: (context, value, child) {
                      return Text(value, style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: context.colors.critical,
                        fontWeight: FontWeight.bold,
                      ),);
                    }
                  ),
                ],
              ),


              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.foreground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      bottom: BorderSide(color: context.colors.outline, width: 1),
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: friendsList.length,
                    itemBuilder: (context, index) {
                      return ValueListenableBuilder(
                        valueListenable: selectedButtons,
                        builder: (context, selected, _) {

                          final isSelected = selected.contains(index);

                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SoButton(
                              color: isSelected ? Colors.black.withValues(alpha: 0.05) : Colors.transparent,
                              width: 300,
                              height: 60,
                              onPressed: () {
                                if (isSelected) {
                                  selectedButtons.value = List.from(selected)..remove(index);
                                } else {
                                  selectedButtons.value = List.from(selected)..add(index);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 25,
                                          child: Text(friendsList[index].username[0]),
                                        ),
                                        SizedBox(width: 8),
                                        Text(friendsList[index].username),
                                      ],
                                    ),
                                    isSelected ? Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Icon(Icons.check),
                                    ) : Container()
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      );
                    },
                  ),
                ),
              ),
              SoButton(
                width: 500,
                height: 50,
                onPressed: () async {
                  if (["", " "].any((c) => c == chatNameController.text)) {
                    errorText.value = "Chat name can'be null!";
                    return;
                  }

                  try {
                    List<int> userId = [];
                    for (int friendIndex in selectedButtons.value) {
                      userId.add(friendsList[friendIndex].id);
                    }
                    if (!isNotSecure.value) {
                      await chatService.createChat(userId, ChatType.GROUP_SECURE,
                          chatNameController.text);
                    } else {
                      await chatService.createChat(userId, ChatType.GROUP_INSECURE,
                          chatNameController.text);
                    }
                    contextService.hideMenu();
                  } on SoException catch(e) {
                    errorText.value = e.cause;
                  } catch (e){
                    errorText.value = e.toString();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Create Group", textAlign: .center),
                ),
              ),
              Row(
                spacing: 4,
                children: [
                  SoButton(
                    width: 30,
                    height: 30,
                    color: Colors.transparent,
                    onPressed: () { isNotSecure.value = !isNotSecure.value; },
                    child: ValueListenableBuilder(
                      valueListenable: isNotSecure,
                      builder: (context, value, _) {
                        final isSecured = value;
                        return isSecured ? Icon(Icons.check_box_outlined) : Icon(Icons.check_box_outline_blank);
                      }
                    ),
                    ),
                  Text(
                    "show chat history for new members?"
                  ),
                  Text(
                      "(unsecure)",
                    style: TextStyle(
                      color: context.colors.critical
                    ),
                  )
                ],
              )
            ],
          )
      );
    };
  }


  static VoidCallback addParticipantDialog(
      BuildContext context,
      WidgetRef ref)
  {
    return () async {
      ChatService chatService = ref.read(chatsServiceProvider.notifier);

      await ref.read(chatControllerProvider.notifier).getFriendsList();
      final friendsList = ref.read(friendsListProvider);
      final selectedChat = ref.read(selectedChatProvider.notifier).state;
      final selectedButtons = ValueNotifier<List<int>>([]);

      showContextWindow(
          context,
          ref,
          height: 500,
          width: 450,

          child: Column(
            spacing: 8,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.foreground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      bottom: BorderSide(color: context.colors.outline, width: 1),
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: friendsList.length,
                    itemBuilder: (context, index) {
                      return ValueListenableBuilder(
                          valueListenable: selectedButtons,
                          builder: (context, selected, _) {

                            final isSelected = selected.contains(index);

                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SoButton(
                                color: isSelected ? Colors.black.withValues(alpha: 0.05) : Colors.transparent,
                                width: 300,
                                height: 60,
                                onPressed: () {
                                  if (isSelected) {
                                    selectedButtons.value = List.from(selected)..remove(index);
                                  } else {
                                    selectedButtons.value = List.from(selected)..add(index);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 25,
                                            child: Text(friendsList[index].username[0]),
                                          ),
                                          SizedBox(width: 8),
                                          Text(friendsList[index].username),
                                        ],
                                      ),
                                      isSelected ? Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Icon(Icons.check),
                                      ) : Container()
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                      );
                    },
                  ),
                ),
              ),
              SoButton(
                width: 500,
                height: 50,
                onPressed: () async {
                  List<int> userIds = [];
                  for (int friendIndex in selectedButtons.value){
                    userIds.add(friendsList[friendIndex].id);
                  }

                  for (int userId in userIds) {
                    await chatService.addParticipant(userId, selectedChat!);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Add users", textAlign: .center),
                ),
              ),
            ],
          )
      );
    };
  }


  static List<ContextMenuButton> userContext(
      BuildContext context,
      WidgetRef ref,
      Chat chat, String description, int? lastMessageId) {

    final chatService = ref.read(chatsServiceProvider.notifier);
    final currentUser = ref.read(currentUserProvider);
    final blockedList = ref.read(blockedListProvider);
    final chatController = ref.read(chatControllerProvider.notifier);


    List<ContextMenuButton> items = [];

    items.addAll([
      ContextMenuButton(text: chat.title,
        leading: CircleAvatar(radius: 20, child: Text(chat.title[0])), onTap: openProfile(context, ref, chat),
        description: description,),
      ContextMenuButton(text: "Pin",
          leading: Icon(Icons.push_pin), onTap: () {}),

    ]);

    if (lastMessageId != null) {
      items.add(ContextMenuButton(text: "Mark read",
          leading: Icon(Icons.mark_chat_read), onTap: () {
            chatController.setLastReadMessage(lastMessageId, chat.id);
          }));
    }

    if (chat.participants.firstWhere((p) => p.user.id == currentUser!.id).chatRole == ChatRole.OWNER || chat.type == ChatType.PRIVATE){
      items.add(ContextMenuButton(text: "Delete chat",
          leading: Icon(Icons.delete_forever), onTap: () {
            chatService.deleteChat(chat.id);
          }));
    }
    else if (chat.participants.firstWhere((p) => p.user.id == currentUser!.id).chatRole == ChatRole.MEMBER){
      items.add(ContextMenuButton(text: "Leave chat",
          leading: Icon(Icons.delete_forever), onTap: () {
            chatService.leaveChat(currentUser!.id, chat.id);
          }));
    }
/*
    if (blockedList.contains(chat.participants[chat.participants.keys.firstWhere((u) => u.username == chat.title)])){
      items.add(ContextMenuButton(text: "Block",
          leading: Icon(Icons.block), onTap: () {}));
    }
    */

    return items;
  }

  static List<ContextMenuButton> friendContext(
      BuildContext context,
      WidgetRef ref,
      User user, String description) {
    final friendshipService = ref.read(friendsServiceProvider.notifier);
    final chatService = ref.read(chatsServiceProvider.notifier);
    final chatController = ref.read(chatControllerProvider.notifier);

    List<ContextMenuButton> items = [];

    items.add(ContextMenuButton(text: user.username,
      leading: CircleAvatar(radius: 20, child: Text(user.username[0])), onTap: () {} ,
      description: description));

    FriendshipStatus status = friendshipService.friendships[user.username]!.status;

    if (status == FriendshipStatus.ACCEPTED){
      items.add(ContextMenuButton(text: "Remove friend",
          leading: Icon(Icons.remove_circle_outline),
          onTap: () { friendshipService.removeFriend(user.username);}));
      if (ref.read(chatsListProvider).any((c) => c.type == ChatType.PRIVATE && c.participants.any((p) => p.user.id == user.id)))
      {
        items.add(ContextMenuButton(text: "Open chat",
            leading: Icon(Icons.chat),
            onTap: () {chatController.openChat(ref.read(chatsListProvider).firstWhere((c) => c.participants.any((p) => p.user.id == user.id) && c.type == ChatType.PRIVATE));}));
      } else {
        items.add(ContextMenuButton(text: "Create chat",
            leading: Icon(Icons.face_retouching_natural_sharp),
            onTap: () { chatService.createChat([user.id], ChatType.PRIVATE, null);}));
      }

      items.add(ContextMenuButton(text: "Block",
          leading: Icon(Icons.block),
          onTap: () { friendshipService.blockUser(user.username);}));
    }
    else if (status == FriendshipStatus.PENDING){
      items.add(ContextMenuButton(text: "Decline request",
          leading: Icon(Icons.face_retouching_natural_sharp),
          onTap: () { friendshipService.removeFriend(user.username);}));

      items.add(ContextMenuButton(text: "Block",
          leading: Icon(Icons.block),
          onTap: () { friendshipService.blockUser(user.username);}));
    }

    else if (status == FriendshipStatus.BLOCKED){
      items.add(ContextMenuButton(text: "Unblock",
          leading: Icon(Icons.face_retouching_natural_sharp),
          onTap: () { friendshipService.blockUser(user.username);}));
    }


    return items;
  }

  static List<ContextMenuButton> avatarContext(
      BuildContext context,
      WidgetRef ref, User user) {
    final loginController = ref.read(loginControllerProvider.notifier);
    return [
      ContextMenuButton(
        text: "${user.nickname} (${user.username})",
        leading: CircleAvatar(radius: 20, child: Text(user.nickname[0])),
        onTap: () { },
        description: user.getDesc()
      ),
      ContextMenuButton(
        text: "Log-out",
        leading: Icon(Icons.logout),
        onTap: () { loginController.logout(context); },
      ),
    ];
  }


  static List<ContextMenuButton> keysListContext(
      BuildContext context,
      int index,
      WidgetRef ref,
      MapEntry<String, KeyP> profile) {
    return [
      ContextMenuButton(
        text: "Edit name",
        leading: Icon(Icons.edit),
        onTap: Menus.keyEditorWindow(context, index, ref)
      ),
      ContextMenuButton(
          text: "Copy JSON",
          leading: Icon(Icons.copy),
          onTap: Menus.keyEditorWindow(context, index, ref)
      ),
      ContextMenuButton(
        text: "Delete",
        leading: Icon(Icons.delete_forever),
        color: context.colors.critical,
        onTap: () {
          ref.read(keyServiceProvider.notifier).removeProfile(profile.key);
        },
      ),
    ];
  }

  static List<ContextMenuButton> serversListContext(
      BuildContext context,
      int index,
      WidgetRef ref,
      MapEntry<String, String> server) {
    return [
      ContextMenuButton(
        text: "Edit",
        leading: Icon(Icons.edit),
        onTap: Menus.serverEditorWindow(context, index, ref),
      ),
      ContextMenuButton(
        text: "Delete",
        leading: Icon(Icons.delete_forever),
        color: context.colors.critical,
        onTap: () {
          ref.read(keyServiceProvider.notifier).removeServer(server.key);
        },
      ),
    ];
  }

  static List<ContextMenuButton> messageContextMenu(
      BuildContext context,
      WidgetRef ref, Message message) {
    return [
      ContextMenuButton(
        text: "Edit",
        leading: Icon(Icons.edit),
        onTap: () {},
      ),
      ContextMenuButton(
        text: "Delete",
        leading: Icon(Icons.delete_forever),
        color: context.colors.critical,
        onTap: () {},
      ),
    ];
  }
}