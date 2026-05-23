import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/context/context_menu.dart';
import 'package:sochat_client/context/context_menu_button.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';

class SoDropdownButton extends ConsumerStatefulWidget {
  const SoDropdownButton({super.key, required this.items, this.height, this.width, this.borderColor, this.color, this.dropdownHeight, this.dropdownWidth, this.onChanged, this.emptyText, this.initialValue});

  final double? height;
  final double? width;
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

  final GlobalKey buttonKey = GlobalKey();

  @override
  void initState() {
    if (widget.initialValue != null) selectedValue = widget.initialValue;
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return SoButton(
      width: widget.width , height: widget.height,
      borderColor: widget.borderColor, color: widget.color,

      key: buttonKey, child: selectedValue != null ? Text(selectedValue!.value,
        style: Theme.of(context).textTheme.bodyMedium,) :
          widget.emptyText != null ? Text(widget.emptyText!, style: Theme.of(context).textTheme.labelMedium) : Container(),
      onPressed: () {
        final RenderBox box = buttonKey.currentContext!.findRenderObject() as RenderBox;
        Offset globalPosition = box.localToGlobal(Offset.zero);
        final Size size = box.size;

        final Offset menuPosition = Offset(
          globalPosition.dx + (widget.width! - size.width) / 2,
          globalPosition.dy,
        );

        showContextMenu(context, menuPosition,
            items: widget.items.entries.map((k) => ContextMenuButton(width: widget.dropdownWidth!.toDouble(), text: k.value,
                onTap: () { selectedValue = k;
                if (widget.onChanged != null) { widget.onChanged!.call(k); };
                setState(() {}); }), ).toList(),
            ref,
            height: widget.dropdownHeight, width: widget.dropdownWidth);
      });
    // привет как дела?
  }
}