import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';


final mediaCaptureServiceProvider = FutureProvider<CaptureService>((ref) async {
  final service = CaptureService();

  await service.initialize();

  navigator.mediaDevices.ondevicechange = ((event) async {
    await service.initialize();
  });

  ref.onDispose(() => service.dispose());
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

  Future<void> initialize({int? audioId, int? videoId, bool audio = true, bool video = true}) async {
    if (_localStream != null) {
      _localStream!.dispose();
      _localStream = null;
    }
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': audioId != null
          ? {
        'deviceId': {'exact': audioId.toString()}
      }
          : audio,
      'video': videoId != null
          ? {
        'deviceId': {'exact': videoId.toString()}
      }
          : video,
    });

    print(_localStream?.getVideoTracks().length);

    final videoTrack = _localStream?.getVideoTracks();
    final audioTrack = _localStream?.getAudioTracks();

    print("STREAM CREATED");

    await Future.delayed(Duration(seconds: 2));

    final allDevices = await navigator.mediaDevices.enumerateDevices();

    print("DEVICES: ${allDevices.length}");

    await configureDevices(allDevices, videoTrack, audioTrack);
  }

  Future<void> configureDevices(List<MediaDeviceInfo> allDevices, List<MediaStreamTrack>? videoTrack, List<MediaStreamTrack>? audioTrack) async {
    selectedAudioOutput = allDevices.where((d) => d.kind == "audiooutput",).firstOrNull;

    for (final d in allDevices) {
      if (d.kind == "audioinput") {
        audioInputDevices.add(d);
        if (audioTrack != null && audioTrack.isNotEmpty) {
          final audioSettings = audioTrack.first.getSettings();
          if (d.deviceId == audioSettings["deviceId"]) {
            selectedAudioInput = d;
          }
        }
      } else if (d.kind == "audiooutput") {
        audioOutputDevices.add(d);
      } else if (d.kind == "videoinput") {
        videoInputDevices.add(d);
        if (videoTrack != null && videoTrack.isNotEmpty) {
          final videoSettings = videoTrack.first.getSettings();
          if (d.deviceId == videoSettings["deviceId"]) {
            selectedVideoInput = d;
          }
        }
      }
      print("${d.kind} ${d.label} ${d.kind} ${d.groupId}");
    }
  }



  void setMediaInputs({bool audio = false, bool video = false}){
    userAudio = audio;
    userVideo = video;

    if (_localStream != null) {
      _localStream?.getAudioTracks().forEach((t) => t.enabled = userAudio);
      _localStream?.getVideoTracks().forEach((t) => t.enabled = userVideo);
    }
  }

  Future<MediaStream> initLocalStream() async {
    if (_localStream != null) { await dispose(); }

    final constraints = <String, dynamic>{
      'audio': userAudio == true,
      'video': userVideo == true,
    };

    final stream = await navigator.mediaDevices.getUserMedia(constraints);

    _localStream = stream;


    return stream!;
  }

  Future<void> playRemoteAudio(MediaStream stream) async {
    final audioRenderer = RTCVideoRenderer();
    await audioRenderer.initialize();
    audioRenderer.srcObject = stream;
  }

  Future<void> dispose() async{
    for (final track in _localStream?.getTracks() ?? []){
      await track.stop();
    }
    await _localStream?.dispose();
    _localStream = null;
  }

  Future<List<MediaDeviceInfo>> getDeviceList() async {
    final devices = await navigator.mediaDevices.enumerateDevices();

    print('DEVICES LENGTH: ${devices.length}');
    for (final d in devices) {
      print('${d.kind} | ${d.label} | ${d.deviceId}');
    }
    return devices;
  }

}