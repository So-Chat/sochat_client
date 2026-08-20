import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';
import 'package:sochat_client/so_ux/settings_controller.dart';

class Appearance extends ConsumerWidget {

  const Appearance({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsController = ref.read(settingsControllerProvider.notifier);

    return Column(
      children: [
        SoButton(
          onPressed: () {

            settingsController.changeTheme();
          },
          height: 80, width: 100,
          child: Text("Change theme"),
        ),
      ],
    );
  }
}
