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
    final hasAvatar = avatarBytes?.isNotEmpty ?? false;
    final hasNickname = nickname?.isNotEmpty ?? false;

    return CircleAvatar(
      radius: radius,
      backgroundColor: hasAvatar
          ? Colors.transparent
          : context.colors.primary,
      backgroundImage: hasAvatar
          ? MemoryImage(avatarBytes!)
          : null,
      child: !hasAvatar && hasNickname
          ? Text(nickname![0].toUpperCase(), style: Theme.of(context).textTheme.bodyLarge,)
          : null,
    );
  }
}
