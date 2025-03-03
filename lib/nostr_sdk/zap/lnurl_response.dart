class LnurlResponse {
  String? callback;
  int? maxSendable;
  int? minSendable;
  String? metadata;
  int? commentAllowed;
  String? tag;
  bool? allowsNostr;
  String? nostrPubkey;

  LnurlResponse({
    this.callback,
    this.maxSendable,
    this.minSendable,
    this.metadata,
    this.commentAllowed,
    this.tag,
    this.allowsNostr,
    this.nostrPubkey,
  });

  LnurlResponse.fromJson(Map<String, dynamic> json) {
    callback = json['callback'];
    maxSendable = json['maxSendable'];
    minSendable = json['minSendable'];
    metadata = json['metadata'];
    commentAllowed = json['commentAllowed'];
    tag = json['tag'];
    allowsNostr = json['allowsNostr'];
    nostrPubkey = json['nostrPubkey'];
  }

  Map<String, dynamic> toJson() {
    return {
      'callback': callback,
      'maxSendable': maxSendable,
      'minSendable': minSendable,
      'metadata': metadata,
      'commentAllowed': commentAllowed,
      'tag': tag,
      'allowsNostr': allowsNostr,
      'nostrPubkey': nostrPubkey,
    };
  }
}
