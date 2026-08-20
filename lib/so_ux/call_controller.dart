import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/context/notifications/inapp_notifications_manager.dart';
import 'package:sochat_client/modules/calls/call_service.dart';
import 'package:sochat_client/modules/calls/call_session.dart';
import 'package:sochat_client/modules/calls/call_state.dart';
import 'package:sochat_client/modules/chats/chat_type.dart';
import 'package:sochat_client/modules/common/auth_service.dart';
import 'package:sochat_client/modules/media_capture/capture_service.dart';
import 'package:sochat_client/modules/users/user.dart';
import 'package:sochat_client/so_ui/notifications/so_notification.dart';

import 'chat_controller.dart';

final callControllerProvider = AsyncNotifierProvider<CallController, CallControllerState>(
  CallController.new,
);

const _unset = Object();

class CallControllerState {
  final bool isInCall;
  final CallSession? callSession;

  const CallControllerState({
    this.isInCall = false,
    this.callSession,
  });

  CallControllerState copyWith({
    bool? isInCall,
    Object? callSession = _unset,
  }) {
    return CallControllerState(
      isInCall: isInCall ?? this.isInCall,
      callSession: callSession == _unset
          ? this.callSession
          : callSession as CallSession?,
    );
  }
}

class CallController extends AsyncNotifier<CallControllerState> {
  late final CallService _callService;
  late final CaptureService _captureService;

  bool get userAudio => _captureService.userAudio;
  bool get userVideo => _captureService.userVideo;
  ValueNotifier<String?> get lastRTCState => _callService.lastRTCState;

  bool get isInCall => state.value?.isInCall ?? false;
  CallSession? get callSession => state.value?.callSession;
  CallControllerState get currentState => state.requireValue;

  @override
  Future<CallControllerState> build() async {
    _callService = await ref.read(callServiceProvider.future);

    _captureService = await ref.read(mediaCaptureServiceProvider.future);

    startListen();

    return const CallControllerState();
  }


  void startListen() {
    _callService.callEvents.listen((event) {
      if (event.type == "new_call") {
        ref
            .read(inAppNotificationsManagerProvider.notifier)
            .addUpdate(SoNotification(title: "Call incoming"));
      }
      if (event.type == "user_joined") {
        final callSession = state.value?.callSession;
        if (callSession != null) {
          final inCallUsers = callSession.inCallUsers;
          inCallUsers.add(event.data! as User);
          setCallSession(callSession.copyWith(
            inCallUsers: inCallUsers,
          ));
        }
      }
    });
  }

  void setIsInCall(bool isInCall) {
    state = AsyncData(
      currentState.copyWith(
        isInCall: true,
      ),
    );
  }
  void setCallSession(CallSession? callSession) {
    state = AsyncData(
      currentState.copyWith(
        callSession: callSession,
      ),
    );
  }


  void callEnd() {
    final chatId = callSession?.chatId;
    if (chatId != null) {
      _callService.callEnd(chatId);
      setCallSession(null);
      setIsInCall(false);
    }
  }

  Future<void> callStart({bool video = false}) async {
    final currentUser = ref.read(authServiceProvider).currentUser;
    final selectedChat = ref.read(chatControllerProvider).selectedChat;
    if (selectedChat == null) {
      return;
    }

    final callSession = state.value?.callSession;

    if (selectedChat.type == ChatType.PRIVATE) {
      try {
        if (selectedChat.callState == CallState.IDLE ||
            selectedChat.callState == CallState.INCOMING) {
          setCallSession(CallSession(
            chatId: selectedChat.id,
            inCallUsers: [ref.read(authServiceProvider).currentUser!],
            isVideo: video,
          ));
          setIsInCall(true);
          await _callService.startCall(
            selectedChat.participants
                .firstWhere((p) => p.user.id != currentUser!.id)
                .user
                .id,
            selectedChat.id,
            withVideo: video,
          );
        } else {
          setIsInCall(true);
        }
      } catch (e) {
        setIsInCall(false);
        if (callSession?.chatId != null) {
          _callService.handleCallEnd(callSession!.chatId);
        }
        setCallSession(null);
        throw e;
      }
    }
  }

  void setMediaInputs({bool? audio, bool? video}) {
    _captureService.setMediaInputs(
      audio: audio ?? userAudio,
      video: video ?? userVideo,
    );
  }
}
