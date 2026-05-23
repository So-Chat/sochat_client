import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/modules/calls/call_service.dart';
import 'package:sochat_client/modules/chats/chat_type.dart';
import 'package:sochat_client/modules/common/auth_service.dart';
import 'package:sochat_client/so_ui/chatscreen/widgets/chat_window/calls/user_in_call.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';

import '../../../../../so_ux/chat_controller.dart';

class CallWindow extends ConsumerStatefulWidget {
  const CallWindow({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => CallWindowState();
}

class CallWindowState extends ConsumerState<CallWindow> {

  @override
  void initState(){
    super.initState();
    final selectedChat = ref.read(selectedChatProvider);
    final currentUser = ref.read(currentUserProvider);

    final callService = ref.read(callServiceProvider.future);

    callService.then((service) {
      if (selectedChat!.type == ChatType.PRIVATE) {
        print("starting call");
        service.startCall(selectedChat.participants.firstWhere((p) => p.user.id != currentUser!.id).user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    final selectedChat = ref.watch(selectedChatProvider);

    return Expanded(
      flex: 2,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: context.colors.outline,
            width: 1.0,
          ),
          color: Colors.black,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            spacing: 8,
            children: [
              Row(
                spacing: 10,
                children: [
                  SoButton(height: 30, width: 30,  color: Colors.transparent, onPressed: () {ref.read(isInCallProvider.notifier).state = false;},
                    child: Icon(Icons.arrow_back, color: context.colors.textPrimary, size: 25),),
                  CircleAvatar(radius: 20, child: Text("S")),
                  Text("silver")
                ],
              ),
              Expanded(
                flex: 5,
                child: Row(
                  spacing: 8,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    UserInCall(userId: 1),
                    UserInCall(userId: 1)
                  ],
                ),
              ),

              Flexible(
                flex: 1,
                child: Row(
                  spacing: 8,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    SoButton(height: 50, width: 50,  color: context.colors.surface, onPressed: () {}, child: Icon(Icons.screen_share_outlined, color: context.colors.textPrimary, size: 25),),
                    SoButton(height: 50, width: 50,  color: context.colors.surface, onPressed: () {}, child: Icon(Icons.videocam_rounded, color: context.colors.textPrimary, size: 25),),
                    SoButton(height: 50, width: 50,  color: context.colors.surface, onPressed: () {}, child: Icon(Icons.mic, color: context.colors.textPrimary, size: 25),),
                    SoButton(height: 50, width: 50,  color: context.colors.critical, onPressed: () {}, child: Icon(Icons.call_end, color: context.colors.textPrimary, size: 25),),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}