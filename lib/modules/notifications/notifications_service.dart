import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  final asyncPlugin = ref.watch(notificationsProvider);

  return asyncPlugin.whenData((plugin) => NotificationsService(plugin)).requireValue;
});

final notificationsProvider = FutureProvider<FlutterLocalNotificationsPlugin>((ref) async {
  final plugin = FlutterLocalNotificationsPlugin();

  const androidSettings = AndroidInitializationSettings('app_icon');
  const darwinSettings = DarwinInitializationSettings();
  const linuxSettings =
  LinuxInitializationSettings(defaultActionName: 'Open notification');

  const windowsSettings = WindowsInitializationSettings(
    appName: 'SoChat',
    appUserModelId: 'com.yomirein.sochat',
    guid: 'ba2e3097-82e8-44ef-b094-02e3f5255817',
  );

  const settings = InitializationSettings(
    android: androidSettings,
    iOS: darwinSettings,
    macOS: darwinSettings,
    linux: linuxSettings,
    windows: windowsSettings,
  );

  await plugin.initialize(
    onDidReceiveNotificationResponse: (response) {
      print('payload: ${response.payload}');
    }, settings: settings,
  );

  return plugin;
});

class NotificationsService {
  final FlutterLocalNotificationsPlugin plugin;

  NotificationsService(this.plugin);

  Future<void> show(int id, String title, String body) async {
    await plugin.show(id: id,  title: title,body:  body);
  }
}