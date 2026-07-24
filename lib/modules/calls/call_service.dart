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
import 'package:sochat_client/modules/calls/call_state.dart';
import 'package:sochat_client/modules/calls/turn_credentials.dart';
import 'package:sochat_client/modules/chats/chat.dart';
import 'package:sochat_client/modules/chats/chat_service.dart';
import 'package:sochat_client/modules/media_capture/capture_service.dart';
import 'package:sochat_client/modules/notifications/notifications_service.dart';
import 'package:sochat_client/modules/websocket/message_packet.dart';
import 'package:sochat_client/modules/websocket/web_socket_service.dart';
import 'package:sochat_client/so_ui/notifications/so_notification.dart';

import '../../so_ux/chat_controller.dart';

final callServiceProvider = FutureProvider<CallService>((ref) async {
  final capture = await ref.watch(mediaCaptureServiceProvider.future);

  ref.onDispose(() async {
    await capture.disposeLocalStream();
  });

  return CallService(
    await ref.read(webSocketProvider.future),
    capture,
    ref.read(chatsServiceProvider.notifier),
    ref.read(inAppNotificationsManagerProvider.notifier),
    ref,
  );
});

class CallService {
  final WebSocketService _webSocket;
  final CaptureService _captureService;
  final ChatService _chatService;

  final InAppNotificationsManager _inAppNotificationsManager;

  StreamSubscription? _subscription;

  RTCPeerConnection? peerConnection;
  RTCVideoRenderer? localRenderer;
  RTCVideoRenderer? remoteRenderer;

  Ref _ref;

  final List<RTCIceCandidate> _pendingCandidates = [];

