import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sochat_client/context/notifications/inapp_notifications_manager.dart';
import 'package:sochat_client/extenstions/desktop_window_listener.dart';
import 'package:sochat_client/extenstions/no_transitions.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/modules/common/local_storage_service.dart';
import 'package:sochat_client/modules/media/media_service.dart';
import 'package:sochat_client/modules/media_capture/capture_service.dart';
import 'package:sochat_client/so_ui/notifications/so_notification.dart';
import 'package:sochat_client/so_ui/chatscreen/chat_screen.dart';
import 'package:sochat_client/so_ui/notifications/notifications_overlay.dart';
import 'package:sochat_client/so_ui/loginscreen/login_screen.dart';
import 'package:sochat_client/so_ui/themes/colors.dart';
import 'package:sochat_client/so_ui/themes/dark/dark_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/so_ui/themes/light/light_theme.dart';
import 'package:sochat_client/so_ux/settings_controller.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';

import 'modules/keys/key_service.dart';
import 'modules/notifications/notifications_service.dart';
import 'modules/websocket/web_socket_service.dart';

final containerHolder = ValueNotifier<ProviderContainer>(ProviderContainer());

void main() async {

  WidgetsFlutterBinding.ensureInitialized();



  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    windowManager.setPreventClose(true);

    windowManager.waitUntilReadyToShow().then((_) async {
      windowManager.show();
    });

    windowManager.addListener(DesktopWindowListener());

    await trayManager.setIcon(
      Platform.isWindows ? 'assets/icons/tray_icon.ico' : 'assets/icons/tray_icon.png',
    );
    await trayManager.setToolTip('SoChat');

    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show',
          label: 'Show',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit',
          label: 'Quit SoChat',
        ),
      ],
    );

    await trayManager.setContextMenu(menu);

    //WindowManager.instance.setMinimumSize(const Size(850, 600));
  }

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);



  runApp(
    ValueListenableBuilder(
      valueListenable: containerHolder,
      builder: (context, container, _) {
        container.read(notificationsProvider);
        return UncontrolledProviderScope(
          container: container,
          child: const SoChat(),
        );
      },
    ),
  );
  /*
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await windowManager.ensureInitialized();

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      WindowManager.instance.setMinimumSize(const Size(850, 600));
    }



    FlutterError.onError = (details) {
      FlutterError.presentError(details);

      containerHolder.value
          .read(notificationsManagerProvider.notifier)
          .addUpdate(
        SoNotification(
          icon: Icons.error_outline,
          title: details.exception.toString(),
          content: details.stack.toString(),
        ),
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      containerHolder.value
          .read(notificationsManagerProvider.notifier)
          .addError(
        error.toString(),
        stack.toString(),
      );

      return true;
    };

    runApp(
      ValueListenableBuilder(
        valueListenable: containerHolder,
        builder: (context, container, _) {
          return UncontrolledProviderScope(
            container: container,
            child: const SoChat(),
          );
        },
      ),
    );
  }, (error, stack) {
    containerHolder.value
        .read(notificationsManagerProvider.notifier)
        .addError(
      error.toString(),
      stack.toString(),
    );
  });*/

}


class SoChat extends ConsumerWidget {
  const SoChat({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(settingsControllerProvider.notifier).getTheme(ref.watch(selectedThemeProvider))
        .whereType<AppColors>()
        .first;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: true,
      ),
        child: Container(
          color: colors.surface,
          child: SafeArea(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                return Stack(
                  children: [
                    child!,
                    NotificationsOverlay(),
                  ],
                );
              },
              theme: ThemeData(
                extensions: ref.watch(settingsControllerProvider.notifier).getTheme(ref.watch(selectedThemeProvider)),
                useMaterial3: false,
                fontFamily: 'Inter',

                primaryColor: colors.primary,
                primaryColorDark: colors.primary,
                primaryColorLight: colors.primary,

                hoverColor: colors.contrastColor.withOpacity(0.05),
                splashFactory: NoSplash.splashFactory,
                highlightColor: colors.contrastColor.withOpacity(0.10),

                colorScheme: ColorScheme.light(
                  primary: colors.primary,
                ),

                textTheme: TextTheme(
                    titleLarge: TextStyle(
                        fontSize: 18,
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                    ),

                    bodyLarge: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: colors.textPrimary,
                    ),

                    labelLarge: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: colors.textSecondary,
                    ),

                    titleMedium: TextStyle(
                        fontSize: 15,
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                    ),

                    bodyMedium: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: colors.textPrimary,
                    ),

                    labelMedium: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: colors.textSecondary,
                    ),

