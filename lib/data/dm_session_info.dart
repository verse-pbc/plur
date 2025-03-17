class DMSessionInfo {
  int? keyIndex;

  String? pubkey;

  /// the last readed event created at
  int? readedTime;

  String? value1;

  String? value2;

  String? value3;

  DMSessionInfo(
      {this.pubkey, this.readedTime, this.value1, this.value2, this.value3});

  DMSessionInfo.fromJson(Map<String, dynamic> json) {
    keyIndex = json['key_index'];
    pubkey = json['pubkey'];
    readedTime = json['readed_time'];
    if (readedTime == null || readedTime! < 0) {
      readedTime = 0;
    }
    value1 = json['value1'];
    value2 = json['value2'];
    value3 = json['value3'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['key_index'] = keyIndex;
    data['pubkey'] = pubkey;
    data['readed_time'] = readedTime;
    data['value1'] = value1;
    data['value2'] = value2;
    data['value3'] = value3;
    return data;
  }
}
