import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sochat_client/modules/calls/call_service.dart';
import 'package:sochat_client/modules/calls/call_state.dart';
import 'package:sochat_client/modules/chats/chat.dart';
import 'package:sochat_client/modules/chats/chat_type.dart';
import 'package:sochat_client/modules/common/auth_service.dart';
import 'package:sochat_client/modules/media_capture/capture_service.dart';

import 'chat_controller.dart';

final callControllerProvicer = FutureProvider<CallController>((ref) async {
  return CallController(
    await ref.read(callServiceProvider.future),
    await ref.read(mediaCaptureServiceProvider.future),
    ref,
  );
});

class CallController {
  final CallService _callService;
  final CaptureService _captureService;
  final Ref _ref;

  bool get userAudio => _captureService.userAudio;

  bool get userVideo => _captureService.userVideo;

  RTCVideoRenderer? get localRenderer => _callService.localRenderer;
  RTCVideoRenderer? get remoteRenderer => _callService.remoteRenderer;

  CallController(this._callService, this._captureService, this._ref);

  void callEnd() {
    _callService.callEnd();
  }

  Future<void> callStartReturn(Chat chat) async {
    final currentUser = _ref.read(currentUserProvider);

    if (chat!.type == ChatType.PRIVATE) {
      try {
        if (chat.callState == CallState.IDLE || chat.callState == CallState.INCOMING) {
          await _callService.startCall(
            chat.participants.firstWhere((p) => p.user.id != currentUser!.id).user.id,
            chat.id,
          );
        } else {
          _ref.read(isInCallProvider.notifier).state = true;
        }
      } catch (e) {
        _ref.read(isInCallProvider.notifier).state = false;
        _callService.handleCallEnd(Map());
      }
    }
  }

  void setMediaInputs({bool? audio, bool? video}) {
    _captureService.userAudio = audio ?? userAudio;
    _captureService.userVideo = video ?? userVideo;
    _captureService.setMediaInputs(audio: userAudio, video: userVideo);
  }
}
