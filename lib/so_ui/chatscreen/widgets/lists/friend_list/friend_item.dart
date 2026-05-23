import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/context/menus.dart';
import 'package:sochat_client/context/context_manager.dart';
import 'package:sochat_client/context/context_menu.dart';
import 'package:sochat_client/context/context_menu_button.dart';
import 'package:sochat_client/modules/users/user.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';


class FriendItem extends ConsumerWidget {
  const FriendItem({
    super.key,
    required this.user,
    this.description = "",
    this.trailing,
    this.menuItems,
    this.color,
  });

  final User user;
  final String description;
  final Widget? trailing;
  final List<ContextMenuButton>? menuItems;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextManager = ref.read(contextManagerProvider);

    Color buttonColor = color ?? Colors.transparent;

    return Material(
      color: buttonColor,
      borderRadius: BorderRadius.circular(10),
      child: SoButton(
        height: 70,
        color: buttonColor,
        width: double.infinity,
        onPressed: Menus.userProfile(context, ref, user),
        onSecondaryTapDown: (details) {
          final menuItems = this.menuItems ??
              Menus.friendContext(context, ref, user, description);

          showContextMenu(
            context,
            details,
            items: menuItems,
            ref,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      child: Text(user.username[0]),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        user.nickname,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}