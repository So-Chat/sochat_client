import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/so_ui/notifications/so_notification.dart';

final inAppNotificationsManagerProvider = NotifierProvider<InAppNotificationsManager, InAppNotificationsManagerState>(
  InAppNotificationsManager.new,
);

class InAppNotificationsManagerState {

  final List<SoNotification> notificationList;

  InAppNotificationsManagerState({required this.notificationList});

  InAppNotificationsManagerState copyWith({
    List<SoNotification>? notifications,
  }) {
    return InAppNotificationsManagerState(
      notificationList: notifications ?? notificationList,
    );
  }
}

class InAppNotificationsManager extends Notifier<InAppNotificationsManagerState> {
  List<SoNotification> get notificationList =>
      state.notificationList;

  @override
  InAppNotificationsManagerState build() {
    return InAppNotificationsManagerState(notificationList: []);
  }

  void remove(int index) {
    final newList = List<SoNotification>.from(notificationList);

    newList.removeAt(index);

    state = state.copyWith(notifications: newList);
  }

  void addUpdate(SoNotification notification) {
    final newList = List<SoNotification>.from(notificationList);
    newList.add(notification);
    state = state.copyWith(notifications: newList);
  }

  void addError(String title, String content){
    final notification = SoNotification(icon: Icons.error_outline_sharp,title: title, content: content, canCopy: true,);
    addUpdate(notification);
  }
}
