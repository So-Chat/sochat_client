import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/context/context_menu.dart';
import 'package:sochat_client/context/context_menu_button.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';

class SoDropdownButton extends ConsumerStatefulWidget {
  const SoDropdownButton({super.key, required this.items, this.maxHeight, this.maxWidth, this.borderColor, this.color, this.dropdownHeight, this.dropdownWidth, this.onChanged, this.emptyText, this.initialValue});

  final double? maxHeight;
  final double? maxWidth;
  final Color? borderColor;
  final Color? color;
  final int? dropdownHeight;
  final int? dropdownWidth;
  
  final String? emptyText;

  final ValueChanged<dynamic>? onChanged;
  final Map<String, dynamic> items;

  final MapEntry<String, dynamic>? initialValue;

  @override
  ConsumerState<SoDropdownButton> createState() => _SoDropdownButtonState();
}

class _SoDropdownButtonState extends ConsumerState<SoDropdownButton> {

  MapEntry<String, dynamic>? selectedValue;
  @override
  void initState() {
    if (widget.initialValue != null) selectedValue = widget.initialValue;
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return SoButton(
        width: widget.maxWidth ?? double.infinity, height: widget.maxHeight,
        borderColor: widget.borderColor, color: widget.color,
        alignment: Alignment.centerLeft,

        key: widget.key,

        onPressed: () {
          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox == null || !renderBox.attached) return;

          final double actualWidth = renderBox.size.width;
          final double actualHeight = renderBox.size.height;

          final Offset globalPos = renderBox.localToGlobal(Offset.zero);

          final Offset menuPosition = Offset(
            globalPos.dx,
            globalPos.dy + actualHeight,
          );

          showContextMenu(
            context,
            menuPosition,
            items: widget.items.entries.map((k) => ContextMenuButton(
              width: actualWidth,
              height: widget.maxHeight,
              text: k.value,
              onTap: () {
                selectedValue = k;
                if (widget.onChanged != null) { widget.onChanged!.call(k); }
                setState(() {});
              },
            )).toList(),
            ref,
            height: widget.dropdownHeight,
            width: actualWidth.toInt(),
          );
        },

        child: Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 8),
          child: selectedValue != null ? Text(
              selectedValue!.value,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis, maxLines: 1
          ) : widget.emptyText != null ? Text(widget.emptyText!, style: Theme.of(context).textTheme.labelMedium)
              : Container(),
        ));
        // привет как дела?
        // привет, всё круто :D
  }
}