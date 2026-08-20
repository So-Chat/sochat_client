//
//
// ITS FUTURE.....!
//
//

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sochat_client/modules/calls/call_event.dart';
import 'package:sochat_client/modules/calls/call_media_state.dart';
import 'package:sochat_client/modules/calls/call_state.dart';
import 'package:sochat_client/modules/calls/turn_credentials.dart';
import 'package:sochat_client/modules/chats/chat.dart';
import 'package:sochat_client/modules/chats/chat_service.dart';
import 'package:sochat_client/modules/media_capture/capture_service.dart';
import 'package:sochat_client/modules/users/user_service.dart';
import 'package:sochat_client/modules/websocket/message_packet.dart';
import 'package:sochat_client/modules/websocket/web_socket_service.dart';

final callServiceProvider = FutureProvider<CallService>((ref) async {
  final capture = await ref.watch(mediaCaptureServiceProvider.future);

  ref.onDispose(() async {
    await capture.disposeLocalStream();
  });

  return CallService(
    await ref.read(webSocketProvider.future),
    capture,
    ref.read(chatsServiceProvider.notifier),
    ref,
  );
});

final mediaStateProvider = StateProvider<CallMediaState?>((ref) => null);

class CallService {
  final WebSocketService _webSocket;
  final CaptureService _captureService;
  final ChatService _chatService;

  StreamSubscription? _subscription;

  RTCPeerConnection? peerConnection;

  Ref _ref;

  final List<RTCIceCandidate> _pendingCandidates = [];
  final lastRTCState = ValueNotifier<String?>(null);

  final _callEventController = StreamController<CallEvent>.broadcast();
  Stream<CallEvent> get callEvents => _callEventController.stream;

  CallService(
    this._webSocket,
    this._captureService,
    this._chatService,
    this._ref,
  ) {
    startListen();
  }

  void dispose() {
    _subscription?.cancel();
    peerConnection?.dispose();
    _ref.read(mediaStateProvider.notifier).state?.dispose();
  }

  void updateLastRTCState(String? text) {
    lastRTCState.value = text;
  }

  void _updateMediaState(CallMediaState Function(CallMediaState state) update) {
    final notifier = _ref.read(mediaStateProvider.notifier);
    final current = notifier.state;

    if (current != null) {
      notifier.state = update(current);
    }
  }

