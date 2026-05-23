import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:sochat_client/modules/keys/key.dart';
import 'package:sochat_client/modules/websocket/message_packet.dart';
import 'package:sochat_client/modules/users/user.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final currentUserProvider = StateProvider<User?>((ref) => null);

class AuthService {
  String? token;

  Future<MessagePacket> login(
      BuildContext context,
      String username,
      KeyP keyPair,
      String ip, WidgetRef ref) async {

      var url = Uri.parse(('$ip/auth/login?username=$username').toString());
      var response = await http.get(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print("hello?");
      print(response.body);

      var mapResponse = jsonDecode(response.body) as Map<String, dynamic>;

      return MessagePacket.fromJson(mapResponse);
  }

  Future<MessagePacket> verify(BuildContext context,
      String username, KeyP keyPair,
      String challenge, ip, WidgetRef ref) async {

      var signature = await keyPair.sign(utf8.encode(challenge));
      var signatureBase64 = base64Encode(signature);

      MessagePacket packet = MessagePacketBuilder()
          .type("verify")
          .put("username", username)
          .put("signature", signatureBase64)
          .put("challenge", challenge)
          .build();

      var url = Uri.parse((ip + '/auth/verify').toString());
      var response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(packet.toJson()),
      );

      var mapResponse = jsonDecode(response.body) as Map<String, dynamic>;
      return MessagePacket.fromJson(mapResponse);
  }


  Future<void> register(
      String username,
      KeyP keyPair,
      String ip) async {
    var url = Uri.parse(('$ip/auth/register').toString());


    MessagePacket packet = MessagePacketBuilder()
        .type('register')
        .put('username', username)
        .put('ed25519PublicKey', base64Encode(keyPair.x509ed25519PublicKey()))
        .put('x25519PublicKey', base64Encode(keyPair.x509x25519PublicKey()))
        .build();

    var response = await http.post(
      url,

      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(packet),
    );

    print(response.body);
  }

}