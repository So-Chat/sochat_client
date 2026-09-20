import 'dart:convert';

class MessagePacket {
  final String? type;
  final Map<String, dynamic> payload;

  MessagePacket({required this.type, required this.payload});

  Map<String, dynamic> toJson() {
    return {
      "type": type,
      "payload": payload,
    };
  }

  factory MessagePacket.fromJson(Map<String, dynamic> json) {
    return MessagePacket(
      type: json["type"],
      payload: Map<String, dynamic>.from(json["payload"] ?? {}),
    );
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

}

class MessagePacketBuilder {
  String? _type;
  final Map<String, dynamic> _payload = {};

  MessagePacketBuilder type(String type) {
    _type = type;
    return this;
  }

  MessagePacketBuilder put(String field, dynamic value) {
    _payload[field] = value;
    return this;
  }

  MessagePacketBuilder putNode(String field, Map<String, dynamic> node) {
    _payload[field] = node;
    return this;
  }

  MessagePacket build() {
    return MessagePacket(type: _type, payload: Map.from(_payload));
  }
}