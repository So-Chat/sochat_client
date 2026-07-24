import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';

class SearchButton extends ConsumerWidget {
  final VoidCallback? onPressed;

  const SearchButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SoButton(
      height: 30,
      color: context.colors.foreground,
      borderColor: context.colors.outline,
      alignment: Alignment.center,
      onPressed: onPressed,
      child: const Text(
        "Search",
        textAlign: TextAlign.center,
      ),
    );
  }
}
