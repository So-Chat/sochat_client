import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/so_ui/chatscreen/widgets/settings_window/account/account.dart';
import 'package:sochat_client/so_ui/chatscreen/widgets/settings_window/appearance/appearance.dart';
import 'package:sochat_client/so_ui/chatscreen/widgets/settings_window/multimedia/multimedia.dart';
import 'package:sochat_client/so_ui/common/base_panel.dart';
import 'package:sochat_client/so_ux/settings_controller.dart';

class SettingsWindow extends ConsumerStatefulWidget {

  const SettingsWindow({
    super.key,
    this.backgroundColor,
    this.borderRadius = 10,
    this.textInputColor,
    this.borderColor,
    this.isExpanded = false
  });

  final Color? borderColor;
  final Color? backgroundColor;
  final Color? textInputColor;
  final double? borderRadius;
  final bool isExpanded;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => SettingsWindowState();
}

class SettingsWindowState extends ConsumerState<SettingsWindow>{
  @override
  void initState(){
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final selectedOption = ref.watch(settingsControllerProvider).selectedOption;
    final settingsController = ref.read(settingsControllerProvider.notifier);

    return BasePanel(
        borderRadius: widget.borderRadius!,
        borderColor: widget.borderColor,
        backgroundColor: widget.backgroundColor ?? context.colors.foreground,
        isExpanded: widget.isExpanded,
        child: _buildOptions(selectedOption, settingsController),
    );


  }

  Widget _buildOptions(int selectedOption, SettingsController settingsController) {
    switch (selectedOption) {
      case 1:
        return Account(textInputColor: widget.textInputColor,);
      case 2:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Text("In future"),
          ],
        );
      case 3:
        return Appearance();
      case 4:
        return MultimediaSettings();
      default:
        return Container();
    }
  }


}
