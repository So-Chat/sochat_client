import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallMediaState {
  final RTCVideoRenderer? localRenderer;
  final RTCVideoRenderer? remoteRenderer;
  final bool hasLocalVideo;
  final bool hasRemoteVideo;

  const CallMediaState({
    this.localRenderer,
    this.remoteRenderer,
    this.hasLocalVideo = false,
    this.hasRemoteVideo = false,
  });

  Future<void> dispose() async {
    await localRenderer?.dispose();
    await remoteRenderer?.dispose();
  }

  CallMediaState copyWith({
    RTCVideoRenderer? localRenderer,
    RTCVideoRenderer? remoteRenderer,
    bool? hasLocalVideo,
    bool? hasRemoteVideo,
  }) {
    return CallMediaState(
      localRenderer: localRenderer ?? this.localRenderer,
      remoteRenderer: remoteRenderer ?? this.remoteRenderer,
      hasLocalVideo: hasLocalVideo ?? this.hasLocalVideo,
      hasRemoteVideo: hasRemoteVideo ?? this.hasRemoteVideo,
    );
  }
}
