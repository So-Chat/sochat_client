import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/extenstions/utils.dart';
import 'package:sochat_client/modules/media/media.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';
import 'package:sochat_client/so_ux/chat_controller.dart';

class DownloadableFile extends ConsumerWidget {

  final Media media;

  const DownloadableFile(this.media, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {


    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 350
        ),
        child: IntrinsicWidth(
          child: SoButton(
            color: context.colors.surface,
            height: 80,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SoButton(
                    width: 40,
                    height: 40,
                    color: context.colors.primary,
                    onPressed: () { ref.read(chatControllerProvider.notifier).saveFile(media); },
                    child: Icon(Icons.file_download),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          Text(
                            media.fileName!,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(Utils.configureFileSize(media.fileSize!), style: Theme.of(context).textTheme.labelSmall)
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


}