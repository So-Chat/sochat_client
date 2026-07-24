import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';

class BasePanel extends ConsumerWidget {
  final Widget child;
  final double borderRadius;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final Color? borderColor;
  final bool isExpanded;

  const BasePanel({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.borderRadius = 10.0,
    this.borderColor,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return isExpanded
        ? Expanded(child: _buildPanel(context))
        : _buildPanel(context);
  }

  Widget _buildPanel(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor ?? context.colors.outline,
          width: 1.0,
        ),
        color: backgroundColor ?? context.colors.foreground,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );
  }
}
