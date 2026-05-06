import 'dart:math';
import 'dart:typed_data';

class Utils {

  static DateTime currentTime = DateTime.now();

  static String buildDateString(DateTime messageDate){
    String dateString = "";
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    dateString += "${twoDigits(messageDate.hour)}:${twoDigits(messageDate.minute)}";

    if (currentTime.year == messageDate.year) {
      if (currentTime.day == messageDate.day) {
        return dateString;
      }
      else if  (currentTime.day == messageDate.day - 1) {
        dateString += " Yesterday";
      }
      else {
        dateString += " ${messageDate.month}/${messageDate.day}";
      }
    }
    else {
      dateString += " ${messageDate.month}/${messageDate.day}/${messageDate.year}";
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

}