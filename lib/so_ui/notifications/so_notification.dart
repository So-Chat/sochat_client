import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';

import '../../context/notifications/inapp_notifications_manager.dart';

class SoNotification extends ConsumerWidget {
  String? title;
  String? content;
  IconData? icon;
  bool canCopy;

  SoNotification({super.key, this.title, this.content, this.icon, this.canCopy = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationManager = ref.watch(inAppNotificationsManagerProvider.notifier);

    return SoButton(
      width: 370,
      height: 125,
      borderColor: context.colors.outline,
      color: context.colors.foreground,
      alignment: Alignment.topLeft,
      onPressed: () {
        notificationManager.remove(ref.read(inAppNotificationsManagerProvider).notificationList.indexOf(this));
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 4,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    spacing: 8,
                    children: [
                      if (icon != null)
                        Icon(icon!),
                      if (title != null)
                        Expanded(
                          child: Text(title!,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                    ],
                  ),
                ),
                if (canCopy) SoButton(
                  width: 30, height: 30,
                    color: Colors.transparent,
                    child: Icon(Icons.copy, size: 20,),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: "$title : $content"));
                    notificationManager.remove(ref.read(inAppNotificationsManagerProvider).notificationList.indexOf(this));
                  },
                )
              ],
            ),

            if (content != null)
              Flexible(
                child: Text(content!,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                  style: Theme.of(context).textTheme.titleMedium,),
              ),
          ],
        ),
      ),
    );
  }
}