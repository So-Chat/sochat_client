
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/context/context_menu.dart';
import 'package:sochat_client/context/context_menu_button.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';

class SelectableButton extends ConsumerStatefulWidget {
  const SelectableButton(
      this.text,
      this.secondaryText, {
        super.key,
        required this.size,
        this.onPressed,
        this.onSecondaryTap,
        required this.isSelected,
        required this.menuItems,
      });

  final String text;
  final String secondaryText;
  final double size;
  final VoidCallback? onPressed;
  final void Function(TapDownDetails)? onSecondaryTap;
  final List<ContextMenuButton> menuItems;
  final bool isSelected;

  @override
  ConsumerState<SelectableButton> createState() =>
      _SelectableButtonState();
}

class _SelectableButtonState extends ConsumerState<SelectableButton> {
  bool isHovered = false;
  final GlobalKey _buttonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return SoButton(
      height: 40,
      width: double.infinity,
      
      onPressed: widget.onPressed,
      //borderColor: context.colors.outline,

      onSecondaryTapDown: (pos) {
        widget.onSecondaryTap?.call(
          TapDownDetails(globalPosition: pos),
        );
      },

      color: widget.isSelected
          ? context.colors.positive
          : context.colors.foreground,

      child: MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),

        child: Container(
          key: _buttonKey,
          padding: EdgeInsets.all(8),

          child: Row(
            children: [
              /// TEXT
              Expanded(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: widget.isSelected
                        ? Colors.white
                        : context.colors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 8),

              /// SECONDARY TEXT
              Expanded(
                child: Text(
                  widget.secondaryText,
                  style: TextStyle(
                    color: widget.isSelected
                        ? Colors.white.withValues(alpha: 0.5)
                        : context.colors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),

              /// MENU BUTTON
              if (isHovered)
                GestureDetector(
                  onTap: () {
                    final box = _buttonKey.currentContext!
                        .findRenderObject() as RenderBox;

                    final global = box.localToGlobal(Offset.zero);
                    final size = box.size;

                    final position = Offset(
                      global.dx + size.width - 30,
                      global.dy + size.height,
                    );

                    showContextMenu(
                      context,
                      position,
                      items: widget.menuItems,
                      ref,
                    );
                  },
                  child: Icon(
                    Icons.more_vert,
                    color: widget.isSelected
                        ? Colors.white.withValues(alpha: 0.5)
                        : context.colors.textSecondary,
                  ),
                )
              else
                const SizedBox(width: 24),
            ],
          ),
        ),
      ),
    );
  }
}