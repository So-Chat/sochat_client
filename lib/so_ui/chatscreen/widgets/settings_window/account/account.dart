import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/modules/common/auth_service.dart';
import 'package:sochat_client/modules/users/user.dart';
import 'package:sochat_client/modules/users/user_service.dart';
import 'package:sochat_client/so_ui/common/input.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';
import 'package:sochat_client/so_ux/settings_controller.dart';

class Account extends ConsumerStatefulWidget {

  const Account({super.key, this.textInputColor});

  final Color? textInputColor;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => AccountState();
}

class AccountState extends ConsumerState<Account> {

  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool isChanged = false;

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(currentUserProvider);
    nicknameController.text = currentUser?.nickname ?? "";
    usernameController.text = currentUser?.username ?? "";
    descriptionController.text = currentUser?.description ?? "";
  }

  void checkChange(){
    final currentUser = ref.read(currentUserProvider);
    setState(() {
      isChanged = (currentUser!.nickname != nicknameController.text) ||
          (currentUser.username != usernameController.text) ||
          (currentUser.description != descriptionController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = ref.read(settingsControllerProvider.notifier);
    final authService = ref.watch(authServiceProvider);
    final userService = ref.watch(userServiceProvider.notifier);
    final currentUser = ref.watch(currentUserProvider);

    ref.listen<User?>(currentUserProvider, (prev, next) {
      if (!mounted || next == null) return;
      nicknameController.text = next.nickname ?? "";
      usernameController.text = next.username;
      descriptionController.text = next.description ?? "";
      setState(() {
        isChanged = false;
      });
    });

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    width: 300,
                    child: Column(
                      spacing: 8,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          spacing: 4,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "Nickname",style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: context.colors.textSecondary,
                            )),
                            SoCommonInput(
                              color: widget.textInputColor ?? context.colors.surface,
                              textStyle: Theme.of(context).textTheme.bodyMedium,
                              decoration: InputDecoration(hintText: "Nickname",
                                hintStyle: Theme.of(context).textTheme.labelMedium,
                                border: const OutlineInputBorder(borderSide: BorderSide.none),
                              ),
                              textEditingController: nicknameController,
                              onChanged: (text) {checkChange();},
                            ),
                          ],
                        ),

                        Column(
                          spacing: 4,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "Username",style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: context.colors.textSecondary,
                            )),
                            SoCommonInput(
                              color: widget.textInputColor ?? context.colors.surface,
                              textStyle: Theme.of(context).textTheme.bodyMedium,
                              decoration: InputDecoration(hintText: "Username",
                                hintStyle: Theme.of(context).textTheme.labelMedium,
                                border: const OutlineInputBorder(borderSide: BorderSide.none),
                              ),
                              textEditingController: usernameController,
                              onChanged: (text) {checkChange();},
                            ),
                          ],
                        ),

                        Column(
                          spacing: 4,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "Description",style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: context.colors.textSecondary,
                            )),
                            SoCommonInput(
                              height: 200,
                              color: widget.textInputColor ?? context.colors.surface,
                              maxLines: null,
                              textStyle: Theme.of(context).textTheme.bodyMedium,
                              decoration: InputDecoration(hintText: "Type something like \"I love drinking coke\"",
                                hintStyle: Theme.of(context).textTheme.labelMedium,
                                hintMaxLines: null,
                                border: const OutlineInputBorder(borderSide: BorderSide.none),
                              ),
                              textEditingController: descriptionController,
                              onChanged: (text) {checkChange();},
                            ),
                          ],
                        ),
                        SoButton(height: 35, width: 300, color: context.colors.primary, onPressed: () {}, child: Text("Preview Profile", style:
                        Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Colors.white,
                        ))),
                        SoButton(height: 35, width: 300, color: context.colors.critical, onPressed: () {}, child: Text("Delete Account", style:
                        Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Colors.white,
                        ))),
                        SizedBox(height: 20,),

                        if (isChanged) Row(
                          children: [
                            SoButton(height: 35, width: 150, color: context.colors.critical, onPressed: () {
                              usernameController.text = currentUser!.username;
                              nicknameController.text = currentUser.nickname;
                              descriptionController.text = currentUser.description!;
                            }, child: Text("Discard", style:
                            Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: Colors.white,
                            ))),
                            SoButton(height: 35, width: 150, color: context.colors.surface, onPressed: () {
                              userService.changeProfile(nicknameController.text, usernameController.text, descriptionController.text);
                              checkChange();
                            }, child: Text("Save", style:
                            Theme.of(context).textTheme.bodySmall!.copyWith(
                            ))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}