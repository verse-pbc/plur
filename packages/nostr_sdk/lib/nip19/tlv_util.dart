class TLVUtil {
  static TLVData? readTLVEntry(
    List<int> data, {
    int startIndex = 0,
  }) {
    var dataLength = data.length;
    if (dataLength < startIndex + 2) {
      return null;
    }

    var typ = data[startIndex];
    var length = data[startIndex + 1];

    if (dataLength >= startIndex + 2 + length) {
      var d = data.sublist(startIndex + 2, startIndex + 2 + length);

      return TLVData(typ, length, d);
    }

    return null;
  }

  static writeTLVEntry(List<int> buf, int typ, List<int> data) {
    var length = data.length;
    buf.add(typ);
    buf.add(length);
    buf.addAll(data);
  }
}

class TLVData {
  int typ;

  int length;

  List<int> data;

  TLVData(this.typ, this.length, this.data);
}

class TLVType {
  static const int defaultType = 0; // "default" is a reserved word
  static const int relay = 1;
  static const int author = 2;
  static const int kind = 3;
}
