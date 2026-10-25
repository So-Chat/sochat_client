import 'dart:async';
import 'dart:typed_data';

class TcpFrameHandler {

  final _packetController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get packetStream => _packetController.stream;

  final Stream<Uint8List> _stream;
  final List<int> _byteBuffer = [];

  TcpFrameHandler(this._stream) {
    _stream.listen((rawFullData) async {
      _byteBuffer.addAll(rawFullData);

      while (_byteBuffer.length >= 4) {
        final dataLength = ByteData.sublistView(Uint8List.fromList(_byteBuffer.sublist(0, 4)),).getUint32(0);
        final packetLength = 4 + dataLength;

        if (_byteBuffer.length < packetLength) {
          break;
        }

        final rawData = Uint8List.fromList(
          _byteBuffer.sublist(4, packetLength),
        );
        _byteBuffer.removeRange(0, packetLength);

        _packetController.add(rawData);
      }
    });
  }

}
