import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sochat_client/context/context_menu.dart';
import 'package:sochat_client/context/context_menu_button.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/modules/media_capture/capture_service.dart';
import 'package:sochat_client/so_ui/common/so_button.dart';
import 'package:sochat_client/so_ui/common/so_dropdownbutton.dart';
import 'package:sochat_client/so_ux/settings_controller.dart';

class MultimediaSettings extends ConsumerStatefulWidget {
  const MultimediaSettings({super.key});

  @override
  ConsumerState<MultimediaSettings> createState() => _MultimediaSettingsState();
}

class _MultimediaSettingsState extends ConsumerState<MultimediaSettings> {

  late List<MediaDeviceInfo> devices = [];
  @override
  void initState() {
    super.initState();
    futureInit();
  }

  void futureInit() async {
    final service =
    await ref.read(mediaCaptureServiceProvider.future);

    final list = await service.getDeviceList();

    if (!mounted) return;

    setState(() {
      devices = list;
    });
  }

  final GlobalKey _buttonKey = GlobalKey();



  @override
  Widget build(BuildContext context) {

    ref.read(mediaCaptureServiceProvider).whenData((service) async {
      devices = await service.getDeviceList();
      print(devices);
    });


    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          SoDropdownButton(buttonKey: _buttonKey, items: { for (var d in devices) d.label : d.deviceId },
            width: 400, height: 50, dropdownHeight: 400, dropdownWidth: 400,
      ),
        ],
      ),
    );

  }
}