  CallService(
    this._webSocket,
    this._captureService,
    this._chatService,
    this._inAppNotificationsManager,
    this._ref,
  ) {
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
      debugPrint(message.toJsonString());
      switch (message.type) {
        case "call_offer":
          {
            _inAppNotificationsManager.addUpdate(
              SoNotification(title: "Call incoming"),
            );
            Chat chat = _chatService.chatList.firstWhere(
              (c) => c.id == message.payload["chat_id"],
            );
            chat.callState = CallState.INCOMING;

            _chatService.addUpdate(chat);
            break;
          }
        case "call_answer":
          {
            handleAnswer(message.payload["sdp"], message.payload["chat_id"]);
            break;
          }
        case "call_ice":
          {
            handleIce(message.payload);
            break;
          }
        case "call_end":
          {
            handleCallEnd(message.payload);
            break;
          }
      }
    });
  }

  Future<RTCPeerConnection> createPeer(TurnCredentials turnCredentials) async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {
          "urls": [
            'turn:${turnCredentials.ip}:${turnCredentials.port}',
            'turn:${turnCredentials.ip}:${turnCredentials.port}?transport=udp',
          ],
          "username": turnCredentials.username,
          "credential": turnCredentials.credentials,
        },
      ],
    };

    final pc = await createPeerConnection(configuration);

    remoteRenderer = RTCVideoRenderer();
    localRenderer = RTCVideoRenderer();

    await remoteRenderer?.initialize();
    await localRenderer?.initialize();

    localRenderer?.srcObject = _captureService.localStream;

    if (_captureService.localStream == null) {
      print("NO LOCAL STREAM");
      throw Exception("NO LOCAL STREAM");
    }

    for (var track in _captureService.localStream!.getTracks()) {
      await pc.addTrack(track, _captureService.localStream!);
    }

    pc.onTrack = (RTCTrackEvent event) async {
      if (event.track.kind == 'audio' || event.track.kind == 'video') {
        event.track.enabled = true;
        if (event.streams.isNotEmpty && remoteRenderer != null) {
          remoteRenderer!.srcObject = event.streams.first;

          if (_captureService.selectedAudioOutput?.deviceId != null) {
            await remoteRenderer!.audioOutput(
              _captureService.selectedAudioOutput!.deviceId,
            );
          }
        }
      }
    };
    pc.onIceConnectionState = (error) {
      print("ICE: $error");
    };

    pc.onConnectionState = (state) {
      print(state);
    };

    pc.onIceCandidate = (RTCIceCandidate? candidate) {
      if (candidate == null) return;

      print(candidate.toMap());
      _webSocket.addToSink(
        MessagePacket(
          type: "call_ice",
          payload: {
            'candidate': candidate.candidate,
            'sdp_mid': candidate.sdpMid,
            'sdp_mline_index': candidate.sdpMLineIndex,
          },
        ).toJson(),
      );
    };

    return pc;
  }

  Future<void> startCall(int userId, int chatId) async {
    try {
      await _captureService.initializeLocalStream(
        audioId: _captureService.selectedAudioInput!.deviceId,
        //videoId: _captureService.selectedVideoInput!.deviceId,
      );
      TurnCredentials turnCredentials = await getCredentials();

      peerConnection = await createPeer(turnCredentials);

      final MessagePacket checkResult = await _webSocket.sendRequest(
        MessagePacket(
          type: "call_check",
          payload: {"chat_id": chatId, "user_id": userId},
        ),
      );
      if (checkResult.payload["sdp"] != null) {
        await handleOffer(checkResult.payload["sdp"], chatId);
        return;
      } else {
        if (checkResult.payload["success"] == false) {
          throw Exception(checkResult.payload["server_message"]);
        }

        final offer = await peerConnection!.createOffer();
        await peerConnection!.setLocalDescription(offer);

        MessagePacket messagePacket = MessagePacket(
          type: "call_offer",
          payload: {"sdp": offer.sdp, "user_id": userId, "chat_id": chatId},
        );

        final request = await _webSocket.sendRequest(messagePacket);
        if (request.payload["success"] == false) {
          throw Exception(request.payload["server_message"]);
        }
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> handleOffer(String sdp, int chatId) async {
    await _captureService.initializeLocalStream(
      audioId: _captureService.selectedAudioInput!.deviceId,
      //videoId: _captureService.selectedVideoInput!.deviceId,
    );

    TurnCredentials turnCredentials = await getCredentials();

    peerConnection = await createPeer(turnCredentials);

    if (peerConnection == null) {
      throw Exception("peerConnection is null");
    }

    await peerConnection!.setRemoteDescription(
      RTCSessionDescription(sdp, "offer"),
    );

    Chat chat = _chatService.chatList.firstWhere(
      (c) => c.id == chatId,
    );
    chat.callState = CallState.IN_CALL;

    _chatService.addUpdate(chat);

    for (final c in _pendingCandidates) {
      await peerConnection!.addCandidate(c);
    }
    _pendingCandidates.clear();

    final answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);

    MessagePacket messagePacket = MessagePacket(
      type: "call_answer",
      payload: {"sdp": answer.sdp},
    );
    _webSocket.addToSink(messagePacket.toJson());
  }

  Future<void> handleAnswer(String sdp, int chatId) async {
    if (peerConnection == null) {
      throw Exception("peerConnection is null");
    }

    await peerConnection!.setRemoteDescription(
      RTCSessionDescription(sdp, "answer"),
    );

    Chat chat = _chatService.chatList.firstWhere(
      (c) => c.id == chatId,
    );
    chat.callState = CallState.IN_CALL;

    _chatService.addUpdate(chat);

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

    if (peerConnection == null ||
        peerConnection!.getRemoteDescription == null) {
      _pendingCandidates.add(candidateIce);
      return;
    }

    await peerConnection!.addCandidate(candidateIce);
  }

  Future<void> callEnd() async {
    _webSocket.addToSink(MessagePacket(type: "call_end", payload: {}).toJson());
  }

  Future<void> handleCallEnd(Map<String, dynamic> payload) async {
    if (payload["success"] != true) return;

    try {
      if (peerConnection != null) {
        try {
          var transceivers = await peerConnection!.getTransceivers();
          for (var transceiver in transceivers) {
            await transceiver.stop();
          }
          var receivers = await peerConnection!.getReceivers();
          for (var receiver in receivers) {
            await receiver.track?.stop();
          }

          var senders = await peerConnection!.getSenders();
          for (var sender in senders) {
            await sender.track?.stop();
          }
        } catch (e) {
          print("Error stopping peer connection tracks/transceivers: $e");
        }
      }

      final localStream = localRenderer?.srcObject;
      if (localRenderer != null) localRenderer!.srcObject = null;

      final remoteStream = remoteRenderer?.srcObject;
      if (remoteRenderer != null) remoteRenderer!.srcObject = null;

      if (localStream != null) {
        for (var track in localStream.getTracks()) {
          await track.stop();
        }
      }
      if (remoteStream != null) {
        for (var track in remoteStream.getTracks()) {
          await track.stop();
        }
      }

      if (peerConnection != null) {
        try {
          await peerConnection!.close();
          await peerConnection!.dispose();
        } catch (e) {
          print("PeerConnection close/dispose error: $e");
        }
      }

      await localRenderer?.dispose();
      await remoteRenderer?.dispose();
    } catch (e) {
      print("Caught error: $e");
    } finally {
      remoteRenderer = null;
      localRenderer = null;
      peerConnection = null;
    }

    // Change chat call state
    Chat chat = _chatService.chatList.firstWhere(
      (c) => c.id == payload["chat_id"],
    );
    chat.callState = CallState.IDLE;

    _chatService.addUpdate(chat);
    _ref.read(isInCallProvider.notifier).state = false;
  }

  Future<TurnCredentials> getCredentials() async {
    final request = await _webSocket.sendRequest(
      MessagePacket(type: "turn_credentials_get", payload: {}),
    );
    return TurnCredentials(
      request.payload["username"],
      request.payload["credential"],
      request.payload["turn_ip"],
      request.payload["turn_port"],
    );
  }
}
