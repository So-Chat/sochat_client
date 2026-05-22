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

  late List<MediaDeviceInfo> audioInputDevices = [];
  late List<MediaDeviceInfo> audioOutputDevices = [];
  late List<MediaDeviceInfo> videoInputDevices = [];
  @override
  void initState() {
    super.initState();
    futureInit();
  }

  void futureInit() async {
    final service =
    await ref.read(mediaCaptureServiceProvider.future);

    if (!mounted) return;

    final allDevices = await service.getDeviceList();
    setState(() {
      for (final d in allDevices) {
        if (d.kind == "audioinput") {
          audioInputDevices.add(d);
        } else if (d.kind == "audiooutput") {
          audioOutputDevices.add(d);
        } else if (d.kind == "videoinput") {
          videoInputDevices.add(d);
          print(d.label);
        }
        print("${d.kind} ${d.label}");
      }
  });
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(mediaCaptureServiceProvider);


    return service.when(data: (captureService) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          spacing: 8,
          crossAxisAlignment: .center,
          children: [
            Row(
              spacing: 10,
              mainAxisAlignment: .center,
              children: [
                SoDropdownButton(items: { for (var d in audioOutputDevices) d.label : d.deviceId },
                  width: 350, height: 50, dropdownHeight: 400, dropdownWidth: 350, borderColor: context.colors.outline, emptyText: "No Audio Output",
                    initialValue: captureService.selectedAudioOutput != null ?
                    MapEntry(captureService.selectedAudioOutput!.label, captureService.selectedAudioOutput!.deviceId) : null
                ),
                SoDropdownButton(items: { for (var d in audioInputDevices) d.label : d.deviceId },
                  width: 350, height: 50, dropdownHeight: 400, dropdownWidth: 350, borderColor: context.colors.outline, emptyText: "No Audio Input",
                    initialValue: captureService.selectedAudioInput != null ?
                    MapEntry(captureService.selectedAudioInput!.label, captureService.selectedAudioInput!.deviceId) : null
                ),
              ],
            ),

            SoDropdownButton(items: { for (var d in videoInputDevices) d.label : d.deviceId },
              width: 710, height: 50, dropdownHeight: 400, dropdownWidth: 710, borderColor: context.colors.outline, emptyText: "No Video Input",
              initialValue: captureService.selectedVideoInput != null ?
              MapEntry(captureService.selectedVideoInput!.label, captureService.selectedVideoInput!.deviceId) : null
            ),
          ],
        ),
      );
    }, error: (_, _) { return CircularProgressIndicator(); }, loading:() { return CircularProgressIndicator(); });
  }
}