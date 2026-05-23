import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sochat_client/extenstions/theme_getter.dart';
import 'package:sochat_client/modules/media_capture/capture_service.dart';
import 'package:sochat_client/so_ui/common/so_dropdownbutton.dart';

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
                // TODO: Made it more flexible
                SoDropdownButton(items: { for (var d in audioOutputDevices) d.deviceId : d.label },
                  width: 350, height: 50, dropdownHeight: 400, dropdownWidth: 350, borderColor: context.colors.outline, emptyText: "No Audio Output",
                    onChanged: (value) { captureService.selectedAudioOutput = captureService.audioOutputDevices.firstWhere((d) => d.deviceId == value.key ); },
                    initialValue: captureService.selectedAudioOutput != null ?
                    MapEntry(captureService.selectedAudioOutput!.deviceId, captureService.selectedAudioOutput!.label) : null
                ),
                SoDropdownButton(items: { for (var d in audioInputDevices) d.deviceId : d.label },
                  width: 350, height: 50, dropdownHeight: 400, dropdownWidth: 350, borderColor: context.colors.outline, emptyText: "No Audio Input",
                    onChanged: (value) { captureService.selectedAudioInput = captureService.audioInputDevices.firstWhere((d) => d.deviceId == value.key); },
                    initialValue: captureService.selectedAudioInput != null ?
                    MapEntry(captureService.selectedAudioInput!.deviceId, captureService.selectedAudioInput!.label) : null
                ),
              ],
            ),

            SoDropdownButton(items: { for (var d in videoInputDevices) d.deviceId : d.label },
              width: 710, height: 50, dropdownHeight: 400, dropdownWidth: 710, borderColor: context.colors.outline, emptyText: "No Video Input",
              onChanged: (value) { captureService.selectedVideoInput = captureService.videoInputDevices.firstWhere((d) => d.deviceId == value.key); },
                initialValue: captureService.selectedVideoInput != null ?
              MapEntry(captureService.selectedVideoInput!.deviceId, captureService.selectedVideoInput!.label) : null
            ),
          ],
        ),
      );
    }, error: (_, _) { return CircularProgressIndicator(); }, loading:() { return CircularProgressIndicator(); });
  }
}