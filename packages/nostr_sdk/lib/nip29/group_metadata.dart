import '../event.dart';
import '../utils/string_util.dart';
import 'group_object.dart';

class GroupMetadata extends GroupObject {
  String? name;

  String? picture;

  String? about;

  /// Optional: A text containing the community guidelines for this group.
  String? communityGuidelines;

  bool? public;

  bool? open;
  
  /// When true, only admins can post announcements, but all members can still chat
  bool? adminOnlyPosts;
  
  List<String>? relays;

  GroupMetadata(
    String groupId,
    int createdAt, {
    this.name,
    this.picture,
    this.about,
    this.communityGuidelines,
    this.public,
    this.open,
    this.adminOnlyPosts,
    this.relays,
  }) : super(groupId, createdAt);

  static GroupMetadata? loadFromEvent(Event event) {
    String? groupId;
    String? name;
    String? picture;
    String? about;
    String? communityGuidelines;
    bool? public;
    bool? open;
    bool? adminOnlyPosts;
    List<String> relays = [];
    int createdAt = event.createdAt;
    for (var tag in event.tags) {
      if (tag is List && tag.isNotEmpty) {
        var key = tag[0];

        if (key == "public") {
          public = true;
        } else if (key == "private") {
          public = false;
        } else if (key == "open") {
          open = true;
        } else if (key == "closed") {
          open = false;
        } else if (key == "adminOnlyPosts") {
          adminOnlyPosts = true;
        } else if (key == "memberPosts") {
          adminOnlyPosts = false;
        } else if (tag.length > 1) {
          var value = tag[1];

          if (key == "d") {
            groupId = value;
          } else if (key == "name") {
            name = value;
          } else if (key == "picture") {
            picture = value;
          } else if (key == "about") {
            about = value;
          } else if (key == "guidelines") {
            communityGuidelines = value;
          } else if (key == "h") {
            groupId = value;
          } else if (key == "relay") {
            relays.add(value);
          }
        }
      }
    }

    if (StringUtil.isBlank(groupId)) {
      return null;
    }

    return GroupMetadata(
      groupId!,
      createdAt,
      name: name,
      picture: picture,
      about: about,
      communityGuidelines: communityGuidelines,
      public: public,
      open: open,
      adminOnlyPosts: adminOnlyPosts,
      relays: relays.isNotEmpty ? relays : null,
    );
  }

  String? get displayName {
    if (name != null && name!.isNotEmpty) return name;

    int apostropheIndex = groupId.indexOf("'");

    if (apostropheIndex != -1) {
      return groupId.substring(apostropheIndex + 1);
    } else {
      return null;
    }
  }
}
