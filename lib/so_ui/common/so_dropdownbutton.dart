import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';

class SoDropdownButton extends ConsumerWidget {
  const SoDropdownButton({super.key, required this.menuEntries, required this.onSelected});

  final ValueChanged<dynamic> onSelected;
  final List<DropdownMenuItem<dynamic>> menuEntries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Container(
      width: 100,
      color: context.colors.surface,
      child: Stack(
        children: [
            DropdownButton<dynamic>(
              isExpanded: true,
              underline: Container(),
              value: menuEntries.first.value,
              elevation: 1,
              alignment: AlignmentGeometry.center,
                icon: SizedBox.shrink(),
                dropdownColor: context.colors.surface,
                onChanged: (value) {
                  onSelected(value);
                },
                items: menuEntries
            ),
        ],
      )
    );
  }


}