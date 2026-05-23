
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';

class KeysButton extends ConsumerWidget {

  KeysButton(this.icon, {super.key, required this.size, this.onPressed, this.color});
  final IconData icon;
  double size;
  final VoidCallback? onPressed;

  Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    color ??= context.colors.foreground;

    return SizedBox(
      width: size,
      height: size,
      child: Material(
        clipBehavior: Clip.hardEdge,
        borderRadius: BorderRadius.circular(10),
        color: color,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Icon(icon, color: context.colors.textPrimary, size: size/1.5),
        ),
      ),
    );
  }
}