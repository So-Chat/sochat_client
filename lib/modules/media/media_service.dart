
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:sochat_client/modules/keys/key_service.dart';

final mediaServiceProvider = Provider<MediaService>((ref) {
  final _keyService = ref.read(keyServiceProvider.notifier);
  return MediaService(_keyService);
});

class MediaService {

  final KeyService _keyService;

  MediaService(this._keyService);

  Future<List<File>> getFiles() async {
    FilePickerResult? result = await FilePicker.pickFiles(allowMultiple: true);

    if (result != null) {
      List<File> files = result.paths.map((path) => File(path!)).toList();
      return files;
    } else {
      return [];
    }
  }

  Future<void> uploadMedia(String ip, int chatId, File file, {String description = ""}) async{
    var url = Uri.parse((ip + '/media').toString());
    var request = await http.MultipartRequest("POST", url);

    request.fields['description'] = description;
    request.fields['chatId'] = chatId.toString();

    final fileBytes = await file.readAsBytes();
    final mimeType = lookupMimeType(file.uri.pathSegments.last);

    String fieldName = 'file';

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


    var multipartFile = http.MultipartFile.fromBytes(
      fieldName,
      fileBytes,
      filename: file.uri.pathSegments.last,
      contentType: mimeType != null ? http.MediaType.parse(mimeType) : null
    );
    request.files.add(multipartFile);

    var response = await request.send();

    if (response.statusCode == 200) {
      print('Loaded!');
    } else {
      print('Error: ${response.statusCode}');
    }
  }

}