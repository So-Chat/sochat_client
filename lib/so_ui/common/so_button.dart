import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';

class SoButton extends ConsumerWidget {
  const SoButton({
    super.key,
    required this.child,
    this.height = 48,
    this.width,
    this.onPressed,
    this.onSecondaryTapDown,
    this.color,
    this.borderColor,
    this.alignment,
    this.anchorKey
  });

  final Widget child;
  final double? height ;
  final double? width;
  final VoidCallback? onPressed;
  final ValueChanged<Offset>? onSecondaryTapDown;
  final Color? color;
  final Color? borderColor;
  final Alignment? alignment;
  final Key? anchorKey;

  bool get isMobile =>
      Platform.isIOS || Platform.isFuchsia || Platform.isAndroid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      key: anchorKey ?? key,
      width: width,
      constraints: BoxConstraints(
        minHeight: height ?? 48,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor ?? Colors.transparent,
          width: 1,
        ),
      ),
      child: Material(
        borderRadius: BorderRadius.circular(10),
        color: color ?? context.colors.foreground,
        child: GestureDetector(
            onLongPressStart: (details) {
              if (!isMobile) { return; }
              onSecondaryTapDown?.call(details.globalPosition);
            },

            onSecondaryTapDown: (details) {
              onSecondaryTapDown?.call(details.globalPosition);
            },
            child: InkWell(
              mouseCursor: SystemMouseCursors.click,
              borderRadius: BorderRadius.circular(10),
              onTap: onPressed,
              child: Align(
                alignment: alignment ?? Alignment.center,
                child: child,
              ),
            ),
          ),
        ),
    );
  }
}
