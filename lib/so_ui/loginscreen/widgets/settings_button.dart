import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';

class SettingsButton extends ConsumerWidget {

  const SettingsButton(this.icon, {super.key, required this.size, this.onPressed, });
  final IconData icon;
  final double size;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide.none,
          left: BorderSide.none,
          right: BorderSide.none,
          bottom: BorderSide(
            color: context.colors.outline,
            width: 1,
          ),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: context.colors.outline,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        color: context.colors.foreground,
        child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onPressed,
            child: Icon(icon, color: context.colors.textPrimary, size: 20,)),
      ),
    );
  }
}
