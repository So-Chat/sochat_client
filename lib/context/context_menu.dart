

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/context/context_manager.dart';

import 'context_menu_button.dart';


void showContextMenu(
    BuildContext context,
    Offset position,
    WidgetRef ref, {
      required List<ContextMenuButton> items,
      int? width, int? height
    }) {
  final contextService = ref.read(contextManagerProvider);

  final screenSize = MediaQuery.of(context).size;

  double dx = position.dx;
  double dy = position.dy;

  const double edgePadding = 10;

  int menuWidth = width ?? 230;
  int menuHeight = items.length * 44;

  final bool isScrollable = height != null && height < menuHeight;
  if (isScrollable) menuHeight = height;

  if (dx + menuWidth > screenSize.width - edgePadding) {
    dx = position.dx - menuWidth;
    if (dx < edgePadding) dx = edgePadding;
  }

  if (dy + menuHeight > screenSize.height - edgePadding) {
    dy = position.dy - menuHeight;
    if (dy < edgePadding) dy = edgePadding;
  }

  final overlay = Overlay.of(context);

  items.forEach((i) {
    i.removeAction = () => contextService.hideMenu();
  });

  final FocusNode _menuFocusNode = FocusNode();

  final overlayEntry = OverlayEntry(
    builder: (ctx) {
      return FocusScope(
        autofocus: true,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => contextService.hideMenu(),
              ),
            ),

            Positioned(
              left: dx,
              top: dy,
              child: Shortcuts(
                shortcuts: {
                  LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
                },
                child: Actions(
                  actions: {
                    DismissIntent: CallbackAction(
                      onInvoke: (_) {
                        contextService.hideMenu();
                        return null;
                      },
                    ),
                  },
                  child: Focus(
                    focusNode: _menuFocusNode,
                    autofocus: true,
                    child: Material(
                      borderRadius: BorderRadius.circular(10),
                      color: context.colors.foreground,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: context.colors.outline),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: isScrollable ? SizedBox(
                          height: double.parse(height.toString()),

                          child: SingleChildScrollView(scrollDirection: Axis.vertical,child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: items,
                          )),
                        ) : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: items,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    contextService.showMenu(overlay, overlayEntry);
    Future.microtask(() {
      _menuFocusNode.requestFocus();
    });
  });
}