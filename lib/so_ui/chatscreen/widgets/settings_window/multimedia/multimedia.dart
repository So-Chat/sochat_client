import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';
import 'package:sochat_client/so_ui/common/so_dropdownbutton.dart';
import 'package:sochat_client/so_ux/settings_controller.dart';

class MultimediaSettings extends ConsumerWidget {

  const MultimediaSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          SoDropdownButton(
            menuEntries: <DropdownMenuItem<dynamic>>[
              DropdownMenuItem<dynamic>(value: 1, child: Text("ж")),
              DropdownMenuItem<dynamic>(value: 2, child: Text("м")),
            ],
            onSelected: (changed) {},
          )
        ],
      ),
    );
  }
}