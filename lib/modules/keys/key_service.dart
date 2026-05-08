import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart';
import 'package:sochat_client/modules/keys/key.dart';
import 'dart:math';

import 'package:crypto/crypto.dart' hide Hmac;

final keyServiceProvider = StateNotifierProvider<KeyService, KeyServiceState>((ref) {
  final service = KeyService(ref);
  return service;
});

final selectedProfileProvider = StateProvider<int>((ref) => 0);
final selectedServerProvider = StateProvider<int>((ref) => 0);

class KeyServiceState {
  final Map<String, KeyP> profiles;
  final Map<String, String> servers;

  KeyServiceState({
    required this.profiles,
    required this.servers,
  });

  KeyServiceState copyWith({
    Map<String, KeyP>? profiles,
    Map<String, String>? servers})
  {
    return KeyServiceState(
      profiles: profiles ?? this.profiles,
      servers: servers ?? this.servers,
    );
  }
}

class KeyService extends StateNotifier<KeyServiceState> {
  KeyService(this.ref) : super(KeyServiceState(profiles: {}, servers: {}));

  final Ref ref;

  Map<String, KeyP> get profiles => state.profiles;
  Map<String, String> get servers => state.servers;

  Future<void> generateProfile() async {
    final keyPair = await KeyP.generate();
    final newProfiles = {...state.profiles};

    final newKey = "profile${newProfiles.length + 1}";
    newProfiles[newKey] = keyPair;

    state = state.copyWith(profiles: newProfiles);
  }


  void addProfile(String key, KeyP value) {
    state = state.copyWith(profiles: {...profiles, key: value});
  }

  void removeProfile(String key) {
    final newProfiles = {...profiles};
    newProfiles.remove(key);
    state = state.copyWith(profiles: newProfiles);
  }

  void addServer(String key, String value) {
    state = state.copyWith(servers: {...servers, key: value});
  }

  void setServerByKey(String oldKey, String newKey, String newValue) {
    final newServers = {...state.servers};
    newServers.remove(oldKey);
    newServers[newKey] = newValue;
    state = state.copyWith(servers: newServers);
  }

  void updateServerIp(String key, String newIp) {
    if (!state.servers.containsKey(key)) return;

    final newServers = {...state.servers};
    newServers[key] = newIp;
    state = state.copyWith(servers: newServers);
  }

  void updateProfileName(String key, String newName) {
    final newProfiles = {...state.profiles};

    final entry = state.profiles.entries
        .firstWhere((e) => e.key == key);
    int index = state.profiles.keys.toList().indexOf(key);

    removeProfile(key);
    insertProfileAt(index, newName, entry.value);
  }

  void insertProfileAt(int index, String key, KeyP value) {
    final entries = state.profiles.entries.toList();

    entries.insert(index, MapEntry(key, value));

    final newMap = Map<String, KeyP>.fromEntries(entries);

    state = state.copyWith(profiles: newMap);
  }


  void updateServerName(String key, String newName) {
    final newServers = {...state.servers};

    final entry = state.servers.entries
        .firstWhere((e) => e.key == key);
    int index = state.servers.keys.toList().indexOf(key);

    removeServer(key);
    insertServerAt(index, newName, entry.value);
  }

  void insertServerAt(int index, String key, String value) {
    final entries = state.servers.entries.toList();

    entries.insert(index, MapEntry(key, value));

    final newMap = Map<String, String>.fromEntries(entries);

    state = state.copyWith(servers: newMap);
  }

  void removeServer(String key) {
    final newServers = {...servers};
    newServers.remove(key);
    state = state.copyWith(servers: newServers);
  }


  String profileToJson(int index) {
    final entry = profiles.entries.elementAt(index);

    final map = {
      entry.key: {
        "ed25519publicKey": entry.value.ed25519PublicKeyBase64(),
        "ed25519privateKey": entry.value.ed25519PrivateKeyBase64(),
      }
    };

    return jsonEncode(map);
  }

  String serverToJson(int index) {
    final entry = servers.entries.elementAt(index);

    final map = {
      entry.key: {
        "ip": entry.value,
      }
    };

    return jsonEncode(map);
  }

  void parseProfiles(String jsonString) async {
    final Map<String, dynamic> decoded = jsonDecode(jsonString);

    if (decoded.isEmpty) {
      throw Exception("JSON empty");
    }
    var firstKey = decoded.keys.first;
    final firstValue = decoded[firstKey] as Map<String, dynamic>;

    if (state.profiles.containsKey(firstKey)){
      final random = Random();
      firstKey += random.nextInt(100).toString();
    }

    KeyP keyP = KeyP(
      publicKeyEd: base64Decode(firstValue['ed25519publicKey']),
      privateKeyEd: base64Decode(firstValue['ed25519privateKey']),
    );
    final x25519Keys = await KeyP.convertToX25519(keyP.privateKeyEd);

    keyP.privateKeyX = x25519Keys.key;
    keyP.publicKeyX = x25519Keys.value;

    var profile = MapEntry(firstKey, keyP);

    addProfile(firstKey, profile.value);
  }

  void parseServers(String jsonString) async {
    final Map<String, dynamic> decoded = jsonDecode(jsonString);

    if (decoded.isEmpty) {
      throw Exception("Server could not load from local storage");
    }
    var firstKey = decoded.keys.first;
    final firstValue = decoded[firstKey]["ip"];

    if (firstValue == null) {
      throw Exception("Server could not load from local storage");
    }

    addServer(firstKey, firstValue);
  }

