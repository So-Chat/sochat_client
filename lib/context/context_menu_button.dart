
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';

class ContextMenuButton extends ConsumerWidget {
  final String text;
  final VoidCallback onTap;

  VoidCallback removeAction = () {};

  final Widget? leading;
  final String? description;
  final double? width;
  final double? height;

  final Alignment? alignment;
  final CrossAxisAlignment? textAlignment;

  ContextMenuButton({super.key, required this.text, required this.onTap, this.leading, this.description, this.color, this.width, this.height, this.textAlignment, this.alignment});

  Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    color ??= context.colors.foreground;

    return Material(
      color: color,
        borderRadius: BorderRadius.circular(10),
      child: InkWell(
          onTap: () {
            onTap();
            removeAction.call();
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: width ?? 230,
            height: height,
            alignment: alignment ?? Alignment.centerLeft,
            decoration: BoxDecoration(
                color: Colors.transparent
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              child: Row(
                spacing: 10,
                children: [
                  if (leading != null) ...[
                    SizedBox(width: 44, child: leading!)
                  ],
                  Expanded(child: Column(
                    crossAxisAlignment: textAlignment ?? CrossAxisAlignment.start,
                    children: [
                      if (description != null) ...[
                        Text(text, style: Theme.of(context).textTheme.titleMedium),
                        Text(description! , style: Theme.of(context).textTheme.labelSmall, overflow: TextOverflow.ellipsis, maxLines: 1,),
                      ] else ...[
                        Text(text, style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis, maxLines: 1,),
                      ]
                    ],
                  ))
                ],
              ),
            ),
          )
      ),
    );
  }
}