import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/hex_color.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';

class LoginButton extends ConsumerWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;
  final double height;

  const LoginButton({
    super.key,
    required this.text,
    required this.color,
    required this.onTap,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SoButton(
      height: height,
      color: color,
      borderColor: context.colors.outline,
      alignment: Alignment.center,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text(text, style: TextStyle(color: "FBFFEF".toColor()))],
        ),
      ),
    );
  }
}
