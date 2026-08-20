
import 'package:flutter/material.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';
import 'package:sochat_client/so_ux/chat_controller.dart';

class InputField extends ConsumerWidget {
  const InputField(this.messageInputController, this.textFieldFocusNode, {super.key});

  final TextEditingController messageInputController;
  final FocusNode textFieldFocusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatController = ref.watch(chatControllerProvider.notifier);

    final chatControllerState = ref.watch(chatControllerProvider);
    final selectedFiles = chatControllerState.selectedMedia;
    final selectedChat = chatControllerState.selectedChat;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.colors.outline,
            width: 1,
          ),
          left: BorderSide.none,
          right: BorderSide.none,
          bottom: BorderSide.none,
        ),
        color: context.colors.foreground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          if (selectedChat!.editMessage != null)
            ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 40),
                child: SoButton(
                  onPressed: () {
                    chatController.stopEditing();
                  },
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Text("Edit message: ", textAlign: .left, style: Theme.of(context).textTheme.labelMedium),
                            Text(selectedChat.editMessage!.content, textAlign: .left)
                          ],
                        ),
                      ),
                    ],
                  ),
                )
            ),
          if (selectedFiles.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 100),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: selectedFiles.length,
                itemBuilder: (context, index) {
                  return SoButton(
                      onPressed: () {
                        chatController.deleteMedia(selectedFiles[index]);
                        final newList = [...selectedFiles];
                        newList.removeAt(index);
                        chatController.setSelectedChat(newList);
                        },
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(selectedFiles[index].file!.uri.pathSegments.last, textAlign: .left),
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),
          Row(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 4),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Material(
                    clipBehavior: Clip.hardEdge,
                    borderRadius: BorderRadius.circular(10),
                    color: context.colors.foreground,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        await chatController.requestMedia();
                      },
                      child: Icon(Icons.attach_file),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: 180
                  ),

                  child: TextField(
                    autofocus: true,
                    focusNode: textFieldFocusNode,
                    keyboardType: TextInputType.multiline,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: null,
                    controller: messageInputController,
                    minLines: 1,
                    decoration: InputDecoration(hintText: "Type message here",
                      hintStyle: Theme.of(context).textTheme.labelMedium,
                      border: const OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Material(
                        clipBehavior: Clip.hardEdge,
                        borderRadius: BorderRadius.circular(10),
                        color: context.colors.foreground,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {},
                          child: Icon(Icons.emoji_emotions_outlined),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Material(
                        clipBehavior: Clip.hardEdge,
                        borderRadius: BorderRadius.circular(10),
                        color: context.colors.foreground,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            if (selectedChat.editMessage == null) {
                              await chatController.sendMessage(messageInputController.text);
                              messageInputController.text = "";
                            } else {
                              final text = messageInputController.text;
                              final editing = selectedChat.editMessage;

                              await chatController.editMessage(text, editing!.id);

                              messageInputController.clear();
                              chatController.stopEditing();
                            }
                            },
                          child: selectedChat.editMessage == null ? Icon(Icons.send_sharp) : Icon(Icons.check),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
