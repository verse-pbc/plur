/// Contains constants representing Nostr event kinds.
///
/// For more information, see:
/// https://github.com/nostr-protocol/nips#event-kinds
class EventKind {
  /// Kind 0 - Metadata about a user (e.g., name, picture, bio).
  static const int metadata = 0;

  /// Kind 1 - Text note (standard post or message).
  static const int textNote = 1;

  /// Kind 2 - Recommended relay (servers the user suggests others follow).
  static const int recommendServer = 2;

  /// Kind 3 - List of contacts the user follows.
  static const int contactList = 3;

  /// Kind 4 - Encrypted direct message to another user.
  static const int directMessage = 4;

  /// Kind 5 - Event used to delete one or more previous events.
  static const int eventDeletion = 5;

  /// Kind 6 - Repost of another event.
  static const int repost = 6;

  /// Kind 7 - Reaction to another event (e.g., like, emoji).
  static const int reaction = 7;

  /// Kind 8 - Awarding a badge to a user.
  static const int badgeAward = 8;

  /// Kind 9 - Group chat message.
  static const int groupChatMessage = 9;

  /// Kind 10 - Reply in a group chat.
  static const int groupChatReply = 10;

  /// Kind 11 - Post within a group.
  static const int groupNote = 11;

  /// Kind 12 - Reply to a group note.
  static const int groupNoteReply = 12;

  /// Kind 13 - Event used to finalize or seal another event.
  static const int sealEventKind = 13;

  /// Kind 14 - Private direct message using an updated encryption scheme.
  static const int privateDirectMessage = 14;

  /// Kind 16 - Generic repost event, not tied to one kind.
  static const int genericRepost = 16;

  /// Kind 1059 - Special event type used to wrap other events (e.g., encryption).
  static const int giftWrap = 1059;

  /// Kind 1063 - Header describing a file.
  static const int fileHeader = 1063;

  /// Kind 1064 - File shared via relay.
  static const int storageSharedFile = 1064;

  /// Kind 2003 - Shared torrent information.
  static const int torrents = 2003;

  /// Kind 4550 - A post that was approved by a community.
  static const int communityApproved = 4550;

  /// Kind 6969 - Poll event for voting.
  static const int poll = 6969;

  /// Kind 9000 - Event to add a user to a group.
  static const int groupAddUser = 9000;

  /// Kind 9001 - Event to remove a user from a group.
  static const int groupRemoveUser = 9001;

  /// Kind 9002 - Event to edit group metadata.
  static const int groupEditMetadata = 9002;

  /// Kind 9003 - Add permission to a group role.
  static const int groupAddPermission = 9003;

  /// Kind 9004 - Remove permission from a group role.
  static const int groupRemovePermission = 9004;

  /// Kind 9005 - Delete an event within a group.
  static const int groupDeleteEvent = 9005;

  /// Kind 9006 - Change the status of a group (active, archived, etc).
  static const int groupEditStatus = 9006;

  /// Kind 9007 - Create a new group.
  static const int groupCreateGroup = 9007;

  /// Kind 9008 - Delete an existing group.
  static const int groupDeleteGroup = 9008;

  /// Kind 9009 - Create an invite to join a group.
  static const int groupCreateInvite = 9009;

  /// Kind 9021 - Event for joining a group.
  static const int groupJoin = 9021;

  /// Kind 9022 - Event for leaving a group.
  static const int groupLeave = 9022;

  /// Kind 9041 - Zap goal event (e.g., fund-raising goal).
  static const int zapGoals = 9041;

  /// Kind 9734 - Zap request (used to initiate zaps).
  static const int zapRequest = 9734;

  /// Kind 9735 - Zap payment receipt.
  static const int zap = 9735;

  /// Kind 10002 - List of relays the user uses.
  static const int relayListMetadata = 10002;

  /// Kind 10003 - List of bookmarks saved by the user.
  static const int bookmarksList = 10003;

  /// Kind 10009 - List of groups the user is in or manages.
  static const int groupList = 10009;

  /// Kind 10030 - Custom emoji definitions.
  static const int emojisList = 10030;

  /// Kind 13194 - NWC (Nostr Wallet Connect) info event.
  static const int nwcInfoEvent = 13194;

  /// Kind 22242 - Authentication event (used in NIP-42).
  static const int authentication = 22242;

  /// Kind 23194 - NWC request event (e.g., send zap).
  static const int nwcRequestEvent = 23194;

  /// Kind 23195 - NWC response event (result of request).
  static const int nwcResponseEvent = 23195;

  /// Kind 24133 - Event for remote signing via Nostr.
  static const int nostrRemoteSigning = 24133;

  /// Kind 24242 - Blossom protocol HTTP authentication.
  static const int blossomHttpAuth = 24242;

  /// Kind 27235 - HTTP authentication used in browser/relay login.
  static const int httpAuth = 27235;

  /// Kind 30000 - Follow sets (curated or grouped follows).
  static const int followSets = 30000;

  /// Kind 30008 - Event to accept a badge.
  static const int badgeAccept = 30008;

  /// Kind 30009 - Definition of a badge.
  static const int badgeDefinition = 30009;

  /// Kind 30023 - Long-form content (e.g., articles).
  static const int longForm = 30023;

  /// Kind 30024 - Link long-form to another event.
  static const int longFormLinked = 30024;

  /// Kind 30311 - Live event announcement (e.g., stream).
  static const int liveEvent = 30311;

  /// Kind 34550 - Community definition and settings.
  static const int communityDefinition = 34550;

  /// Kind 34235 - Horizontal video content.
  static const int videoHorizontal = 34235;

  /// Kind 34236 - Vertical video content (e.g., short videos).
  static const int videoVertical = 34236;

  /// Kind 39000 - Group metadata for display or management.
  static const int groupMetadata = 39000;

  /// Kind 39001 - List of group admins.
  static const int groupAdmins = 39001;

  /// Kind 39002 - List of group members.
  static const int groupMembers = 39002;

  /// Event kinds that should not be sent to cache relays.
  static List<int> cacheAvoidEvents = [
    nostrRemoteSigning,
    groupAdmins,
    groupMembers,
    groupChatMessage,
    groupChatReply,
    groupNote,
    groupNoteReply,
  ];

  /// Event kinds currently supported in the application.
  static List<int> supportedEvents = [
    textNote,
    repost,
    genericRepost,
    longForm,
    fileHeader,
    storageSharedFile,
    torrents,
    poll,
    zapGoals,
    videoHorizontal,
    videoVertical,
  ];
}
