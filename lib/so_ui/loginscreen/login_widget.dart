import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/modules/common/auth_service.dart';
import 'package:sochat_client/modules/common/local_storage_service.dart';
import 'package:sochat_client/modules/keys/key_service.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';
import 'package:sochat_client/so_ui/common/so_exception.dart';
import 'package:sochat_client/so_ui/loginscreen/login_screen.dart';
import 'package:sochat_client/so_ui/loginscreen/widgets/login_button.dart';
import 'package:sochat_client/so_ui/loginscreen/widgets/login_input.dart';
import 'package:sochat_client/so_ui/loginscreen/widgets/settings_button.dart';
import 'package:sochat_client/so_ux/login_controller.dart';
import 'package:sochat_client/so_ux/settings_controller.dart';

class LoginWidget extends ConsumerStatefulWidget {

  final TextEditingController usernameController;

  const LoginWidget({super.key, required this.usernameController});

  @override
  LoginPageWidget createState() => LoginPageWidget();
}

class LoginPageWidget extends ConsumerState<LoginWidget> {
    String errorText = "";
    void setError(String text){
      setState(() {
        errorText = text;
      });

    }

  @override
  Widget build(BuildContext context) {
    final authService = ref.read(authServiceProvider);
    final keyService = ref.read(keyServiceProvider);

    final loginController = ref.read(loginControllerProvider.notifier);

    return Padding(
      padding: EdgeInsetsGeometry.directional(top: 20, bottom: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 8,
        children: [
          Text("So"),
          Column(
            spacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoginInput(hintText: "Username", inputController: widget.usernameController, height: 52, onChanged: (text) {
                    setError("");
                  },),
                  Text(errorText,   style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: context.colors.critical,
                    fontWeight: FontWeight.bold,
                  ),),
                ],
              ),
              Row(
                spacing: 8,
                children: [
                  Expanded(child: LoginButton(text: "Login", color: context.colors.primary, onTap: () async {
                    setError("");
                    try {
                      await loginController.login(
                          context,
                          widget.usernameController.text,
                          ref.read(selectedProfileProvider),
                          ref.read(selectedServerProvider),
                          ref
                      );
                    } on SocketException catch (e) {
                      setError(e.message);
                    } on SoException catch (e) {
                      setError(e.cause);
                    } catch (e) {
                      setError("Unknown error: $e");
                    }
                  })),
                  SettingsButton(Icons.settings, size: 43, onPressed: () {ref.read(settingsToggle.notifier).state = !ref.read(settingsToggle);}),
                ],
              ),
              LoginButton(text: "Register", color: context.colors.positive, onTap: () {
                setError("");
                try {
                  loginController.register(context, widget.usernameController.text,
                      ref.read(selectedProfileProvider), ref.read(selectedServerProvider), ref);
                } on SocketException catch (e) {
                  setError(e.message);
                } on SoException catch (e) {
                  setError(e.cause);
                } catch (e) {
                  setError("Unknown error: $e");
                }
              }),
              if (kDebugMode) Column(
                children: [
                  Row(
                    children: [
                      LoginButton(text: "Kafka", color: context.colors.critical, onTap: () async {
                        widget.usernameController.text = "kafka";
                        ref.read(keyServiceProvider.notifier).parseProfiles('{"profile1":{"ed25519publicKey":"WE6YkhFUBrteC+3Z5kXQ98HbR+OxDZEoglpDnGe58i4=","ed25519privateKey":"fPIX2aL/xfu3rDDV0FnVgvpPCiIjaJZ5C5UvTB+LjJk="}}');
                        ref.read(selectedProfileProvider.notifier).state = keyService.profiles.length-1;
                        loginController.login(context, widget.usernameController.text,
                            ref.read(selectedProfileProvider), ref.read(selectedServerProvider), ref);

                      }),
                      LoginButton(text: "Silver", color: context.colors.critical, onTap: () {
                        widget.usernameController.text = "silver";
                        ref.read(keyServiceProvider.notifier).parseProfiles('{"profile2":{"ed25519publicKey":"rIO/d0h1lLIiy0oUNhReQncJku8+jN8cLNVN1594hbg=","ed25519privateKey":"n50jTg/3yw69h53e5Q5e1yuRsfcMUxN4YPXFSvE8fu0="}}');
                        ref.read(selectedProfileProvider.notifier).state = keyService.profiles.length - 1;
                        loginController.login(context, widget.usernameController.text,
                            ref.read(selectedProfileProvider), ref.read(selectedServerProvider), ref);
                      }),
                      LoginButton(text: "hero", color: context.colors.critical, onTap: () {
                        widget.usernameController.text = "hero";
                        ref.read(keyServiceProvider.notifier).parseProfiles('{"profile2":{"ed25519publicKey":"d7u94NKVtO7vk/llLvMw+sLkTprYE1fIcq6WoDcgTQ4=","ed25519privateKey":"kcVXn/UNBwz0GcnT5idmFkL60FobvugpB5exYDQh6d0="}}');
                        ref.read(selectedProfileProvider.notifier).state = keyService.profiles.length - 1;
                        loginController.login(context, widget.usernameController.text,
                            ref.read(selectedProfileProvider), ref.read(selectedServerProvider), ref);
                      }),
                      LoginButton(text: "Build", color: context.colors.textSecondary, onTap: () { ref.read(localStorageServiceProvider.notifier).buildSettingsJSON(); }),
                      LoginButton(text: "Save", color: context.colors.textSecondary, onTap: () { ref.read(localStorageServiceProvider.notifier).saveSettings(); }),
                      LoginButton(text: "Load", color: context.colors.textSecondary, onTap: () { ref.read(localStorageServiceProvider.notifier).loadSettings(); }),
                      LoginButton(text: "Purge", color: context.colors.textSecondary, onTap: () { ref.read(localStorageServiceProvider.notifier).purgeData(); }),
                    ],
                  ),
                  SoButton(color: context.colors.textSecondary, onPressed: () { ref.read(settingsControllerProvider.notifier).changeTheme(); }, child:Text("Theme")),
                ],
              ),

              
            ],
          )
        ],
      ),
    );
  }
}