import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/context/menus.dart';
import 'package:sochat_client/modules/keys/key_service.dart';
import 'package:sochat_client/context/context_menu.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';
import 'package:sochat_client/so_ui/loginscreen/widgets/keys/selectable_button.dart';

class KeysList extends ConsumerWidget  {

  const KeysList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyService = ref.watch(keyServiceProvider);
    final keyServiceNotifier = ref.watch(keyServiceProvider.notifier);
    final selectedKey = ref.watch(selectedProfileProvider);

    return Expanded(
      flex: 2,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: context.colors.outline,
            width: 1.0,
          ),
          color: context.colors.foreground,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          children: [
            Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: context.colors.outline,
                    width: 1,
                  ),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Keychain", style: Theme.of(context).textTheme.labelSmall,),
                  Row(
                    children: [
                      SoButton(height: 30, width: 30, onPressed: Menus.keyEditorWindow(context, selectedKey, ref),child: Icon(Icons.edit, color: context.colors.textPrimary, size: 25),),
                      SoButton(height: 30, width: 30, onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: keyServiceNotifier.profileToJson(selectedKey)));
                      },child: Icon(Icons.copy, color: context.colors.textPrimary, size: 25),),
                      SoButton(height: 30, width: 30, onPressed: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        String text = data?.text ?? "";
                        keyServiceNotifier.parseProfiles(text);

                      },child: Icon(Icons.paste, color: context.colors.textPrimary, size: 25),),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer(builder: (context, ref, _) {
                final keyService = ref.watch(keyServiceProvider);
                final profiles = keyService.profiles;

                return ListView.separated(
                  itemCount: profiles.length,
                  itemBuilder: (context, index) {
                    final profile = profiles.entries.toList()[index];
                    final isSelected = ref.watch(selectedProfileProvider) == index;

                    return SelectableButton(
                      size: 40,
                      profile.key,
                      "",
                      isSelected: isSelected,
                      onPressed: () {
                        ref.read(selectedProfileProvider.notifier).state = index;
                      },

                      menuItems: Menus.keysListContext(context, index, ref,  profile),

                      onSecondaryTap: (details) {
                        showContextMenu(context, details.globalPosition,
                            items: Menus.keysListContext(context, index, ref,  profile),
                            ref);
                      },
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}