import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';


final mediaCaptureServiceProvider = FutureProvider<CaptureService>((ref) async {
  final service = CaptureService();

  await service.initialize();

  navigator.mediaDevices.ondevicechange = ((event) async {
    service.devices = await service.getDeviceList();
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

  Future<void> initialize() async {

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });

    print("STREAM CREATED");

    await Future.delayed(Duration(seconds: 2));

    devices = await navigator.mediaDevices.enumerateDevices();

    print("DEVICES: ${devices.length}");

    for (final d in devices) {
      print("${d.kind} ${d.label}");
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

    print('DEVICES LENGTH: ${devices.length}');
    for (final d in devices) {
      print('${d.kind} | ${d.label} | ${d.deviceId}');
    }
    return devices;
  }

}