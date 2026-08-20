import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';

void _emptyCallback(String text) {}

class SoCommonInput extends ConsumerWidget {

  final TextStyle? textStyle;
  final InputDecoration? decoration;

  final Border? border;
  final Color? color;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final int? maxLength;
  final int? maxLines;
  final ValueChanged<String>? onChanged;

  final TextEditingController? textEditingController;

  const SoCommonInput({super.key, this.textStyle, this.decoration, this.border, this.color,
    this.borderRadius, this.width, this.height, this.maxLength, this.maxLines, this.onChanged = _emptyCallback, this.textEditingController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultDecoration = InputDecoration(
      hintText: "What are you looking for?",
      hintStyle: Theme.of(context).textTheme.labelMedium,
      border: const OutlineInputBorder(borderSide: BorderSide.none),
    );

    return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: border ?? Border(
            top: BorderSide.none,
            left: BorderSide.none,
            right: BorderSide.none,
            bottom: BorderSide(
              color: context.colors.outline,
              width: 1,
            ),
          ),
          color: color ?? context.colors.foreground,
          borderRadius: borderRadius ?? BorderRadius.circular(10),
        ),
        child: TextField(
          onChanged: onChanged,
          maxLines: maxLines,
          maxLength: maxLength,
            controller: textEditingController,
            keyboardType: TextInputType.multiline,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: decoration?.copyWith(
              hintText: decoration?.hintText ?? defaultDecoration.hintText,
              hintStyle: decoration?.hintStyle ?? defaultDecoration.hintStyle,
              border: decoration?.border ?? defaultDecoration.border,
              prefixIcon: decoration?.prefixIcon ?? defaultDecoration.prefixIcon,
              suffixIcon: decoration?.suffixIcon ?? defaultDecoration.suffixIcon,
              contentPadding: decoration?.contentPadding ?? defaultDecoration.contentPadding,
            ) ??
                defaultDecoration
        )
    );
  }
}
