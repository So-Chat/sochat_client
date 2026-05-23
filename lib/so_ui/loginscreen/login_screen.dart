import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/modules/common/local_storage_service.dart';
import 'package:sochat_client/modules/keys/key_service.dart';
import 'package:sochat_client/so_ui/loginscreen/keysettings.dart';
import 'package:sochat_client/so_ui/loginscreen/login_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/so_ux/login_controller.dart';


final settingsToggle = StateProvider<bool>((ref) => false);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();

}

class _LoginScreenState extends ConsumerState<LoginScreen> {

  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final localStorageService = ref.read(localStorageServiceProvider.notifier);
    final loginController = ref.read(loginControllerProvider.notifier);

    if (await localStorageService.checkForContainingSession()) {
      loginController.authenticateWithActiveSession(context, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final toggle = ref.watch(settingsToggle);


    ref.watch(selectedProfileProvider);
    ref.watch(selectedServerProvider);
    ref.watch(keyServiceProvider);
    ref.watch(keyServiceProvider.notifier);

    return Scaffold(
      body: Padding(padding: EdgeInsets.all(16), child: Center(
        child: SizedBox(
          width: 550,
          height: 350,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: context.colors.outline,
                  width: 1.0,
                ),
                color: context.colors.surface
            ),
            padding: EdgeInsets.all(16),
            child: toggle ? KeySettings() : LoginWidget(usernameController: _usernameController,)
          ),
        ),
      ),
    ));
  }
}