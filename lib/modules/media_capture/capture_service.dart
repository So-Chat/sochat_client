import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';


final mediaCaptureServiceProvider = FutureProvider<CaptureService>((ref) async {
  final service = CaptureService();

  service.bootstrapPc = await createPeerConnection({});

  await service.initialize();

  navigator.mediaDevices.ondevicechange = ((event) async {
    await service.initialize();
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

  Future<void> initialize({String? audioId, String? videoId, bool audio = true, bool video = false, bool removeAfter = true}) async {
    if (_localStream != null) {
      await disposeLocalStream();
    }
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': audioId != null
          ? {
        'deviceId': audioId.toString(),
        'sourceId': audioId.toString(),
        'echoCancellation': false,
        'googEchoCancellation': false,
        'googEchoCancellation2': false,
        'googNoiseSuppression': false,
        'googNoiseSuppression2': false,
        'googAutoGainControl': false,
        'googHighpassFilter': false,
      }
          : audio,
      'video': videoId != null
          ? {
        'deviceId': videoId.toString(),
        'sourceId': videoId.toString(),
      }
          : video,
    });

    print(_localStream?.getVideoTracks().length);

    final videoTrack = _localStream?.getVideoTracks();
    final audioTrack = _localStream?.getAudioTracks();
    await Future.delayed(Duration(seconds: 2));

    final allDevices = await navigator.mediaDevices.enumerateDevices();

    await configureDevices(allDevices, videoTrack, audioTrack);

    if (removeAfter) {
      await disposeLocalStream();
      return;
    }
  }

  Future<void> configureDevices(List<MediaDeviceInfo> allDevices, List<MediaStreamTrack>? videoTrack, List<MediaStreamTrack>? audioTrack) async {
    selectedAudioOutput ??= allDevices.where((d) => d.kind == "audiooutput",).firstOrNull;

    for (final d in allDevices) {
      if (d.kind == "audioinput") {
        audioInputDevices.add(d);
        if (audioTrack != null && audioTrack.isNotEmpty) {
          final audioSettings = audioTrack.first.getSettings();
          print(audioSettings);
          if (d.deviceId == audioSettings["deviceId"] && selectedAudioInput == null) {
            selectedAudioInput = d;
          }
        }
      } else if (d.kind == "audiooutput") {
        audioOutputDevices.add(d);
      } else if (d.kind == "videoinput") {
        videoInputDevices.add(d);
        if (videoTrack != null && videoTrack.isNotEmpty) {
          final videoSettings = videoTrack.first.getSettings();
          print(videoSettings);
          if (d.deviceId == videoSettings["deviceId"] && selectedVideoInput == null) {
            selectedVideoInput = d;
          }
        }
      }
      print("${d.kind} ${d.label} ${d.groupId} ${d.deviceId}");
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

  void setMediaInputs({bool audio = false, bool video = false}){
    if (_localStream != null) {
      _localStream?.getAudioTracks().forEach((t) => t.enabled = audio);
      _localStream?.getVideoTracks().forEach((t) => t.enabled = video);
    }
  }

  Future<void> playRemoteAudio(MediaStream stream) async {
    final audioRenderer = RTCVideoRenderer();
    await audioRenderer.initialize();
    audioRenderer.srcObject = stream;
  }

  Future<void> disposeLocalStream() async{
    for (final track in _localStream?.getTracks() ?? []){
      await track.stop();
    }
    await _localStream?.dispose();
    _localStream = null;
  }

  Future<List<MediaDeviceInfo>> getDeviceList() async {
    final devices = await navigator.mediaDevices.enumerateDevices();

    for (final d in devices) {
      print('${d.kind} | ${d.label} | ${d.deviceId}');
    }
    return devices;
  }

}