  Future<String> generateFingerprint() async {
    Uint8List keyP = profiles.entries.toList()[ref.read(selectedProfileProvider)].value.x509ed25519PublicKey();
    final bytes = utf8.encode(base64.encode(keyP));
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  Future<String> generateAes() async {
    final algorithm = AesGcm.with256bits();
    final secretKey = await algorithm.newSecretKey();
    final secretKeyBytes = await secretKey.extractBytes();

    return base64Encode(secretKeyBytes);
  }

  SecretKey decodeAes(String aesKey) {
    final secretKeyBytes = base64Decode(aesKey);
    return SecretKey(secretKeyBytes);
  }

  Future<String> encryptAesWithX25519(
      String recipientPublicKeyBase64,
      SecretKey aesKey,
      ) async {

    final algorithm = X25519();
    final ephemeralKeyPair = await algorithm.newKeyPair();

    final fullBytesPublicKey = base64Decode(recipientPublicKeyBase64);
    final rawPublicKey = fullBytesPublicKey.sublist(fullBytesPublicKey.length - 32);

    final recipientPublicKey = SimplePublicKey(
      rawPublicKey,
      type: KeyPairType.x25519,
    );

    final sharedSecret = await algorithm.sharedSecretKey(
      keyPair: ephemeralKeyPair,
      remotePublicKey: recipientPublicKey,
    );

    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final derivedKey = await hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: [],
      info: utf8.encode("key-wrapping"),
    );

    final aesGcm = AesGcm.with256bits();
    final nonce = aesGcm.newNonce();

    final secretBytes = await aesKey.extractBytes();

    final encrypted = await aesGcm.encrypt(
      secretBytes,
      secretKey: derivedKey,
      nonce: nonce,
    );

    final ephemeralPublic = await ephemeralKeyPair.extractPublicKey();

    final combined = Uint8List.fromList([
      ...ephemeralPublic.bytes,
      ...nonce,
      ...encrypted.cipherText,
      ...encrypted.mac.bytes,
    ]);

    return base64Encode(combined);
  }

  Future<SecretKey> decryptAesWithX25519({
    required String storedString,
    required List<int> keyBytes,
  }) async {

    final algorithm = X25519();
    KeyPair myPrivateKey = await algorithm.newKeyPairFromSeed(keyBytes);

    final data = base64Decode(storedString);

    final ephemeralPublic = data.sublist(0, 32);
    final nonce = data.sublist(32, 44);
    final ciphertext = data.sublist(44, 76);
    final mac = data.sublist(76, 92);

    final ephemeralPublicKey = SimplePublicKey(
      ephemeralPublic,
      type: KeyPairType.x25519,
    );

    final sharedSecret = await algorithm.sharedSecretKey(
      keyPair: myPrivateKey,
      remotePublicKey: ephemeralPublicKey,
    );

    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

    final derivedKey = await hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: [],
      info: utf8.encode("key-wrapping"),
    );

    final aesGcm = AesGcm.with256bits();

    final secretBox = SecretBox(
      ciphertext,
      nonce: nonce,
      mac: Mac(mac),
    );

    final decryptedBytes = await aesGcm.decrypt(
      secretBox,
      secretKey: derivedKey,
    );

    return SecretKey(decryptedBytes);
  }

  Future<String> encryptStringWithAesToString(String content, SecretKey aesKey) async {
    final contentBytes = utf8.encode(content);
    return base64Encode(await encryptWithAes(contentBytes, aesKey));
  }
  Future<List<int>> encryptStringWithAesToBytes(String content, SecretKey aesKey) async {
    final contentBytes = utf8.encode(content);
    return await encryptWithAes(contentBytes, aesKey);
  }
  Future<String> encryptBytesWithAesToString(List<int> contentBytes, SecretKey aesKey) async {
    return base64Encode(await encryptWithAes(contentBytes, aesKey));
  }


  Future<List<int>> encryptWithAes(List<int> contentBytes, SecretKey aesKey) async {
    final algorithm = AesGcm.with256bits();
    final nonce = algorithm.newNonce();

    final secretBox = await algorithm.encrypt(
      contentBytes,
      secretKey: aesKey,
      nonce: nonce,
    );

    final combined = [
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ];

    return combined;
  }

  Stream<List<int>> ctrDecryptStream(ByteStream stream, SecretKey secretKey, Uint8List nonce) {
    final algorithm = AesCtr.with256bits(macAlgorithm: MacAlgorithm.empty);
    return algorithm.decryptStream(
      stream,
      secretKey: secretKey,
      nonce: nonce,
      mac: Mac.empty,
    );
  }


  // I REALLY DON'T WANT TO MAKE A WHOLE NEW TYPE FOR JUST THAT METHOD :crying:
  ({Stream<List<int>> stream, List<int> nonce}) ctrEncryptStream(Stream<List<int>> fileStream, SecretKey secretKey) {
    final algorithm = AesCtr.with256bits(macAlgorithm: MacAlgorithm.empty);
    final nonce = algorithm.newNonce();

    final encryptStream = algorithm.encryptStream(
      fileStream,
      secretKey: secretKey,
      nonce: nonce,
      onMac: (_) {},
    );

    return (
      stream: encryptStream, nonce: nonce
    );
  }


  Future<String> decryptWithAes(String base64EncodedContent, SecretKey aesKey) async {
    try {
      final algorithm = AesGcm.with256bits();

      final combined = base64Decode(base64EncodedContent);

      final nonce = combined.sublist(0, 12);
      final mac = Mac(combined.sublist(combined.length - 16));
      final cipherText = combined.sublist(12, combined.length - 16);

      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: mac,
      );

      final decrypted = await algorithm.decrypt(
        secretBox,
        secretKey: aesKey,
      );

      return utf8.decode(decrypted);
    }
    catch (e){
      return "Couldn't decrypt content";
    }
  }

}