import 'event.dart';

/// filter is a JSON object that determines what events will be sent in that subscription
class Filter {
  /// a list of event ids or prefixes
  List<String>? ids;

  /// a list of pubkeys or prefixes, the pubkey of an event must be one of these
  List<String>? authors;

  /// a list of a kind numbers
  List<int>? kinds;

  /// a list of event ids that are referenced in an "e" tag
  List<String>? e;

  /// a list of pubkeys that are referenced in a "p" tag
  List<String>? p;

  /// a timestamp, events must be newer than this to pass
  int? since;

  /// a timestamp, events must be older than this to pass
  int? until;

  /// maximum number of events to be returned in the initial query
  int? limit;

  /// Default constructor
  Filter(
      {this.ids,
      this.authors,
      this.kinds,
      this.e,
      this.p,
      this.since,
      this.until,
      this.limit});

  /// Deserialize a filter from a JSON
  Filter.fromJson(Map<String, dynamic> json) {
    ids = json['ids'] == null ? null : List<String>.from(json['ids']);
    authors =
        json['authors'] == null ? null : List<String>.from(json['authors']);
    kinds = json['kinds'] == null ? null : List<int>.from(json['kinds']);
    e = json['#e'] == null ? null : List<String>.from(json['#e']);
    p = json['#p'] == null ? null : List<String>.from(json['#p']);
    since = json['since'];
    until = json['until'];
    limit = json['limit'];
  }

  /// Serialize a filter in JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (ids != null) {
      data['ids'] = ids;
    }
    if (authors != null) {
      data['authors'] = authors;
    }
    if (kinds != null) {
      data['kinds'] = kinds;
    }
    if (e != null) {
      data['#e'] = e;
    }
    if (p != null) {
      data['#p'] = p;
    }
    if (since != null) {
      data['since'] = since;
    }
    if (until != null) {
      data['until'] = until;
    }
    if (limit != null) {
      data['limit'] = limit;
    }
    return data;
  }

  bool checkEvent(Event event) {
    if (ids != null && (!ids!.contains(event.id))) {
      return false;
    }
    if (authors != null && (!authors!.contains(event.pubkey))) {
      return false;
    }
    if (kinds != null && (!kinds!.contains(event.kind))) {
      return false;
    }
    if (since != null && since! > event.createdAt) {
      return false;
    }
    if (until != null && until! < event.createdAt) {
      return false;
    }

    List<String> es = [];
    List<String> ps = [];
    for (var tag in event.tags) {
      if (tag is List && tag.length > 1) {
        var k = tag[0];
        var v = tag[1];

        if (k == "e") {
          es.add(v);
        } else if (k == "p") {
          ps.add(v);
        }
      }
    }
    if (e != null &&
        (!(es.any((v) {
          return e!.contains(v);
        })))) {
      // filter query e but es don't contains e.
      return false;
    }
    if (p != null &&
        (!(ps.any((v) {
          return p!.contains(v);
        })))) {
      // filter query p but ps don't contains p.
      return false;
    }

    return true;
  }
}
