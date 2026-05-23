import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/modules/common/local_storage_service.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';
import 'package:sochat_client/so_ui/loginscreen/widgets/keys/keys_list.dart';
import 'package:sochat_client/so_ui/loginscreen/widgets/keys/server_list.dart';

import 'login_screen.dart';

final selectedSettingProvider = StateProvider<int>((ref) => 0);

class KeySettings extends ConsumerWidget {
  const KeySettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSetting = ref.watch(selectedSettingProvider);
    final isNarrowDevice = (Platform.isFuchsia ||
        Platform.isIOS ||
        Platform.isAndroid ||
        MediaQuery.sizeOf(context).width <= 800);

    print(isNarrowDevice);
    return Column(
      spacing: 8,
      children: [
        Row(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (isNarrowDevice)
              Expanded(
                child: Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: SoButton(
                        height: 43,
                        borderColor: context.colors.outline,
                        color: selectedSetting != 0 ? null : context.colors.primary,
                        onPressed: () {
                          ref.read(selectedSettingProvider.notifier).state = 0;
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [Icon(Icons.web), Text("Servers")],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SoButton(
                        height: 43,
                        borderColor: context.colors.outline,
                        color: selectedSetting != 1 ? null : context.colors.primary,
                        onPressed: () {
                          ref.read(selectedSettingProvider.notifier).state = 1;
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [Icon(Icons.key), Text("Profiles")],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SoButton(
              borderColor: context.colors.outline,
              width: 43,
              height: 43,
              onPressed: () {
                ref.read(localStorageServiceProvider.notifier).saveSettings();
                ref.read(settingsToggle.notifier).state =
                !ref.read(settingsToggle);
              },
              child: Icon(Icons.arrow_back_outlined),
            ),
          ],
        ),

        buildLoginSettingsLists(selectedSetting, isNarrowDevice),
      ],
    );
  }

  Widget buildLoginSettingsLists(int selectedSetting, bool isNarrowDevice) {
    if (!isNarrowDevice) {
      return Expanded(
        child: Row(
          spacing: 8,
          children: [ServerList(), KeysList()],
        ),
      );
    }

    switch (selectedSetting) {
      case 0:
        return ServerList();
      case 1:
        return KeysList();
      default:
        return ServerList();
    }
  }
}