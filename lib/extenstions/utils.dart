import 'dart:math';
import 'dart:typed_data';

class Utils {
  static DateTime currentTime = DateTime.now();

  static String buildDateString(DateTime messageDate) {
    String dateString = "";
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    dateString +=
        "${twoDigits(messageDate.hour)}:${twoDigits(messageDate.minute)}";

    if (currentTime.year == messageDate.year) {
      if (currentTime.day == messageDate.day) {
        return dateString;
      } else if (currentTime.day == messageDate.day - 1) {
        dateString += " Yesterday";
      } else {
        dateString += " ${messageDate.month}/${messageDate.day}";
      }
    } else {
      dateString +=
          " ${messageDate.month}/${messageDate.day}/${messageDate.year}";
    }

    return dateString;
  }

  static String configureFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];

    // log(bytes) / log(1024) gives us degree of 1024
    int i = (log(bytes) / log(1024)).floor();

    // Result number
    double size = bytes / pow(1024, i);

    // if number is integer, return without decimals, if double return with them
    return "${size.toStringAsFixed(size == size.truncate() ? 0 : 1)} ${suffixes[i]}";
  }

  static List<int> int32ToBytes(int value) {
    final b = ByteData(4);
    b.setUint32(0, value, Endian.big);
    return b.buffer.asUint8List();
  }

  static List<Map<String, dynamic>> parseSdp(String sdp) {
    final sections = sdp
        .split(RegExp(r'(?=m=)'))
        .where((section) => section.trim().isNotEmpty);

    return sections.map((section) {
      final lines = section
          .split(RegExp(r'\r?\n'))
          .where((line) => line.isNotEmpty)
          .toList();

      final mediaLine = lines.firstWhere(
        (line) => line.startsWith('m='),
      );

      final type = mediaLine.substring(2).split(' ').first;

      String direction = 'sendrecv';
      String? mid;
      final codecs = <String>[];

      for (final line in lines) {
        if (line.startsWith('a=mid:')) {
          mid = line.substring('a=mid:'.length);
        } else if (line == 'a=sendrecv' ||
            line == 'a=sendonly' ||
            line == 'a=recvonly' ||
            line == 'a=inactive') {
          direction = line.substring(2);
        } else if (line.startsWith('a=rtpmap:')) {
          codecs.add(line.substring('a=rtpmap:'.length));
        }
      }

      return {
        'type': type,
        'direction': direction,
        'mid': mid,
        'codecs': codecs,
      };
    }).toList();
  }
}