  // TODO: SET SPEAKER, ITS REALLY IMPORTANT
  void startListen() {
    _subscription = _webSocket.callMessages.listen((message) {
      debugPrint(message.toJsonString());
      switch (message.type) {
        case "call_offer":
          {
            _callEventController.add(
              CallEvent("new_call", message.payload["chat_id"]),
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
            handleAnswer(message.payload["sdp"], message.payload["chat_id"], message.payload["user_id"]);
            break;
          }
        case "call_ice":
          {
            handleIce(message.payload);
            break;
          }
        case "call_end":
          {
            handleCallEnd(message.payload["chat_id"]);
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

    final localRenderer = RTCVideoRenderer();
    final remoteRenderer = RTCVideoRenderer();

    await localRenderer.initialize();
    await remoteRenderer.initialize();

    localRenderer.srcObject = _captureService.localStream;
    remoteRenderer.onFirstFrameRendered = () {
      _updateMediaState((state) => state.copyWith(hasRemoteVideo: true));
    };

    _ref.read(mediaStateProvider.notifier).state = CallMediaState(
      localRenderer: localRenderer,
      remoteRenderer: remoteRenderer,
      hasLocalVideo:
          _captureService.localStream?.getVideoTracks().isNotEmpty == true,
    );

    if (_captureService.localStream == null) {
      debugPrint("NO LOCAL STREAM");
      throw Exception("NO LOCAL STREAM");
    }

    for (var track in _captureService.localStream!.getTracks()) {
      await pc.addTrack(track, _captureService.localStream!);
    }

    pc.onTrack = (RTCTrackEvent event) async {
      final stream = event.streams.firstOrNull;
      if (stream == null) return;

      if (event.track.kind == 'audio' || event.track.kind == 'video') {
        event.track.enabled = true;
        if (event.streams.isNotEmpty &&
            _ref.read(mediaStateProvider.notifier).state!.remoteRenderer !=
                null) {
          _ref
                  .read(mediaStateProvider.notifier)
                  .state!
                  .remoteRenderer!
                  .srcObject =
              event.streams.first;

          if (_captureService.selectedAudioOutput?.deviceId != null) {
            await _ref
                .read(mediaStateProvider.notifier)
                .state!
                .remoteRenderer!
                .audioOutput(_captureService.selectedAudioOutput!.deviceId);
          }
        }
        if (event.track.kind == 'video') {
          _updateMediaState((state) => state.copyWith(hasRemoteVideo: true));
        }
      }
    };
    pc.onIceConnectionState = (error) {
      debugPrint("ICE: $error");
      updateLastRTCState(error.name);
    };
    pc.onConnectionState = (state) {
      debugPrint("$state");
      updateLastRTCState(state.name);
    };
    pc.onIceGatheringState = (state) {
      debugPrint("$state");
      updateLastRTCState(state.name);
    };
    pc.onSignalingState = (state) {
      debugPrint("$state");
      updateLastRTCState(state.name);
    };

    pc.onIceCandidate = (RTCIceCandidate? candidate) {
      if (candidate == null) return;

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

  Future<void> startCall(
    int userId,
    int chatId, {
    bool withVideo = false,
  }) async {
    try {
      await _captureService.initializeLocalStream(
        audio: true,
        video: withVideo,
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

        _webSocket.addToSink(messagePacket.toJson());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> handleOffer(
    String sdp,
    int chatId, {
    bool withVideo = false,
  }) async {
    await _captureService.initializeLocalStream(audio: true, video: withVideo);

    TurnCredentials turnCredentials = await getCredentials();

    peerConnection = await createPeer(turnCredentials);

    if (peerConnection == null) {
      throw Exception("peerConnection is null");
    }

    await peerConnection!.setRemoteDescription(
      RTCSessionDescription(sdp, "offer"),
    );

    Chat chat = _chatService.chatList.firstWhere((c) => c.id == chatId);
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

  Future<void> handleAnswer(String sdp, int chatId, int userId) async {
    if (peerConnection == null) {
      throw Exception("peerConnection is null");
    }

    final user = await _ref.read(userServiceProvider).getUser(id: userId);
    _callEventController.add(CallEvent("user_joined", user));

    await peerConnection!.setRemoteDescription(
      RTCSessionDescription(sdp, "answer"),
    );

    Chat chat = _chatService.chatList.firstWhere((c) => c.id == chatId);
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

    final remoteDescriptionSet = await peerConnection!.getRemoteDescription();

    if (peerConnection == null || remoteDescriptionSet == null) {
      _pendingCandidates.add(candidateIce);
      return;
    }

    await peerConnection!.addCandidate(candidateIce);
  }

  Future<void> callEnd(int chatId) async {
    _webSocket.addToSink(
      MessagePacket(type: "call_end", payload: {}).toJson(),
    );
    await handleCallEnd(chatId);
  }

  Future<void> handleCallEnd(int chatId) async {
    updateLastRTCState(null);
    final mediaNotifier = _ref.read(mediaStateProvider.notifier);
    final mediaState = mediaNotifier.state;

    // Change chat call state
    Chat chat = _chatService.chatList.firstWhere((c) => c.id == chatId);
    chat.callState = CallState.IDLE;

    _chatService.addUpdate(chat);

    if (peerConnection == null) {
      return;
    }

    try {
      /*if (peerConnection != null) {
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
      }*/

      final localStream = mediaState!.localRenderer?.srcObject;
      if (mediaState.localRenderer != null) {
        mediaState.localRenderer!.srcObject = null;
      }
      final remoteStream = mediaState.remoteRenderer?.srcObject;
      if (mediaState.remoteRenderer != null) {
        mediaState.remoteRenderer!.srcObject = null;
      }
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
          debugPrint("PeerConnection close/dispose error: $e");
          rethrow;
        }
      }

      _ref.read(mediaStateProvider.notifier).state?.dispose();
    } catch (e) {
      debugPrint("Caught error: $e");
      rethrow;
    } finally {
      _ref.read(mediaStateProvider.notifier).state = null;
      peerConnection = null;
    }
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
