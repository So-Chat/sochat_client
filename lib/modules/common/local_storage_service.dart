import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sochat_client/modules/common/auth_service.dart';
import 'package:sochat_client/modules/keys/key_service.dart';
import 'package:sochat_client/so_ui/themes/theme_type.dart';
import 'package:sochat_client/so_ux/settings_controller.dart';

final localStorageServiceProvider = StateNotifierProvider<LocalStorageService, LocalStorageServiceState>((ref) {
  return LocalStorageService(ref.read(keyServiceProvider.notifier), ref);
});

class LocalStorageServiceState {}

class LocalStorageService extends StateNotifier<LocalStorageServiceState>{
  LocalStorageService(this._keyService, this._ref) : super(LocalStorageServiceState());

  final KeyService _keyService;
  final Ref _ref;

  final storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  // Settings:
  // selected_server = 0,
  // selected_profile = 0,
  // {servers: [{"server1":{"ip":"localhost:8081"}}], selectedServerIndex = 0}
  // {profiles: [{"profile1":{"ed25519publicKey":"WE6YkhFUBrteC+3Z5kXQ98HbR+OxDZEoglpDnGe58i4=","ed25519privateKey":"fPIX2aL/xfu3rDDV0FnVgvpPCiIjaJZ5C5UvTB+LjJk="}}], selectedProfileIndex = 0}
  // Theme: {"Light"/"Dark"}

  // Session:
  // selected_server
  // selected_profile
  // token

  String buildSettingsJSON(){
    List<dynamic> profiles = _keyService.profiles.keys.map((profileName) {
      int index = _keyService.profiles.keys.toList().indexOf(profileName);
      return jsonDecode(_keyService.profileToJson(index));
    }).toList();

    List<dynamic> servers = _keyService.servers.keys.map((serverName) {
      int index = _keyService.servers.keys.toList().indexOf(serverName);
      return jsonDecode(_keyService.serverToJson(index));
    }).toList();

    final data = {
      "servers": servers,
      "profiles": profiles,
      "selected_server": _ref.read(selectedServerProvider),
      "selected_profile": _ref.read(selectedProfileProvider),
      "theme": _ref.read(selectedThemeProvider).name
    };
    return jsonEncode(data);
  }

  // Loading settings
  Future<void> loadSettings() async {
    if (kDebugMode) return;

    String? data = await storage.read(key: "settings");
    print("loaded data: $data");
    if (data != null) {
      final mapData = jsonDecode(data);
      final selectedServer = mapData["selected_server"];
      final selectedProfile = mapData["selected_profile"];
      final serverMap = mapData["servers"];
      final profileMap = mapData["profiles"];
      final currentTheme = mapData["theme"];

      _ref.read(selectedProfileProvider.notifier).state = selectedProfile;
      _ref.read(selectedServerProvider.notifier).state = selectedServer;

      for (final server in serverMap) {
        _ref.read(keyServiceProvider.notifier).parseServers(jsonEncode(server));
      }

      for (final profile in profileMap) {
        _ref.read(keyServiceProvider.notifier).parseProfiles(jsonEncode(profile));
      }

      _ref.read(selectedThemeProvider.notifier).state = ThemeType.values.byName(currentTheme);
    }
    else {
      throw Exception("Settings returned null");
    }
  }

  // Saving Theme, Profiles and Servers with selected profiles and servers
  Future<void> saveSettings() async {
    if (kDebugMode) return;
    await storage.write(key: "settings", value: buildSettingsJSON());
  }

  Future<void> saveSession() async {
    if (kDebugMode) return;
    final data = {
      "token": _ref.read(authServiceProvider).token,
      "selected_server": _ref.read(selectedServerProvider),
      "selected_profile": _ref.read(selectedProfileProvider),
    };
    await storage.write(key: "session", value: jsonEncode(data));
  }

  Future<String> getSessionAndSetSelectedKeys() async {
    if (kDebugMode) return "NO";

    final data = await storage.read(key: "session");
    if (data != null) {
      final decodedData = jsonDecode(data);
      _ref.read(selectedServerProvider.notifier).state = decodedData["selected_server"];
      _ref.read(selectedProfileProvider.notifier).state = decodedData["selected_profile"];
      return decodedData["token"];
    }
    else {
      throw Exception("Session returned null");
    }
  }


  Future<bool> checkForContainingSettings() async {
    if (kDebugMode) return false;
    final result = await storage.containsKey(key: "settings");
    return result;
  }

  Future<bool> checkForContainingSession() async {
    if (kDebugMode) return false;
    final result = await storage.containsKey(key: "session");
    return result;
  }

  Future<void> removeSession() async {
    if (kDebugMode) return;
    await storage.delete(key: "session");
  }

  Future<void> purgeData() async {
    await storage.deleteAll();
  }
}