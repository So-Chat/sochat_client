import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/hex_color.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';

class LoginButton extends ConsumerWidget {
  final String text;
  final Color color;
  VoidCallback onTap;

  LoginButton({super.key, required this.text, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: color,

      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: context.colors.outline,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
          onTap: onTap,

          hoverColor: Colors.black.withValues(alpha: 0.05),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.black.withValues(alpha: 0.10),

          child: Container(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
              child: Row(
                spacing: 10,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(text, style: TextStyle(color: "FBFFEF".toColor()),)
                ],
              ),
            ),
          )
      ),
    );
  }
}