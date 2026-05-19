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

  CallService(this._webSocket) : super(CallState());

  void startListen() {
    _subscription = _webSocket.callMessages.listen((message) {
      switch(message.type){

      }
    });
  }

  void configurePeer() {

  }

  Future<void> startCall() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    peerConnection = await createPeerConnection(configuration);

    peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
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

    final offer = await peerConnection!.createOffer();
    peerConnection!.setLocalDescription(offer);

    MessagePacket messagePacket = MessagePacket(type: "call_offer", payload: {"sdp": offer.sdp});

    _webSocket.sendRequest(messagePacket);
  }

  Future<void> answerCall(int callId) async {
    _webSocket.sendRequest(MessagePacket(type: "call_answer", payload: {"call_id": callId}));
  }

  Future<void> handleOffer(String sdp) async {

  }
}