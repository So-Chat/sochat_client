//
//
// ITS FUTURE.....!
//
//

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sochat_client/context/notifications/inapp_notifications_manager.dart';
import 'package:sochat_client/modules/chats/chat_service.dart';
import 'package:sochat_client/modules/media_capture/capture_service.dart';
import 'package:sochat_client/modules/notifications/notifications_service.dart';
import 'package:sochat_client/modules/websocket/message_packet.dart';
import 'package:sochat_client/modules/websocket/web_socket_service.dart';
import 'package:sochat_client/so_ui/notifications/so_notification.dart';

final callServiceProvider = FutureProvider<CallService>((ref) async {
  final capture = await ref.watch(mediaCaptureServiceProvider.future);

  ref.onDispose(() async {
    await capture.dispose();
  });

  return CallService(await ref.read(webSocketProvider.future), capture, ref.read(chatsServiceProvider.notifier), ref.read(inAppNotificationsManagerProvider.notifier));
});

class CallService {

  final WebSocketService _webSocket;
  final CaptureService _captureService;
  final ChatService _chatService;

  final InAppNotificationsManager _inAppNotificationsManager;

  StreamSubscription? _subscription;

  RTCPeerConnection? peerConnection;
  RTCVideoRenderer? localRenderer;

  final List<RTCIceCandidate> _pendingCandidates = [];

  CallService(this._webSocket, this._captureService, this._chatService, this._inAppNotificationsManager) {
    startListen();
  }

  void dispose() {
    _subscription?.cancel();
    peerConnection?.dispose();
    localRenderer?.dispose();
  }

  // TODO: SET SPEAKER, ITS REALLY IMPORTANT

  void startListen() {
    _subscription = _webSocket.callMessages.listen((message) {
      print(message);
      switch(message.type){
        case "call_offer": {
          _inAppNotificationsManager.addUpdate(SoNotification(title: "Call incoming"));
          _chatService.chatList.firstWhere((c) => c.id == message.payload["chat_id"]).inCall = true;
          //answerCall(message.payload["chatId"]);
          break;
        }
        case "call_answer": { handleAnswer(message.payload["sdp"]); break; }
        case "call_accept": { handleOffer(message.payload["sdp"]); break; }
        case "call_ice": {
          handleIce(message.payload);
          break;
        }
      }
    });
  }

  Future<RTCPeerConnection> createPeer() async {

    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    final pc = await createPeerConnection(configuration);
    final renderer = RTCVideoRenderer();

    await renderer.initialize();

    renderer.audioOutput(_captureService.selectedAudioOutput!.deviceId);

    if (_captureService.localStream == null) {
      throw Exception("NO LOCAL STREAM");
    }
    for (var track in _captureService.localStream!.getTracks()) {
      await pc.addTrack(track, _captureService.localStream!);
    }

    pc.onTrack = (RTCTrackEvent event) async {
      if (event.streams.isNotEmpty) {
        renderer.srcObject = event.streams.first;
        if (event.track.kind == 'audio') {
          event.track.enabled = true;
        }
      }
    };

    pc.onIceConnectionState = (state) {
      print("ICE connection state: $state");
    };
    pc.onConnectionState = (state) {
      print("Peer connection state: $state");
    };

    pc.onIceGatheringState = (state) {
      print('ICE gathering: $state');
    };

    pc.onSignalingState = (state) {
      print('Signaling: $state');
    };

    pc.onConnectionState = (state) {
      print("PC STATE: $state");
    };

    pc.onIceConnectionState = (error) {
      print("ICE: $error");
    };

    pc.onIceCandidate = (RTCIceCandidate? candidate) {
      if (candidate == null) return;

      print(candidate.toMap());
      _webSocket.addToSink(MessagePacket(
        type: "call_ice",
        payload: {
          'candidate': candidate.candidate,
          'sdp_mid': candidate.sdpMid,
          'sdp_mline_index': candidate.sdpMLineIndex,
        },
      ).toJson());
    };

    return pc;
  }

  Future<void> startCall(int userId) async {
    //await _captureService.initialize(audioId: _captureService.selectedAudioInput!.deviceId);


    //localRenderer = RTCVideoRenderer();
    //localRenderer!.srcObject = _captureService.localStream;

    peerConnection = await createPeer();

    final offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    MessagePacket messagePacket = MessagePacket(type: "call_offer", payload: {"sdp": offer.sdp, "callee_id": userId});

    _webSocket.addToSink(messagePacket.toJson());
  }

  Future<void> answerCall(int callId) async {
    _webSocket.addToSink(MessagePacket(type: "call_accept", payload: {"call_id": callId}).toJson());
  }

  Future<void> handleOffer(String sdp) async {
    //await _captureService.initialize(audioId: _captureService.selectedAudioInput!.deviceId);
    peerConnection = await createPeer();


    if (peerConnection == null) { throw Exception("peerConnection is null"); }

    await peerConnection!.setRemoteDescription(RTCSessionDescription(sdp, "offer"));

    for (final c in _pendingCandidates) {
      await peerConnection!.addCandidate(c);
    }
    _pendingCandidates.clear();

    final answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);

    MessagePacket messagePacket = MessagePacket(type: "call_answer", payload: {"sdp":answer.sdp});
    _webSocket.addToSink(messagePacket.toJson());
  }

  Future<void> handleAnswer(String sdp) async {
    if (peerConnection == null) { throw Exception("peerConnection is null"); }

    await peerConnection!.setRemoteDescription(RTCSessionDescription(sdp, "answer"));
    for (final c in _pendingCandidates) {
      await peerConnection!.addCandidate(c);
    }
    _pendingCandidates.clear();
  }

  Future<void> handleIce(Map<String, dynamic> payload) async {
    final candidateIce = RTCIceCandidate(
      payload['candidate']?.toString(),
      payload['sdp_mid']?.toString(),
      payload['sdp_mline_index'] is int
          ? payload['sdp_mline_index']
          : int.tryParse(payload['sdp_mline_index']?.toString() ?? '0'),
    );

    if (peerConnection == null) {
      _pendingCandidates.add(candidateIce);
      return;
    }
    final remoteDesc = await peerConnection!.getRemoteDescription();
    if (remoteDesc == null) {
      _pendingCandidates.add(candidateIce);
      return;
    }

    await peerConnection!.addCandidate(candidateIce);
  }

  Future<void> handleCallEnd() async {
    final request = await _webSocket.sendRequest(MessagePacket(type: "call_end", payload: {}));
    if (request.payload["success"] == "true") {

    }
  }
}