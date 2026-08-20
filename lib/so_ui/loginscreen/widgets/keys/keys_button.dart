
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';

void _emptyCallback() {}

class KeysButton extends ConsumerWidget {

  const KeysButton(this.icon, {super.key, required this.size, this.onPressed = _emptyCallback, this.color});
  final IconData icon;
  final double size;
  final VoidCallback? onPressed;

  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        clipBehavior: Clip.hardEdge,
        borderRadius: BorderRadius.circular(10),
        color: color ?? context.colors.foreground,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Icon(icon, color: context.colors.textPrimary, size: size/1.5),
        ),
      ),
    );
  }
}
