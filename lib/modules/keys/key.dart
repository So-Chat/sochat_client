import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class KeyP {
  final List<int> privateKeyEd;
  final List<int> publicKeyEd;

  List<int>? privateKeyX;
  List<int>? publicKeyX;

  KeyP({required this.privateKeyEd, required this.publicKeyEd, this.publicKeyX, this.privateKeyX});

  static Future<KeyP> generate() async {
    final algorithm = Ed25519();
    final keyPairEd = await algorithm.newKeyPair();
    final privateKeyBytesEd = await keyPairEd.extractPrivateKeyBytes();
    final publicKey = await keyPairEd.extractPublicKey();

    final x25519 = await convertToX25519(privateKeyBytesEd);

    return KeyP(
      privateKeyEd: privateKeyBytesEd,
      publicKeyEd: publicKey.bytes,
      privateKeyX: x25519.key,
      publicKeyX: x25519.value,
    );
  }

  static Future<MapEntry> convertToX25519(List<int> privateKeyEd) async {
    final x25519SecretKeyBytes = privateKeyEd;

    final x25519KeyPair = await X25519().newKeyPairFromSeed(x25519SecretKeyBytes);
    final publicKey = await x25519KeyPair.extractPublicKey();

    var privateKeyX = await x25519KeyPair.extractPrivateKeyBytes();
    var publicKeyX = publicKey.bytes;

    print("PrivateX:  $privateKeyX \n PublicX: $publicKeyX");

    return MapEntry(privateKeyX, publicKeyX);
  }



  Future<List<int>> sign(List<int> message) async {
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPairFromSeed(Uint8List.fromList(privateKeyEd));

    final signature = await algorithm.sign(message, keyPair: keyPair);
    return signature.bytes;
  }

  Future<bool> verify(List<int> message, List<int> signatureBytes) async {
    final algorithm = Ed25519();
    final pubKey = SimplePublicKey(publicKeyEd, type: KeyPairType.ed25519);
    final signature = Signature(signatureBytes, publicKey: pubKey);
    return await algorithm.verify(message, signature: signature);
  }

  Uint8List encodeEd25519PublicKeyForJava(List<int> rawBytes) {
    final prefix = Uint8List.fromList([
      0x30, 0x2a, 0x30, 0x05,
      0x06, 0x03, 0x2b, 0x65, 0x70,
      0x03, 0x21, 0x00
    ]);

    final combined = Uint8List(prefix.length + rawBytes.length);
    combined.setAll(0, prefix);
    combined.setAll(prefix.length, rawBytes);
    return combined;
  }

  Uint8List encodeX25519PublicKeyForJava(List<int> rawBytes) {
    final prefix = Uint8List.fromList([
      0x30, 0x2a, 0x30, 0x05,
      0x06, 0x03, 0x2b, 0x65, 0x6e,
      0x03, 0x21, 0x00
    ]);

    final combined = Uint8List(prefix.length + rawBytes.length);
    combined.setAll(0, prefix);
    combined.setAll(prefix.length, rawBytes);
    return combined;
  }

  static KeyP fromBase64(String privateBase64, String publicBase64) {
    return KeyP(
      privateKeyEd: base64Decode(privateBase64),
      publicKeyEd: base64Decode(publicBase64),
    );
  }

  Uint8List x509ed25519PublicKey() => encodeEd25519PublicKeyForJava(publicKeyEd);
  Uint8List x509x25519PublicKey() => encodeX25519PublicKeyForJava(publicKeyX!);

  String ed25519PrivateKeyBase64() => base64Encode(privateKeyEd);
  String ed25519PublicKeyBase64() => base64Encode(publicKeyEd);

  String x25519PrivateKeyBase64() => base64Encode(privateKeyX!);
  String x25519PublicKeyBase64() => base64Encode(publicKeyX!);


}