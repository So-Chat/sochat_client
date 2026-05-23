import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sochat_client/so_ui/chatscreen/widgets/chat_window/calls/call_window.dart';
import 'package:sochat_client/so_ui/chatscreen/widgets/chat_window/message_list.dart';
import 'package:sochat_client/so_ui/chatscreen/widgets/chat_window/chat_top.dart';
import 'package:sochat_client/so_ui/chatscreen/widgets/chat_window/input_field.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/so_ui/common/base_panel.dart';
import 'package:sochat_client/so_ux/chat_controller.dart';

class ChatWindow extends ConsumerStatefulWidget {
  const ChatWindow({super.key,
    this.backgroundColor,
    this.topBorderRadius = 10,
    this.borderRadius = 10,
    this.messageInputPadding = const EdgeInsets.all(0),
    this.borderColor,
  });

  final Color? borderColor;
  final Color? backgroundColor;
  final double? topBorderRadius;
  final double? borderRadius;
  final EdgeInsets? messageInputPadding;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => ChatWindowState();
}

class ChatWindowState extends ConsumerState<ChatWindow>{

  final TextEditingController messageInputController = TextEditingController();
  late final FocusNode textFieldFocusNode;

  @override
  void initState(){
    super.initState();
    final chatController = ref.read(chatControllerProvider.notifier);

    textFieldFocusNode = FocusNode(
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          final shiftPressed = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
              HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftRight);

          if (event.logicalKey == LogicalKeyboardKey.enter) {
            if (shiftPressed) {
              return KeyEventResult.ignored;
            } else {
              if (messageInputController.text.trim().isEmpty || messageInputController.text.trim() == "" || messageInputController.text.trim() == " ") KeyEventResult.ignored;
              chatController.sendMessage(messageInputController.text.trim());
              messageInputController.clear();

              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
    );
    textFieldFocusNode.requestFocus();
  }


  @override
  Widget build(BuildContext context) {
    final selectedChat = ref.watch(selectedChatProvider);
    final isInCall = ref.watch(isInCallProvider);
    final chatController = ref.read(chatControllerProvider.notifier);

    final FocusNode chatFocusNode = FocusNode(
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape && selectedChat != null) {
              ref.read(selectedChatProvider.notifier).state = null;
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        }
    );

    return BasePanel(
      flex: 2,
      borderRadius: widget.borderRadius!,
      borderColor: widget.borderColor,
      backgroundColor: widget.backgroundColor ?? context.colors.foreground,
      child: Focus(
        focusNode: chatFocusNode,
        child: selectedChat != null
            ? (isInCall
            ? Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CallWindow(),
          ],
        )
            : Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChatTop(borderRadius: widget.topBorderRadius!),
            MessageList(textFieldFocusNode),
            Padding(
              padding: widget.messageInputPadding!,
              child: InputField(messageInputController, textFieldFocusNode),
            ),
          ],
        ))
            : const Center(),
      ),
    );
  }
}