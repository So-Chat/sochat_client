import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sochat_client/modules/calls/call_service.dart';
import 'package:sochat_client/modules/media_capture/capture_service.dart';

import 'chat_controller.dart';

final callControllerProvicer = FutureProvider<CallController>((ref) async {
  return CallController(await ref.read(callServiceProvider.future), await ref.read(mediaCaptureServiceProvider.future), ref);
});

class CallController {
  final CallService _callService;
  final CaptureService _captureService;
  final Ref _ref;

  bool get userAudio =>
      _captureService.userAudio;

  bool get userVideo =>
      _captureService.userVideo;

  RTCVideoRenderer? get localRenderer => _callService.localRenderer;
  RTCVideoRenderer? get remoteRenderer => _callService.remoteRenderer;

  CallController(this._callService, this._captureService, this._ref);

  void callEnd() {
    _callService.callEnd();
  }

  void setMediaInputs({bool? audio, bool? video}) {
    _captureService.userAudio = audio ?? userAudio;
    _captureService.userVideo = video ?? userVideo;
    _captureService.setMediaInputs(audio: userAudio, video: userVideo);
  }
}