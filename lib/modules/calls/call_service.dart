//
//
// ITS FUTURE.....!
//
//

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sochat_client/modules/websocket/message_packet.dart';
import 'package:sochat_client/modules/websocket/web_socket_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final callServiceProvider = StateNotifierProvider<CallService, CallState>((ref) {
  return CallService(ref.read(webSocketProvider));
});

class CallState {}

class CallService extends StateNotifier<CallState> {

  WebSocketService _webSocket;

  StreamSubscription? _subscription;

  RTCPeerConnection? peerConnection;

  CallService(this._webSocket)
      : super(CallState()) {
    startListen();
  }

  void startListen() {
    _subscription = _webSocket.callMessages.listen((message) {
      switch(message.type){
        case "call_offer": { answerCall(message.payload["userId"]); break; }
        case "call_accept": { handleOffer(message.payload["sdp"]); break; }
        case "call_ice": { handleIce(message.payload); break; }
        case "call_end": {
          // TODO: Do something other than just print
          print("CALL END"); break;
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

    pc.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        final stream = event.streams.first;
        // TODO: Configure video and audio here duh
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

    pc.onIceCandidate = (RTCIceCandidate? candidate) {
      if (candidate == null) return;

      print(candidate.toMap());
      _webSocket.sendRequest(MessagePacket(
        type: "ice_candidate",
        payload: {
          'candidate': candidate.candidate,
          'sdp_mid': candidate.sdpMid,
          'sdp_mline_index': candidate.sdpMLineIndex,
        },
      ));
    };

    return pc;
  }

  Future<void> startCall(int userId) async {
    peerConnection = await createPeer();

    final offer = await peerConnection!.createOffer();
    peerConnection!.setLocalDescription(offer);

    MessagePacket messagePacket = MessagePacket(type: "call_offer", payload: {"sdp": offer.sdp, "callee_id": userId});

    _webSocket.sendRequest(messagePacket);
  }

  Future<void> answerCall(int callId) async {
    _webSocket.sendRequest(MessagePacket(type: "call_accept", payload: {"call_id": callId}));
  }

  Future<void> handleOffer(String sdp) async {

    peerConnection = await createPeer();

    if (peerConnection == null) { throw Exception("peerConnection is null"); }

    await peerConnection!.setRemoteDescription(RTCSessionDescription(sdp, "offer"));

    final answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);

    MessagePacket messagePacket = MessagePacket(type: "call_answer", payload: {"sdp":answer.sdp});
    _webSocket.sendRequest(messagePacket);
  }

  Future<void> handleAnswer(String sdp) async {
    if (peerConnection == null) { throw Exception("peerConnection is null"); }

    await peerConnection!.setRemoteDescription(RTCSessionDescription(sdp, "answer"));
  }

  Future<void> handleIce(Map<String, dynamic> payload) async {
    if (peerConnection == null) { throw Exception("peerConnection is null"); }

    final candidateIce = RTCIceCandidate(
      payload['candidate']?.toString(),
      payload['sdp_mid']?.toString(),
      payload['sdp_mline_index'] is int
          ? payload['sdp_mline_index']
          : int.tryParse(payload['sdp_mline_index']?.toString() ?? '0'),
    );
    await peerConnection!.addCandidate(candidateIce);
  }
}