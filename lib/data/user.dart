class User {
  String? pubkey;
  String? name;
  String? displayName;
  String? picture;
  String? banner;
  String? website;
  String? about;
  String? nip05;
  String? lud16;
  String? lud06;
  int? updatedAt;
  int? valid;

  User({
    this.pubkey,
    this.name,
    this.displayName,
    this.picture,
    this.banner,
    this.website,
    this.about,
    this.nip05,
    this.lud16,
    this.lud06,
    this.updatedAt,
    this.valid,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final nip05 = json['nip05'];
    final updatedAt = json['updated_at'];
    return User(
      pubkey: json['pub_key'],
      name: json['name'],
      displayName: json['display_name'],
      picture: json['picture'],
      banner: json['banner'],
      website: json['website'],
      about: json['about'],
      nip05: nip05 != null && nip05 is String ? nip05 : null,
      lud16: json['lud16'],
      lud06: json['lud06'],
      updatedAt: updatedAt != null && updatedAt is int ? updatedAt : null,
      valid: json['valid'],
    );
  }

  Map<String, dynamic> toFullJson() {
    var data = toJson();
    data['pub_key'] = pubkey;
    return data;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['display_name'] = displayName;
    data['picture'] = picture;
    data['banner'] = banner;
    data['website'] = website;
    data['about'] = about;
    data['nip05'] = nip05;
    data['lud16'] = lud16;
    data['lud06'] = lud06;
    data['updated_at'] = updatedAt;
    data['valid'] = valid;
    return data;
  }
}
