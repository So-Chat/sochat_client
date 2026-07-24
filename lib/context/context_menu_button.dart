
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';

class ContextMenuButton extends ConsumerWidget {
  final String text;
  final VoidCallback onTap;

  final VoidCallback removeAction;

  final Widget? leading;
  final String? description;
  final double? width;
  final double? height;

  final Alignment? alignment;
  final CrossAxisAlignment? textAlignment;
  final Color? color;

  static void _empty() {}

  const ContextMenuButton({
    super.key,
    required this.text,
    required this.onTap,
    this.removeAction = _empty,
    this.leading,
    this.description,
    this.color,
    this.width,
    this.height,
    this.textAlignment,
    this.alignment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SoButton(
      width: width ?? 230,
      height: height ?? 48,
      color: color ?? context.colors.foreground,
      alignment: alignment ?? Alignment.centerLeft,
      onPressed: () {
        onTap();
        removeAction.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 10,
        ),
        child: Row(
          spacing: 10,
          children: [
            if (leading != null)
              SizedBox(
                width: 44,
                child: leading!,
              ),

            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    textAlignment ?? CrossAxisAlignment.start,
                children: [
                  if (description != null) ...[
                    Text(
                      text,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      description!,
                      style: Theme.of(context).textTheme.labelSmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ] else ...[
                    Text(
                      text,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ContextMenuButton copyWith({
    String? text,
    VoidCallback? onTap,
    VoidCallback? removeAction,
    Widget? leading,
    String? description,
    double? width,
    double? height,
    Alignment? alignment,
    CrossAxisAlignment? textAlignment,
    Color? color,
  }) {
    return ContextMenuButton(
      text: text ?? this.text,
      onTap: onTap ?? this.onTap,
      removeAction: removeAction ?? this.removeAction,
      leading: leading ?? this.leading,
      description: description ?? this.description,
      width: width ?? this.width,
      height: height ?? this.height,
      alignment: alignment ?? this.alignment,
      textAlignment: textAlignment ?? this.textAlignment,
      color: color ?? this.color,
    );
  }
}
