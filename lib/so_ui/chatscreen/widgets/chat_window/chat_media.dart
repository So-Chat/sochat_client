import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/modules/media/media.dart';
import 'package:sochat_client/modules/media/media_service.dart';
import 'package:sochat_client/so_ui/common/sub_buttons/downloadable_file.dart';
import 'package:sochat_client/so_ux/chat_controller.dart';

class ChatMedia extends StatefulWidget {
  const ChatMedia(this.mediaFile, this.ref, {super.key});

  final Media mediaFile;
  final WidgetRef ref;

  @override
  State<ChatMedia> createState() => ChatMediaState();
}

class ChatMediaState extends State<ChatMedia> {
  late final Future<Uint8List>? _future;

  @override
  void initState() {
    super.initState();
    _future = widget.ref
        .read(mediaServiceProvider)
        .loadPhotoBytes(
          widget.mediaFile,
          widget.ref,
          aesKey: widget.ref
              .read(chatControllerProvider).selectedChat!
              .chatKeys
              .last
              .key,
        );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaFile.mimeType!.contains("image")) {
      return FutureBuilder<Uint8List>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              width: 160,
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return const Icon(Icons.broken_image);
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const SizedBox(width: 160, height: 160);
          }
          return Image.memory(
            snapshot.data!,
            alignment: Alignment.topLeft,
            width: 160,
            height: 160,
            fit: BoxFit.scaleDown
          );
        },
      );
    } else {
      return DownloadableFile(widget.mediaFile);
    }
  }
}
