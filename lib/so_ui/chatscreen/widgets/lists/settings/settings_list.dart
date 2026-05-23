import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/so_ui/chatscreen/widgets/lists/settings/settings_item.dart';
import 'package:sochat_client/so_ui/common/base_panel.dart';
import 'package:sochat_client/so_ux/login_controller.dart';
import 'package:sochat_client/so_ux/settings_controller.dart';

class SettingsList extends ConsumerWidget {

  final Color? borderColor;
  final double? borderRadius;
  final EdgeInsets? padding;

  const SettingsList({
    super.key, this.borderColor, this.borderRadius, this.padding
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginController = ref.read(loginControllerProvider.notifier);

    return BasePanel(
      flex: 1,
      borderColor: borderColor,
      borderRadius: borderRadius ?? 10,
      backgroundColor: context.colors.surface,
      padding: padding ?? EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              SettingsItem(title: "Account", trailing: Icon(Icons.person, size: 30,), onPressed: () { ref.read(selectedSettingsOptionProvider.notifier).state = 1; }),
              SettingsItem(title: "Notifications", trailing: Icon(Icons.notifications, size: 30), onPressed: () { ref.read(selectedSettingsOptionProvider.notifier).state = 2; }),
              SettingsItem(title: "Appearance", trailing: Icon(Icons.palette, size: 30), onPressed: () { ref.read(selectedSettingsOptionProvider.notifier).state = 3; }),
              SettingsItem(title: "Multimedia", trailing: Icon(Icons.phone, size: 30), onPressed: () { ref.read(selectedSettingsOptionProvider.notifier).state = 4; }),
            ],
          ),
          SettingsItem(title: "Log-out", trailing: Icon(Icons.logout, size: 30), onPressed: () { loginController.logout(context); }),
        ],
      ),
    );
  }
}