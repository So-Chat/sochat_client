import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

final mediaCaptureServiceProvider = Provider<CaptureService>((ref) {
  final service = CaptureService();

  navigator.mediaDevices.ondevicechange = ((event) async {
    if (event.runtimeType == MediaDeviceInfo) {
      service.devices = await service.getDeviceList();
    }
  });

  ref.onDispose(() => service.dispose());
  return service;
});

class CaptureService {

  MediaStream? _localStream;
  MediaStream? get localStream => _localStream;

  List<MediaDeviceInfo> devices = [];

  bool userAudio = true;
  bool userVideo = false;

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
    final audioRenderer = RTCVideoRenderer(); // он умеет и аудио
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

    for (final d in devices) {
      print('${d.kind} | ${d.label} | ${d.deviceId}');
    }

    return devices;
  }

}