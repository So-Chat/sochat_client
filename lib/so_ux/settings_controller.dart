import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/modules/common/local_storage_service.dart';
import 'package:sochat_client/so_ui/themes/dark/dark_theme.dart';
import 'package:sochat_client/so_ui/themes/light/light_theme.dart';
import 'package:sochat_client/so_ui/themes/theme_type.dart';

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);

class SettingsState {
  final int selectedOption;
  final ThemeType selectedTheme;

  final bool settingsToggle;
  final int selectedSetting;

  const SettingsState({
    this.selectedOption = 1,
    this.selectedTheme = ThemeType.dark,
    this.settingsToggle = false,
    this.selectedSetting = 0,
  });

  SettingsState copyWith({
    int? selectedOption,
    ThemeType? selectedTheme,
    bool? settingsToggle,
    int? selectedSetting,
  }) {
    return SettingsState(
      selectedOption: selectedOption ?? this.selectedOption,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      settingsToggle: settingsToggle ?? this.settingsToggle,
      selectedSetting: selectedSetting ?? this.selectedSetting,
    );
  }
}

class SettingsController extends Notifier<SettingsState> {
  int? get selectedOption => state.selectedOption;
  ThemeType? get selectedTheme => state.selectedTheme;
  bool? get settingsToggle => state.settingsToggle;
  int? get selectedSetting => state.selectedSetting;

  @override
  SettingsState build() {
    return SettingsState();
  }

  void setSelectedOption(int option) {
    state = state.copyWith(selectedOption: option);
  }
  void setSelectedTheme(ThemeType theme) {
    state = state.copyWith(selectedTheme: theme);
  }
  void setSettingsToggle(bool toggle) {
    state = state.copyWith(settingsToggle: toggle);
  }
  void setSelectedSetting(int setting) {
    state = state.copyWith(selectedSetting: setting);
  }

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

  void changeTheme() {
    if (selectedTheme == ThemeType.dark) {
      setSelectedTheme(ThemeType.light);
      ref.read(localStorageServiceProvider).saveSettings();
      return;
    }
    setSelectedTheme(ThemeType.dark);
    ref.read(localStorageServiceProvider).saveSettings();
  }
}