                    titleSmall: TextStyle(
                        fontSize: 12,
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,

                    ),

                    bodySmall: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: colors.textPrimary,
                    ),

                    labelSmall: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: colors.textSecondary,
                      letterSpacing: 0.1,
                    )
                ),

                pageTransitionsTheme: PageTransitionsTheme(
                  builders: {
                    TargetPlatform.android: const NoTransitionsBuilder(),
                    TargetPlatform.iOS: const NoTransitionsBuilder(),
                    TargetPlatform.fuchsia: const NoTransitionsBuilder(),
                    TargetPlatform.linux: const NoTransitionsBuilder(),
                    TargetPlatform.macOS: const NoTransitionsBuilder(),
                    TargetPlatform.windows: const NoTransitionsBuilder(),
                  },
                ),

                iconTheme: IconThemeData(
                  color: colors.textPrimary,
                  size: 24,
                ),

                appBarTheme: AppBarTheme(
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                scaffoldBackgroundColor: colors.background,



                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: colors.foreground,
                    shadowColor: Colors.transparent,
                    alignment: Alignment.center,
                    padding: EdgeInsets.zero,
                  ),
                ),

                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              title: 'SoChat',
              home: const SoDesignPage(title: 'SoChat'),
              themeMode: null,
            ),
          ),
        ),
    );
  }
}

class SoDesignPage extends ConsumerStatefulWidget {
  const SoDesignPage({super.key, required this.title});
  final String title;


  @override
  ConsumerState<SoDesignPage> createState() => _SoDesignPageState();
}

class _SoDesignPageState extends ConsumerState<SoDesignPage> with TrayListener {

  late final InAppNotificationsManager notificationsManager;
  late final LocalStorageService localStorageService;
  late final KeyService keyService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationManager =
      notificationsManager = ref.read(inAppNotificationsManagerProvider.notifier);
      trayManager.addListener(this);
    });

    ref.read(selectedProfileProvider);
    ref.read(selectedServerProvider);
    ref.read(keyServiceProvider);
    ref.read(keyServiceProvider.notifier);

    keyService = ref.read(keyServiceProvider.notifier);


    localStorageService = ref.read(localStorageServiceProvider.notifier);
    loadSettings();

    if (!kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
    }

  }

  void loadSettings() async {
    if (await localStorageService.checkForContainingSettings()){
      localStorageService.loadSettings();
    }
    else {
      Future.microtask(() {
        keyService.generateProfile();
        keyService.addServer("localhost", "http://localhost:8081");
      });
    }
  }

  @override
  void onTrayIconRightMouseDown() async {
    await trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconMouseDown() async {
    await windowManager.show();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'show') {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setSkipTaskbar(false);
    } else if (menuItem.key == 'exit') {
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {

    final mediaService = ref.watch(mediaServiceProvider);
    final captureService = ref.watch(mediaCaptureServiceProvider);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            TextButton(onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => LoginScreen()));
            },
                child: Text("Login")),
            TextButton(onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ChatScreen()));
            }, child: Text("Chat (CAUTION: DO NOT USE), it will crash app")),
            TextButton(onPressed: () {
              notificationsManager.addUpdate(SoNotification(title: "youi", content: "nananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananananana", icon: Icons.error_outline));
            }, child: Text("Notification test")),

            TextButton(onPressed: () async {
              final devices = await captureService.getTrueDeviceList();
              for (var device in devices) {
                print('${device.kind}: ${device.label} (ID: ${device.deviceId})');
              }
            }, child: Text("Test Media List output")),

          ],
        ),
      ),
    );
  }
}
