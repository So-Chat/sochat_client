//
//
// ITS FUTURE.....!
//
//

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sochat_client/modules/websocket/web_socket_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final callServiceProvider = StateNotifierProvider<CallService, CallState>((ref) {
  return CallService(ref.read(webSocketProvider));
});

class CallState {}

class CallService extends StateNotifier<CallState> {

  WebSocketService _webSocket;

  StreamSubscription? _subscription;

  CallService(this._webSocket) : super(CallState());

  void startListen() {
    _subscription = _webSocket.callMessages.listen((message) {
      switch(message.type){

      }
    });
  }
}