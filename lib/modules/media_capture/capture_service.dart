import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter_miniaudio/flutter_miniaudio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

final mediaCaptureServiceProvider = FutureProvider<CaptureService>((ref) async {
  final service = CaptureService();

  service.bootstrapPc = await createPeerConnection({});

  //await service.testInitialize();
  await service.initializeDeviceList();

  navigator.mediaDevices.ondevicechange = ((event) async {
    await service.initializeDeviceList();
  });

  ref.onDispose(() {
    if (service.bootstrapPc != null) {
      service.bootstrapPc!.close();
      service.bootstrapPc!.dispose();
    }
    service.disposeLocalStream();
  });

  return service;
});

class CaptureService {
  MediaStream? _localStream;
  MediaStream? get localStream => _localStream;

  List<MediaDeviceInfo> audioInputDevices = [];
  List<MediaDeviceInfo> audioOutputDevices = [];
  List<MediaDeviceInfo> videoInputDevices = [];

  MediaDeviceInfo? selectedAudioInput;
  MediaDeviceInfo? selectedAudioOutput;
  MediaDeviceInfo? selectedVideoInput;

  bool userAudio = true;
  bool userVideo = false;

  RTCPeerConnection? bootstrapPc;

  Future<void> initializeLocalStream({
    bool audio = true,
    bool video = false,
  }) async {
    try {
      if (_localStream != null) {
        await disposeLocalStream();
      }

    Map<String, dynamic> audioConstraints = {
      'echoCancellation': true,
      'googEchoCancellation': true,
      'googNoiseSuppression': true,
      'googAutoGainControl': false,
    };


    final videoConstraints = (video &&
            selectedVideoInput != null &&
            selectedVideoInput!.deviceId.isNotEmpty)
      ? <String, dynamic>{
          'optional': [
            {'sourceId': selectedVideoInput!.deviceId},
          ],
        }
      : false;

      if (audio &&
        selectedAudioInput != null &&
        selectedAudioInput!.deviceId.isNotEmpty) {
        audioConstraints['optional'] = {'sourceId': selectedAudioInput!.deviceId};
      } else {
        audioConstraints['deviceId'] = true;
      }

      final constraints = {
        'audio': audioConstraints,
        'video': videoConstraints
      };


      _localStream = await mediaDevices.getUserMedia(constraints);

      userAudio = _localStream!.getAudioTracks().isNotEmpty;
      userVideo = _localStream!.getVideoTracks().isNotEmpty;


      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // Because getUserMedia often uses wrong devices despite setting certain devices
        // I set Audio input and output by force using Helper
        // Only in desktop
        if (selectedAudioInput != null &&
          selectedAudioInput!.deviceId.isNotEmpty) {
            await Helper.selectAudioInput(selectedAudioInput!.deviceId);
          }

          await Helper.selectAudioOutput(selectedAudioOutput!.deviceId);
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> initializeDeviceList() async {
    final allDevices = await navigator.mediaDevices.enumerateDevices();

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final defaultAudioOutput = MiniaudioContext.getCaptureDevices()
          .firstWhere((d) => d.isDefault);
      final defaultVideoOutput = MiniaudioContext.getPlaybackDevices()
          .firstWhere((d) => d.isDefault);

      await configureDevices(
        allDevices,
        desktopDefaultAO: defaultAudioOutput,
        desktopDefaultVO: defaultVideoOutput,
      );
      return;
    }

    await configureDevices(allDevices);
  }

  Future<void> configureDevices(
    List<MediaDeviceInfo> allDevices, {
    MiniaudioDeviceInfo? desktopDefaultAO,
    MiniaudioDeviceInfo? desktopDefaultVO,
  }) async {
    selectedAudioOutput ??= allDevices
        .where((d) => d.kind == "audiooutput")
        .firstOrNull;

    for (final d in allDevices) {
      if (d.kind == "audioinput") {
        audioInputDevices.add(d);
        if (selectedAudioInput == null &&
            desktopDefaultAO != null &&
            d.deviceId == desktopDefaultAO.deviceIdString) {
          selectedAudioInput = d;
        }
      } else if (d.kind == "audiooutput") {
        audioOutputDevices.add(d);
        if (selectedAudioOutput == null &&
            desktopDefaultVO != null &&
            d.deviceId == desktopDefaultVO.deviceIdString) {
          selectedAudioOutput = d;
        }
      } else if (d.kind == "videoinput") {
        videoInputDevices.add(d);
      }
      debugPrint("${d.kind} ${d.label} ${d.groupId} ${d.deviceId}");
    }
  }

  MediaDeviceInfo? findCurrentDevice(
    List<MediaDeviceInfo> devices,
    MediaStreamTrack track,
  ) {
    final settings = track.getSettings();

    return devices.firstWhere(
      (d) =>
          d.deviceId == settings["deviceId"] ||
          d.groupId == settings["groupId"] ||
          d.label == track.label,
    );
  }

  void setMediaInputs({bool? audio, bool? video}) {
    final audioTracks = _localStream?.getAudioTracks() ?? [];
    final videoTracks = _localStream?.getVideoTracks() ?? [];

    if (audio != null && audioTracks.isNotEmpty) {
      for (final track in audioTracks) {
        track.enabled = audio;
      }
      userAudio = audio;
    }

    if (video != null && videoTracks.isNotEmpty) {
      for (final track in videoTracks) {
        track.enabled = video;
      }
      userVideo = video;
    }
  }


  Future<void> playRemoteAudio(MediaStream stream) async {
    final audioRenderer = RTCVideoRenderer();
    await audioRenderer.initialize();
    audioRenderer.srcObject = stream;
  }

  Future<void> disposeLocalStream() async {
    for (final track in _localStream?.getTracks() ?? []) {
      await track.stop();
    }
    await _localStream?.dispose();
    _localStream = null;
  }

  Future<List<MediaDeviceInfo>> getDeviceList() async {
    final devices = await navigator.mediaDevices.enumerateDevices();

    for (final d in devices) {
      debugPrint('${d.kind} | ${d.label} | ${d.deviceId}');
    }
    return devices;
  }
}
