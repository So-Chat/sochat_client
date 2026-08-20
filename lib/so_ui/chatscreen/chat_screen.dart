import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _ChatScreenState extends ConsumerState<ChatScreen> {
  double width = 0;

  final resizableController = ResizableController();
  final GlobalKey _avatarButtonKey = GlobalKey();

  @override
  void initState() {
    final chatController = ref.read(chatControllerProvider.notifier);
    chatController.loadChatList();
    chatController.loadFriendsList();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final chatController = ref.read(chatControllerProvider.notifier);

    final active = ref.watch(chatControllerProvider).activeList;
    final activeSettings = ref.watch(settingsControllerProvider).selectedOption;

    final selectedChat = ref.watch(chatControllerProvider).selectedChat;
    final currentUser = ref.watch(authServiceProvider).currentUser;

    ref.read(callServiceProvider);

    width = MediaQuery.sizeOf(context).width;

    if (Platform.isAndroid || Platform.isIOS || Platform.isFuchsia) {
      return Scaffold(
        backgroundColor: context.colors.surface,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          child: Column(
            spacing: 8,
            children: [
              if (selectedChat == null)
                _buildTopBar(
                  currentUser, chatController,
                  padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
                ),
              width >= 600
                  ? Expanded(
                      child: _buildFullLayout(
                        active,
                        backgroundColor: context.colors.surface,
                        borderRadius: 0,
                        borderColor: Colors.transparent,
                        chatTopBorderRadius: 0,
                        messageInputPadding: EdgeInsets.all(8),
                        listPadding: EdgeInsets.all(0),
                      ),
                    )
                  : _buildMiniLayout(
                      active,
                      activeSettings,
                      selectedChat,
                      backgroundColor: context.colors.surface,
                      borderRadius: 0,
                      borderColor: Colors.transparent,
                      chatTopBorderRadius: 0,
                      messageInputPadding: EdgeInsets.all(8),
                      listPadding: EdgeInsets.all(0),
                    ),
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
            _buildTopBar(currentUser, chatController),
            width >= 600
                ? Expanded(
                    child: _buildFullLayout(
                      active,
                      backgroundColor: context.colors.foreground,
                      borderRadius: 10,
                      chatTopBorderRadius: 10,
                      messageInputPadding: EdgeInsets.all(0),
                    ),
                  )
                : _buildMiniLayout(
                    active,
                    activeSettings,
                    selectedChat,
                    backgroundColor: context.colors.foreground,
                    borderRadius: 10,
                    chatTopBorderRadius: 10,
                    messageInputPadding: EdgeInsets.all(0),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(User? currentUser, ChatController chatController, {EdgeInsets? padding}) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(0.0),
      child: Column(
        children: [
          Row(
            spacing: 8,
            children: [
              if (!(Platform.isAndroid ||
                  Platform.isFuchsia ||
                  Platform.isIOS ||
                  width <= 600))
                Row(
                  spacing: 8,
                  children: [
                    TopButton(
                      Icons.sms,
                      onPressed: () {
                        chatController.setActiveList(0);
                      },
                    ),
                    TopButton(
                      Icons.person,
                      onPressed: () {
                        chatController.setActiveList(1);
                      },
                    ),
                    TopButton(
                      Icons.settings,
                      onPressed: () {
                        chatController.setActiveList(2);
                        ref
                        .read(settingsControllerProvider.notifier).setSelectedOption(0);
                      },
                    ),
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
                  AvatarButton(user: currentUser, buttonKey: _avatarButtonKey),
                ],
              ),
            ],
          ),
          if (Platform.isAndroid ||
              Platform.isFuchsia ||
              Platform.isIOS ||
              width <= 600)
            Padding(
              padding: padding ?? EdgeInsets.all(0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TopButton(
                    Icons.sms,
                    onPressed: () {
                      chatController.setActiveList(0);
                    },
                  ),
                  TopButton(
                    Icons.person,
                    onPressed: () {
                      chatController.setActiveList(1);
                    },
                  ),
                  TopButton(
                    Icons.settings,
                    onPressed: () {
                      chatController.setActiveList(2);
                      ref.read(settingsControllerProvider.notifier).setSelectedOption(0);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFullLayout(
    int active, {
    Color? backgroundColor,
    Color? borderColor,
    double? borderRadius,
    double? chatTopBorderRadius,
    EdgeInsets? messageInputPadding,
    EdgeInsets? listPadding,
  }) {
    return ResizableContainer(
      direction: Axis.horizontal,
      controller: resizableController,
      children: [
        ResizableChild(
          divider: ResizableDivider(
              thickness: 8,
              color: Colors.transparent,
          ),
          size: ResizableSize.ratio(0.35, min: 110),
          child: (
            (active == 0) ?
          ChatList(
            borderRadius: borderRadius,
            borderColor: borderColor,
            padding: listPadding,
          ) : (active == 1) ?
          FriendList(
            borderRadius: borderRadius,
            borderColor: borderColor,
            padding: listPadding,
          ) : (active == 2) ?
          SettingsList(
            borderRadius: borderRadius,
            borderColor: borderColor,
            padding: listPadding,
          ): Container()
          )
        ),
        ResizableChild(
          size: ResizableSize.expand(min: 500),
          child: ([0, 1].contains(active))
            ? ChatWindow(
                backgroundColor: backgroundColor,
                borderColor: borderColor,
                borderRadius: borderRadius,
                topBorderRadius: chatTopBorderRadius,
                messageInputPadding: messageInputPadding,
            ) : SettingsWindow()
        ),
      ],
    );
  }

  Widget _buildMiniLayout(
    int active,
    int activeSettings,
    Chat? selectedChat, {
    Color? backgroundColor,
    Color? borderColor,
    double? borderRadius,
    double? chatTopBorderRadius,
    EdgeInsets? messageInputPadding,
    EdgeInsets? listPadding,
  }) {
    if (selectedChat != null) {
      return ChatWindow(
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        borderRadius: borderRadius,
        topBorderRadius: chatTopBorderRadius,
        messageInputPadding: messageInputPadding,
        isExpanded: true
      );
    }
    switch (active) {
      case 0:
        return ChatList(
          borderRadius: borderRadius,
          borderColor: borderColor,
          padding: listPadding,
          isExpanded: true
        );
      case 1:
        return FriendList(
          borderRadius: borderRadius,
          borderColor: borderColor,
          padding: listPadding,
          isExpanded: true
        );
      case 2:
      default:
        switch (activeSettings) {
          case 1:
            return SettingsWindow(
              backgroundColor: backgroundColor,
              borderColor: borderColor,
              borderRadius: borderRadius,
              textInputColor: context.colors.background,
              isExpanded: true
            );
          case 2:
            return SettingsWindow(
              backgroundColor: backgroundColor,
              borderColor: borderColor,
              borderRadius: borderRadius,
              textInputColor: context.colors.background,
              isExpanded: true
            );
          case 3:
            return SettingsWindow(
              backgroundColor: backgroundColor,
              borderColor: borderColor,
              borderRadius: borderRadius,
              textInputColor: context.colors.background,
              isExpanded: true
            );
          default:
            return SettingsList(
              borderRadius: borderRadius,
              borderColor: borderColor,
              padding: listPadding,
              isExpanded: true
            );
        }
    }
  }
}
