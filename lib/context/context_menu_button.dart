
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

  ContextMenuButton({super.key, required this.text, required this.onTap, this.leading, this.description, this.color, this.width});

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
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
                color: Colors.transparent
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
              child: Row(
                spacing: 10,
                children: [
                  if (leading != null) ...[
                    SizedBox(width: 44, child: leading!)
                  ],
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (description != null) ...[
                        Text(text, style: Theme.of(context).textTheme.titleMedium,),
                        Text(description! , style: Theme.of(context).textTheme.labelSmall,),
                      ] else ...[
                        Text(text, style: Theme.of(context).textTheme.bodyMedium),
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