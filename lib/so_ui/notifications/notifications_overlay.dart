import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/context/notifications/inapp_notifications_manager.dart';

class NotificationsOverlay extends ConsumerStatefulWidget {
  const NotificationsOverlay({super.key});

  @override
  ConsumerState<NotificationsOverlay> createState() => _NotificationsOverlayState();
}
class _NotificationsOverlayState extends ConsumerState<NotificationsOverlay> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: Consumer(
        builder: (context, ref, _) {
          final notifications =
          ref.watch(inAppNotificationsManagerProvider);

          return Stack(
            children: [
              Positioned(
                right: 10,
                bottom: 10,
                child: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: 300,
                    child: ListView.separated(
                      reverse: true,
                      shrinkWrap: true,
                      itemCount: notifications.notificationList.length,
                      separatorBuilder: (_, _) =>
                      const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final n =
                        notifications.notificationList[index];

                        return IgnorePointer(
                          ignoring: false,
                          child: n
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}