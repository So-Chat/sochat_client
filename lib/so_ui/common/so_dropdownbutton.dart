import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/context/context_menu.dart';
import 'package:sochat_client/context/context_menu_button.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';

class SoDropdownButton extends ConsumerStatefulWidget {
  const SoDropdownButton({super.key, required this.buttonKey, required this.items, this.height, this.width, this.borderColor, this.color, this.dropdownHeight, this.dropdownWidth, this.onChanged});

  final double? height;
  final double? width;
  final Color? borderColor;
  final Color? color;
  final int? dropdownHeight;
  final int? dropdownWidth;

  final ValueChanged<dynamic>? onChanged;
  final Map<String, dynamic> items;

  final GlobalKey buttonKey;

  @override
  ConsumerState<SoDropdownButton> createState() => _SoDropdownButtonState();
}

class _SoDropdownButtonState extends ConsumerState<SoDropdownButton> {

  MapEntry<String, dynamic>? selectedValue;



  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return SoButton(
      width: widget.width , height: widget.height,
      borderColor: widget.borderColor, color: widget.color,

      key: widget.buttonKey, child: selectedValue != null ? Text(selectedValue!.key) : Container(),
      onPressed: () {
        final RenderBox box = widget.buttonKey.currentContext!.findRenderObject() as RenderBox;
        Offset globalPosition = box.localToGlobal(Offset.zero);
        final Size size = box.size;

        final Offset menuPosition = Offset(
          globalPosition.dx + (widget.width! - size.width) / 2,
          globalPosition.dy + size.height,
        );

        showContextMenu(context, menuPosition,
            items: widget.items.entries.map((k) => ContextMenuButton(width: widget.dropdownWidth!.toDouble(), text: k.key,
                onTap: () { selectedValue = k; widget.onChanged; setState(() {}); }), ).toList(),
            ref,
            height: widget.dropdownHeight, width: widget.dropdownWidth);
      });
  }
}