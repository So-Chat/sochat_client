import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sochat_client/context/menus.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/modules/calls/call_service.dart';
import 'package:sochat_client/modules/chats/chat.dart';
import 'package:sochat_client/modules/common/auth_service.dart';
import 'package:sochat_client/modules/users/user.dart';
import 'package:sochat_client/so_ui/common/sub_buttons/avatar_button.dart';
import 'package:sochat_client/so_ui/chatscreen/widgets/lists/chat_list/chat_list.dart';
import 'package:sochat_client/so_ui/chatscreen/widgets/chat_window/chat_window.dart';
import 'package:sochat_client/so_ui/chatscreen/widgets/lists/friend_list/friend_list.dart';
import 'package:sochat_client/so_ui/chatscreen/widgets/lists/settings/settings_list.dart';
import 'package:sochat_client/so_ui/common/sub_buttons/search_button.dart';
import 'package:sochat_client/so_ui/chatscreen/widgets/settings_window/settings_window.dart';
import 'package:sochat_client/so_ui/common/sub_buttons/top_button.dart';

import 'package:sochat_client/so_ux/chat_controller.dart';
import 'package:sochat_client/so_ux/settings_controller.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

final activeList = StateProvider<int>((ref) => 0);

class _ChatScreenState extends ConsumerState<ChatScreen> {

  double width = 0;

  @override
  void initState() {

    final chatController = ref.read(chatControllerProvider.notifier);
    chatController.getChatList();
    chatController.getFriendsList();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeList);
    final activeSettings = ref.watch(selectedSettingsOptionProvider);

    final selectedChat = ref.watch(selectedChatProvider);
    final currentUser = ref.watch(currentUserProvider);

    ref.read(callServiceProvider);

    width = MediaQuery.sizeOf(context).width;

    if (Platform.isAndroid || Platform.isIOS || Platform.isFuchsia) {
      return Scaffold(
        backgroundColor: context.colors.surface,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(0,0,0,0),
          child: Column(
            spacing: 8,
            children: [
              if (selectedChat == null) _buildTopBar(currentUser, padding: EdgeInsets.fromLTRB(8,8,8,0)),
                width >= 600
                    ? Expanded(child: _buildFullLayout(active,
                    backgroundColor: context.colors.surface,
                      borderRadius: 0, borderColor: Colors.transparent, chatTopBorderRadius: 0, messageInputPadding: EdgeInsets.all(8), listPadding: EdgeInsets.all(0)))

                    : _buildMiniLayout(active, activeSettings, selectedChat,
                    backgroundColor: context.colors.surface,
                      borderRadius: 0, borderColor: Colors.transparent, chatTopBorderRadius: 0, messageInputPadding: EdgeInsets.all(8), listPadding: EdgeInsets.all(0)),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          spacing: 8,
          children: [
            _buildTopBar(currentUser),
            width >= 600
                  ? Expanded(child: _buildFullLayout(active, backgroundColor: context.colors.foreground,
                    borderRadius: 10, chatTopBorderRadius: 10, messageInputPadding: EdgeInsets.all(0)))
                  : _buildMiniLayout(active, activeSettings, selectedChat, backgroundColor: context.colors.foreground,
                    borderRadius: 10, chatTopBorderRadius: 10, messageInputPadding: EdgeInsets.all(0)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(User? currentUser, {EdgeInsets? padding}) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(0.0),
      child: Column(
        children: [
          Row(
            spacing: 8,
            children: [
              if (!(Platform.isAndroid || Platform.isFuchsia || Platform.isIOS || width <= 600)) Row(
                spacing: 8,
                children: [
                  TopButton(Icons.sms, onPressed: () {
                    ref.read(activeList.notifier).state = 0;
                  }),
                  TopButton(Icons.person, onPressed: () {
                    ref.read(activeList.notifier).state = 1;
                  }),
                  TopButton(Icons.settings, onPressed: () {
                    ref.read(activeList.notifier).state = 2;
                    ref.read(selectedSettingsOptionProvider.notifier).state = 0;
                  }),
                ],
              ),
      
              Expanded(
                flex: 4,
                child: SearchButton(
                  onPressed: Menus.openSearchWindow(context, ref),
                ),
              ),
      
              Row(
                spacing: 8,
                children: [
                  TopButton(Icons.inbox_rounded),
                  AvatarButton(user: currentUser!),
                ],
              ),
            ],
          ),
        if (Platform.isAndroid || Platform.isFuchsia || Platform.isIOS || width <= 600) Padding(
          padding: padding ?? EdgeInsets.all(0),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TopButton(Icons.sms, onPressed: () {
                  ref.read(activeList.notifier).state = 0;
                }),
                TopButton(Icons.person, onPressed: () {
                  ref.read(activeList.notifier).state = 1;
                }),
                TopButton(Icons.settings, onPressed: () {
                  ref.read(activeList.notifier).state = 2;
                  ref.read(selectedSettingsOptionProvider.notifier).state = 0;
                }),
              ],
            ),
        )
        ],
      ),
    );
  }

  Widget _buildFullLayout(int active, {Color? backgroundColor, Color? borderColor, double? borderRadius, double? chatTopBorderRadius, EdgeInsets? messageInputPadding, EdgeInsets? listPadding}) {
    return Row(
      spacing: 8,
      children: [
        if (active == 0) ChatList(borderRadius: borderRadius, borderColor: borderColor, padding: listPadding),
        if (active == 1) FriendList(borderRadius: borderRadius, borderColor: borderColor, padding: listPadding),
        if (active == 2) SettingsList(borderRadius: borderRadius, borderColor: borderColor, padding: listPadding),

        ([0, 1].contains(active))
            ? ChatWindow(backgroundColor: backgroundColor, borderColor: borderColor, borderRadius: borderRadius, topBorderRadius: chatTopBorderRadius, messageInputPadding: messageInputPadding,)
            : SettingsWindow(),
      ],
    );
  }

  Widget _buildMiniLayout(int active, int activeSettings, Chat? selectedChat, {Color? backgroundColor, Color? borderColor, double? borderRadius, double? chatTopBorderRadius, EdgeInsets? messageInputPadding, EdgeInsets? listPadding }) {
    if (selectedChat != null) {
      return ChatWindow(backgroundColor: backgroundColor, borderColor: borderColor, borderRadius: borderRadius, topBorderRadius: chatTopBorderRadius, messageInputPadding: messageInputPadding);
    }
    switch (active) {
      case 0:
        return ChatList(borderRadius: borderRadius, borderColor: borderColor, padding: listPadding);
      case 1:
        return FriendList(borderRadius: borderRadius, borderColor: borderColor, padding: listPadding);
      case 2:
        //return SettingsWindow();
      default:
        switch (activeSettings){
          case 1: return SettingsWindow(backgroundColor: backgroundColor, borderColor: borderColor, borderRadius: borderRadius, textInputColor: context.colors.background);
          case 2: return SettingsWindow(backgroundColor: backgroundColor, borderColor: borderColor, borderRadius: borderRadius, textInputColor: context.colors.background);
          case 3: return SettingsWindow(backgroundColor: backgroundColor, borderColor: borderColor, borderRadius: borderRadius, textInputColor: context.colors.background);
          default: return SettingsList(borderRadius: borderRadius, borderColor: borderColor, padding: listPadding);
        }


    }
  }
}
