
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
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

  Future<void> uploadImage(String ip) async{
    var url = Uri.parse((ip + '/media').toString());
    var request = await http.MultipartRequest("POST", url);

    request.fields['description'] = 'test';

    var multipartFile = await http.MultipartFile.fromPath(
      'photo', "C:\\portapps\\sochat_client\\test.png"
    );
    request.files.add(multipartFile);

    var response = await request.send();

    if (response.statusCode == 200) {
      print('Загружено!');
    } else {
      print('Ошибка: ${response.statusCode}');
    }

  }

}