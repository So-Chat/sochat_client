
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sochat_client/main.dart';
import 'package:sochat_client/modules/common/auth_service.dart';
import 'package:sochat_client/modules/common/local_storage_service.dart';
import 'package:sochat_client/modules/keys/key_service.dart';
import 'package:sochat_client/modules/websocket/message_packet.dart';
import 'package:sochat_client/modules/websocket/web_socket_service.dart';
import 'package:sochat_client/so_ui/chatscreen/chat_screen.dart';
import 'package:sochat_client/so_ui/common/so_exception.dart';

import '../modules/notifications/notifications_service.dart';

final loginControllerProvider = StateNotifierProvider<LoginController, LoginControllerState>((ref) {
  final authService = ref.read(authServiceProvider);
  final keyService = ref.read(keyServiceProvider.notifier);

  return LoginController(authService, keyService, ref);
});


class LoginControllerState {

}

class LoginController extends StateNotifier<LoginControllerState> {
  final AuthService _authService;
  final KeyService _keyService;
  final Ref _ref;

  LoginController(this._authService, this._keyService, this._ref) : super(LoginControllerState());

  Future<void> login(
      BuildContext context,
      String username,
      int profileIndex,
      int serverIndex,
      WidgetRef widgetRef
      ) async {

    if (username == ""){
      throw SoException("Username can't be null!");
    }
    else if (username.contains(" ")){
      throw SoException("Username can't contain spaces!");
    }

    final ip = _keyService.servers.entries.toList()[serverIndex].value;
    final profile = _keyService.profiles.entries.toList()[profileIndex].value;


    try{
      MessagePacket response = await _authService.login(
          context,
          username,
          profile,
          ip,
          widgetRef);

      if (response.payload["success"]){
        MessagePacket verifyResponse = await _authService.verify(
            context, username,
            profile,
            response.payload["challenge"].toString(),
            ip,
            widgetRef);
        if (!verifyResponse.payload["success"]) {
          throw Exception(response.payload["server_message"]);
        }
        await _verify(context, verifyResponse, widgetRef);
      }
      else {
        throw Exception(response.payload["server_message"]);
      }
    } catch (e) {
      rethrow;
    }

  }

  Future<void> _verify(BuildContext context, MessagePacket messagePacket, WidgetRef ref) async {
    final webSocketService = await ref.read(webSocketProvider.future);
    webSocketService.connect();

    _authService.token = messagePacket.payload["token"];
    await webSocketService.authenticate(messagePacket.payload["token"]);

    ref.read(localStorageServiceProvider.notifier).saveSession();

    Navigator.push(
        context, MaterialPageRoute(builder: (context) => ChatScreen()));
  }

  Future<void> authenticateWithActiveSession(BuildContext context, WidgetRef ref) async{
    final webSocketService = await ref.read(webSocketProvider.future);
    webSocketService.connect();

    String token = await ref.read(localStorageServiceProvider.notifier).getSessionAndSetSelectedKeys();
    print("got token");

    _authService.token = token;

    await webSocketService.authenticate(token);

    Navigator.push(
        context, MaterialPageRoute(builder: (context) => ChatScreen()));
  }


  Future<void> register(BuildContext context, String username, int profileIndex, int serverIndex, WidgetRef widgetRef) async {
    _authService.register(username,
        _keyService.profiles.entries.toList()[profileIndex].value,
        _keyService.servers.entries.toList()[serverIndex].value);
    await _authService.login(context, username,
        _keyService.profiles.entries.toList()[profileIndex].value,
        _keyService.servers.entries.toList()[serverIndex].value, widgetRef);
  }

  Future<void> logout(BuildContext context) async {
    final oldContainer = containerHolder.value;

    oldContainer.read(localStorageServiceProvider.notifier).removeSession();

    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ValueListenableBuilder(
          valueListenable: containerHolder,
          builder: (context, container, _) {
            container.read(notificationsProvider);
            container.read(webSocketProvider);
            return UncontrolledProviderScope(
              container: container,
              child: const SoChat(),
            );
          },
        ),
      ),
          (route) => false,
    );


    Future.microtask(() async {
      (await oldContainer.read(webSocketProvider.future)).disconnect();
      oldContainer.dispose();
      containerHolder.value = ProviderContainer();
    });
  }
}