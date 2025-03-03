/// Models a NIP-29 group identifier ('h' tag). Some group identifiers include the relay, so this
/// class will make that available if it is present.
class GroupIdentifier {

  // This field in here is wss://domain not like NIP29 domain
  // This should be nullable. NIP-29 says that groups identifiers MAY put the host before an 
  // apostrophe in the group identifier, not that they must.
  String host;

  String groupId;

  GroupIdentifier(this.host, this.groupId);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GroupIdentifier && other.host == host && other.groupId == groupId;
  }

  @override
  int get hashCode => host.hashCode ^ groupId.hashCode;

  static GroupIdentifier? parse(String idStr) {
    var strs = idStr.split("'");
    if (strs.isNotEmpty && strs.length > 1) {
      return GroupIdentifier(strs[0], strs[1]);
    }

    return GroupIdentifier("", idStr);
  }

  @override
  String toString() {
    return "$host'$groupId";
  }

  List<dynamic> toJson() {
    List<dynamic> list = [];
    list.add("group");
    list.add(groupId);
    list.add(host);
    return list;
  }
}
