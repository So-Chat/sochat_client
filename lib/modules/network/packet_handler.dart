import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sochat_client/context/notifications/inapp_notifications_manager.dart';
import 'package:sochat_client/modules/keys/key_service.dart';
import 'package:sochat_client/modules/network/message_packet.dart';
import 'package:sochat_client/so_ui/notifications/so_notification.dart';

class PacketHandler {
  final StreamController<MessagePacket> _friendsController;
  final StreamController<MessagePacket> _chatsController;
  final StreamController<MessagePacket> _messagesController;
  final StreamController<MessagePacket> _callController;
  final InAppNotificationsManager _notificationsManager;
  final Map<int, Completer<dynamic>> _pendingRequests;
  final KeyService _keyService;

  PacketHandler({
    required this._friendsController,
    required this._chatsController,
    required this._messagesController,
    required this._callController,
    required this._notificationsManager,
    required this._pendingRequests,
    required this._keyService
  });

  Future<void> _handleCleanPacket(List<int> data) async {
    final messageBytes = utf8.decode(data);
    final message = MessagePacket.fromJson(jsonDecode(messageBytes));

    if (message.payload["success"] == false){
      _notificationsManager.addUpdate(
        SoNotification(
          icon: Icons.error_outline,
          title: "Error",
          content: message.payload["server_message"],
        ),
      );
    }
    switch (message.type) {
      case "friend_request":
      case "friend_accept":
      case "friend_decline":
      case "friend_remove":
      case "block": {
        _friendsController.add(message);
        break;
      }
      case "authenticate":
      case "chat_create":
      case "chat_add_participant":
      case "chat_delete": {
        _chatsController.add(message);
        break;
      }
      case "message_send":
      case "message_edit":
      case "message_read":
      case "message_delete":{
        _messagesController.add(message);
        break;
      }
      case "call_end":
      case "call_ice":
      case "call_offer":
      case "call_answer":
      case "call_accept":{
          _callController.add(message);
          break;
      }
      default:
        //debugPrint("Unhandled type: ${messagg.type}");
    }
  }

  ({Uint8List data, int requestId}) _parseResponse(Uint8List bytes,) {
    if (bytes.length < 4) {
      throw const FormatException('Packet too short');
    }

    final dataLength = bytes.length - 4;

    final data = Uint8List.sublistView(
      bytes,
      0,
      dataLength,
    );

    final requestId = ByteData.sublistView(
      bytes,
      dataLength,
    ).getUint32(0, Endian.big);

    return (data: data, requestId: requestId);
  }

  bool _completePendingRequest(int requestId, Uint8List data) {
    final pending = _pendingRequests.remove(requestId);

    if (pending == null || requestId == 0) {
      return false;
    }

    if (pending.isCompleted) { return true; }
    if (pending is Completer<Uint8List>) { pending.complete(data); return true; }

    if (pending is Completer<MessagePacket>) {
      try {
        final message = MessagePacket.fromJson(jsonDecode(utf8.decode(data)));
        pending.complete(
          MessagePacket(requestId: requestId, type: message.type, payload: Map<String, dynamic>.from(message.payload)),
        );
      } catch (e, st) { pending.completeError(e, st); }
      return true;
    }

    if (!pending.isCompleted) {
      pending.completeError(StateError('Unexpected response type for request $requestId'),);
    }
    return true;
  }

  Future<void> handleIncomingData(Uint8List rawData) async {
    final Uint8List decoded;

    if (_keyService.sessionKey == null) {
      decoded = rawData;
    } else {
      decoded = Uint8List.fromList(
        await _keyService.decryptWithAes(rawData, _keyService.sessionKey!),
      );
    }

    final response = _parseResponse(decoded);

    if (response.requestId != 0 &&
        _pendingRequests.containsKey(response.requestId)) {
      _completePendingRequest(response.requestId, response.data,);
      return;
    }

    if (_keyService.sessionKey != null) {
      await _handleCleanPacket(response.data);
    }
  }
}
