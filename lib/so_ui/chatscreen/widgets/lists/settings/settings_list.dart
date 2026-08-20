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
  final bool isExpanded;

  const SettingsList({
    super.key, this.borderColor, this.borderRadius, this.padding, this.isExpanded = false
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginController = ref.read(loginControllerProvider);

    return BasePanel(
      borderColor: borderColor,
      borderRadius: borderRadius ?? 10,
      backgroundColor: context.colors.surface,
      padding: padding ?? EdgeInsets.all(8),
      isExpanded: isExpanded,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              SettingsItem(title: "Account", trailing: Icon(Icons.person, size: 30,), onPressed: () { ref.read(settingsControllerProvider.notifier).setSelectedOption(1); }),
              SettingsItem(title: "Notifications", trailing: Icon(Icons.notifications, size: 30), onPressed: () { ref.read(settingsControllerProvider.notifier).setSelectedOption(2); }),
              SettingsItem(title: "Appearance", trailing: Icon(Icons.palette, size: 30), onPressed: () { ref.read(settingsControllerProvider.notifier).setSelectedOption(3); }),
              SettingsItem(title: "Multimedia", trailing: Icon(Icons.phone, size: 30), onPressed: () { ref.read(settingsControllerProvider.notifier).setSelectedOption(4); }),
            ],
          ),
          SettingsItem(title: "Log-out", trailing: Icon(Icons.logout, size: 30), onPressed: () { loginController.logout(context); }),
        ],
      ),
    );
  }
}
