import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/modules/friends/friends_service.dart';
import 'package:sochat_client/so_ui/chatscreen/widgets/lists/friend_list/friend_item.dart';
import 'package:sochat_client/so_ui/chatscreen/widgets/lists/friend_list/outgoing_friend_item.dart';
import 'package:sochat_client/so_ui/chatscreen/widgets/lists/friend_list/outcoming_friend_item.dart';
import 'package:sochat_client/so_ui/common/base_panel.dart';

class FriendList extends ConsumerWidget {

  final Color? borderColor;
  final double? borderRadius;
  final EdgeInsets? padding;

  const FriendList({
    super.key, this.borderColor, this.borderRadius, this.padding
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedRelativesList = ref.watch(blockedListProvider);
    final friendRelativesList = ref.watch(friendsListProvider);
    final incomingRelativesList = ref.watch(incomingRequestsProvider);
    final outgoingRelativesList = ref.watch(outgoingRequestsProvider);

    return BasePanel(
      flex: 1,
      borderColor: borderColor,
      borderRadius: borderRadius ?? 10,
      backgroundColor: context.colors.surface,
      padding: padding ?? EdgeInsets.all(8),
      child: ListView(
        children: [
          ...friendRelativesList.map((e) => FriendItem(
            user: e,
          )),

          ...incomingRelativesList.map((e) => IncomingFriendItem(
            user: e,
          )),

          ...outgoingRelativesList.map((e) => OutgoingFriendItem(
            user: e,
          )),

          ...blockedRelativesList.map((e) => FriendItem(
            user: e,
          )),
        ],
      ),
    );
  }
}