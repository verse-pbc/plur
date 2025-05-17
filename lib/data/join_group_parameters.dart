/// Parameters needed to join a group
class JoinGroupParameters {
  /// The relay hosting the group
  final String host;
  
  /// The unique identifier for the group
  final String groupId;
  
  /// Optional invitation code
  final String? code;
  
  /// Creates parameters for joining a group
  /// 
  /// [host] is the relay address (e.g. "wss://communities.nos.social")
  /// [groupId] is the unique identifier for the group
  /// [code] is the optional invitation code
  JoinGroupParameters(this.host, this.groupId, {this.code});
}
