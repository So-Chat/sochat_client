import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';

class TopButton extends ConsumerWidget {

  const TopButton(this.icon, {super.key, this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SoButton(
      width: 30,
      height: 30,
      color: context.colors.foreground,
      borderColor: context.colors.outline,
      alignment: Alignment.center,
      onPressed: onPressed,
      child: Icon(
        icon,
        color: context.colors.textPrimary,
        size: 20,
      ),
    );
  }
}
