import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/context/menus.dart';
import 'package:sochat_client/modules/keys/key_service.dart';
import 'package:sochat_client/context/context_menu.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';
import 'package:sochat_client/so_ui/loginscreen/widgets/keys/selectable_button.dart';

class ServerList extends ConsumerWidget  {

  const ServerList({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedServer = ref.watch(selectedServerProvider);

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
                  Text("Servers", style: Theme.of(context).textTheme.labelSmall,),
                  Row(
                    children: [
                      SoButton(height: 30, width: 30,
                          onPressed: Menus.addServerEditorWindow(context, ref), child: Icon(Icons.add, color: context.colors.textPrimary, size: 25)),
                      SoButton(height: 30, width: 30,
                          onPressed: Menus.serverEditorWindow(context, selectedServer, ref), child: Icon(Icons.edit, color: context.colors.textPrimary, size: 25)
                      )
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer(builder: (context, ref, _) {
                final keyService = ref.watch(keyServiceProvider);
                final servers = keyService.servers;

                return ListView.separated(
                  itemCount: servers.length,
                  itemBuilder: (context, index) {
                    final server = servers.entries.toList()[index];
                    final isSelected = ref.watch(selectedServerProvider) == index;

                    return SelectableButton(
                      size: 40,
                      server.key,
                      server.value,
                      isSelected: isSelected,
                      onPressed: () {
                        ref.read(selectedServerProvider.notifier).state = index;
                      },
                      menuItems: Menus.serversListContext(context, index, ref, server),
                      onSecondaryTap: (details) {
                        showContextMenu(context, details.globalPosition,
                            items: Menus.serversListContext(context, index, ref, server),
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