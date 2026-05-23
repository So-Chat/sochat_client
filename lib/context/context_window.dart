import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/context/context_manager.dart';


void showContextWindow(
    BuildContext context,
    WidgetRef ref,
    {required Widget child, double height = 700, double width = 466}
    ) {
  final contextService = ref.read(contextManagerProvider);

  final overlay = Overlay.of(context);

  final FocusNode menuFocusNode = FocusNode(
    onKeyEvent: (node, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.escape) {
        contextService.hideWindow();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
  );


  final overlayEntry = OverlayEntry(
    builder: (context) {
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => contextService.hideWindow(),
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
          Center(
            child: Material(
              borderRadius: BorderRadius.circular(10),
              child: Focus(
                autofocus: true,
                focusNode: menuFocusNode,
                child: Container(
                    width: width,
                    height: height,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.colors.outline,
                      ),
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: child
                ),
              ),
            ),
          ),
        ],
      );
    },
  );

  contextService.hideWindow();


  WidgetsBinding.instance.addPostFrameCallback((_) {
    contextService.showWindow(overlay, overlayEntry);
    menuFocusNode.requestFocus();
  });
}