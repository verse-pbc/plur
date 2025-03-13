class CustomEmoji {
  String? name;
  String? filepath;

  CustomEmoji({this.name, this.filepath});

  CustomEmoji.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    filepath = json['filepath'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['filepath'] = filepath;
    return data;
  }
}
