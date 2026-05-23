
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sochat_client/modules/common/local_storage_service.dart';
import 'package:sochat_client/so_ui/themes/dark/dark_theme.dart';
import 'package:sochat_client/so_ui/themes/light/light_theme.dart';
import 'package:sochat_client/so_ui/themes/theme_type.dart';

final settingsControllerProvider = StateNotifierProvider<SettingsController, SettingsControllerState>((ref) {
  return SettingsController(ref);
});

final selectedSettingsOptionProvider = StateProvider<int>((ref) => 1);
final selectedThemeProvider = StateProvider<ThemeType>(
        (ref) => ThemeType.dark);

class SettingsControllerState {
}

class SettingsController extends StateNotifier<SettingsControllerState> {
  Ref ref;

  SettingsController(this.ref) : super(SettingsControllerState());

  List<ThemeExtension<dynamic>> getTheme(ThemeType theme) {
    switch (theme) {
      case ThemeType.light:
        return LightTheme.extensions;
      case ThemeType.dark:
        return DarkTheme.extensions;
      case ThemeType.custom:
        return DarkTheme.extensions;
    }
  }

  void changeTheme(){
    if (ref.read(selectedThemeProvider) == ThemeType.dark){
      ref.read(selectedThemeProvider.notifier).state = ThemeType.light;
      ref.read(localStorageServiceProvider.notifier).saveSettings();
      return;
    }
    ref.read(selectedThemeProvider.notifier).state = ThemeType.dark;
    ref.read(localStorageServiceProvider.notifier).saveSettings();
  }
}