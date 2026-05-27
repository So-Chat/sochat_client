
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:sochat_client/modules/common/auth_service.dart';
import 'package:sochat_client/modules/keys/key_service.dart';


import 'media.dart';

final mediaServiceProvider = Provider<MediaService>((ref) {
  final keyService = ref.read(keyServiceProvider.notifier);
  final authService = ref.read(authServiceProvider);
  return MediaService(keyService, authService);
});

class MediaService {

  final KeyService _keyService;
  final AuthService _authService;

  MediaService(this._keyService, this._authService);

  Future<List<File>> getFiles() async {
    FilePickerResult? result = await FilePicker.pickFiles(allowMultiple: true, lockParentWindow: true);

    if (result != null) {
      List<File> files = result.paths.map((path) => File(path!)).toList();
      return files;
    } else {
      return [];
    }
  }



  Future<void> downloadMedia(String ip, Media mediaFile, String savePath, {SecretKey? aesKey}) async {
    final stream = await _openMediaStream(ip, mediaFile, aesKey: aesKey,);

    final file = File(savePath);
    final sink = file.openWrite();

    await stream.pipe(sink);
    await sink.close();
  }

  Future<Uint8List>? loadPhotoBytes(
      Media mediaFile, WidgetRef ref, {
        SecretKey? aesKey,
      }) async {
    final ip = _keyService.servers.entries.toList()[ref.read(selectedServerProvider)].value;

    final stream = await _openMediaStream(ip, mediaFile, aesKey: aesKey);

    final bytes = await stream.expand((x) => x).toList();
    return Uint8List.fromList(bytes);
  }

  Future<void> deleteMedia(String ip, Media mediaFile) async {
    var url = Uri.parse(('$ip/media?id=${mediaFile.mediaId}').toString());
    var request = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer ${_authService.token!}'
      },

    );

    print(request.body);
  }


  Future<void> uploadMedia(String ip, Media mediaFile, {String? description, SecretKey? aesKey}) async{
    var url = Uri.parse(('$ip/media').toString());
    var request = http.MultipartRequest("POST", url);

    // Set chat id and send authorization token
    request.headers['Authorization'] = 'Bearer ${_authService.token!}';

    String fieldName = 'file';

    final file = mediaFile.file!;
    int length = await file.length();

    int uploadedState = 0;

    late final Stream<List<int>> fileStream;

    if (aesKey != null) {
      final encryptData = _keyService.ctrEncryptStream(file.openRead(), aesKey);
      request.headers['x-nonce'] = base64Encode(encryptData.nonce);

      fileStream = encryptData.stream;
    } else {
      fileStream = file.openRead();
    }

    final progressStream = buildProgressStream(
      fileStream,
      isEncrypted: aesKey != null,
      uploadedState: uploadedState,
    );

    // Configure mimeType
    // It will help client configure out how to display file when someone gets it
    final mimeType = lookupMimeType(mediaFile.file!.uri.pathSegments.last);
    if (mimeType != null) {
      if (mimeType.startsWith('image/')) {
        fieldName = 'photo';
      } else if (mimeType.startsWith('video/')) {
        fieldName = 'video';
      } else if (mimeType.startsWith('audio/')) {
        fieldName = 'audio';
      } else {
        fieldName = 'document';
      }
    }

    // Generating multipart file, it will make send files in request fragmented
    var multipartFile = http.MultipartFile(
        fieldName,
        progressStream,
        length,
        filename: mediaFile.file!.uri.pathSegments.last,
        contentType: mimeType != null ? http.MediaType.parse(mimeType) : null
    ); // And adding it to request


    request.files.add(multipartFile);

    // Finally send request
    var response = await request.send();

    // Debug code
    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      mediaFile.mediaId = responseBody;
      mediaFile.isLoaded = true;
      print('Loaded!');
    } else {
      print('Error: ${response.statusCode}');
    }
  }

  Future<void> resolveMediaBytes(String ip, Media media) async {
    final url = "$ip/media/${media.mediaId}";
    final response = await http.get(Uri.parse(url));
    media.fileBytes = response.bodyBytes;
  }

  Stream<List<int>> buildProgressStream(
      Stream<List<int>> source, {
        required bool isEncrypted,
        AesCtr? algorithm,
        List<int>? secretKey,
        List<int>? nonce,
        required int uploadedState,
      }) {
    return source.transform(
      StreamTransformer.fromHandlers(
        handleData: (chunk, sink) {
          uploadedState += chunk.length;

          print(
            'Uploaded${isEncrypted ? " encrypted" : ""}: $uploadedState',
          );

          sink.add(chunk);
        },
      ),
    );
  }

  Future<Stream<List<int>>> _openMediaStream(
      String ip,
      Media mediaFile, {
        SecretKey? aesKey,
      }) async {
    final url = Uri.parse("$ip/media/${mediaFile.mediaId}");
    final request = http.Request("GET", url);

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception("Request failed: ${response.statusCode}");
    }

    if (aesKey != null) {
      return _keyService.ctrDecryptStream(
        response.stream,
        aesKey,
        base64Decode(mediaFile.nonce!),
      );
    }

    return response.stream;
  }

}