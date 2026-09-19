import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
class SoAvatar extends ConsumerWidget {
  const SoAvatar({super.key, this.avatarBytes, this.radius = 48, this.nickname});

  final Uint8List? avatarBytes;
  final double radius;
  final String? nickname;


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool containAvatar = avatarBytes != null && avatarBytes!.isNotEmpty;
    bool containNickname = nickname != null && nickname!.isNotEmpty;
    return CircleAvatar(
          radius: radius,
          backgroundColor: !containAvatar ? context.colors.primary : Colors.transparent,
          backgroundImage: containAvatar
              ? MemoryImage(avatarBytes!)
              : null,
          child: !containAvatar && containNickname
              ? Text(nickname![0])
              : Text(""),
        );
  }
}
