import 'dart:io';
import 'dart:typed_data';

class Media {
  String? mediaId;
  int? senderId;

  String? mimeType;
  String? fileName;
  int? fileSize;

  int? width;
  int? height;
  int? length;

  String? nonce;

  File? file;
  Uint8List? fileBytes;

  bool isLoaded = false;


  Media({this.mediaId, this.senderId, this.mimeType, this.fileName, this.fileSize, this.width, this.height, this.length, this.file, this.fileBytes, this.nonce});

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      mediaId: json['mediaId'] as String,
      senderId: json['senderId'] as int,
      mimeType: json['mimeType'] as String,
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as int,
      width: json['width'],
      height: json['height'],
      length: json['length'],
      nonce: json['nonce'],
    );
  }
}