/// Contains constants representing Nostr event kinds.
/// 
/// For more information, see: 
/// https://github.com/nostr-protocol/nips#event-kinds
class EventKind {
  /// Metadata about a user (e.g., name, picture, bio).
  static const int metadata = 0;

  /// Text note (standard post or message).
  static const int textNote = 1;

  /// Recommended relay (servers the user suggests others follow).
  static const int recommendServer = 2;

  /// List of contacts the user follows.
  static const int contactList = 3;

  /// Encrypted direct message to another user.
  static const int directMessage = 4;

  /// Event used to delete one or more previous events.
  static const int eventDeletion = 5;

  /// Repost of another event.
  static const int repost = 6;

  /// Reaction to another event (e.g., like, emoji).
  static const int reaction = 7;

  /// Awarding a badge to a user.
  static const int badgeAward = 8;

  /// Group chat message.
  static const int groupChatMessage = 9;

  /// Reply in a group chat.
  static const int groupChatReply = 10;

  /// Post within a group.
  static const int groupNote = 11;

  /// Reply to a group note.
  static const int groupNoteReply = 12;

  /// Event used to finalize or seal another event.
  static const int sealEventKind = 13;

  /// Private direct message using an updated encryption scheme.
  static const int privateDirectMessage = 14;

  /// Generic repost event, not tied to one kind.
  static const int genericRepost = 16;

  /// Special event type used to wrap other events (e.g., encryption).
  static const int giftWrap = 1059;

  /// Header describing a file.
  static const int fileHeader = 1063;

  /// File shared via relay.
  static const int storageSharedFile = 1064;

  /// Shared torrent information.
  static const int torrents = 2003;

  /// A post that was approved by a community.
  static const int communityApproved = 4550;

  /// Poll event for voting.
  static const int poll = 6969;

  /// Event to add a user to a group.
  static const int groupAddUser = 9000;

  /// Event to remove a user from a group.
  static const int groupRemoveUser = 9001;

  /// Event to edit group metadata.
  static const int groupEditMetadata = 9002;

  /// Add permission to a group role.
  static const int groupAddPermission = 9003;

  /// Remove permission from a group role.
  static const int groupRemovePermission = 9004;

  /// Delete an event within a group.
  static const int groupDeleteEvent = 9005;

  /// Change the status of a group (active, archived, etc).
  static const int groupEditStatus = 9006;

  /// Create a new group.
  static const int groupCreateGroup = 9007;

  /// Delete an existing group.
  static const int groupDeleteGroup = 9008;

  /// Create an invite to join a group.
  static const int groupCreateInvite = 9009;

  /// Event for joining a group.
  static const int groupJoin = 9021;

  /// Event for leaving a group.
  static const int groupLeave = 9022;

  /// Zap goal event (e.g., fund-raising goal).
  static const int zapGoals = 9041;

  /// Zap request (used to initiate zaps).
  static const int zapRequest = 9734;

  /// Zap payment receipt.
  static const int zap = 9735;

  /// List of relays the user uses.
  static const int relayListMetadata = 10002;

  /// List of bookmarks saved by the user.
  static const int bookmarksList = 10003;

  /// List of groups the user is in or manages.
  static const int groupList = 10009;

  /// Custom emoji definitions.
  static const int emojisList = 10030;

  /// NWC (Nostr Wallet Connect) info event.
  static const int nwcInfoEvent = 13194;

  /// Authentication event (used in NIP-42).
  static const int authentication = 22242;

  /// NWC request event (e.g., send zap).
  static const int nwcRequestEvent = 23194;

  /// NWC response event (result of request).
  static const int nwcResponseEvent = 23195;

  /// Event for remote signing via Nostr.
  static const int nostrRemoteSigning = 24133;

  /// Blossom protocol HTTP authentication.
  static const int blossomHttpAuth = 24242;

  /// HTTP authentication used in browser/relay login.
  static const int httpAuth = 27235;

  /// Follow sets (curated or grouped follows).
  static const int followSets = 30000;

  /// Event to accept a badge.
  static const int badgeAccept = 30008;

  /// Definition of a badge.
  static const int badgeDefinition = 30009;

  /// Long-form content (e.g., articles).
  static const int longForm = 30023;

  /// Link long-form to another event.
  static const int longFormLinked = 30024;

  /// Live event announcement (e.g., stream).
  static const int liveEvent = 30311;

  /// Community definition and settings.
  static const int communityDefinition = 34550;

  /// Horizontal video content.
  static const int videoHorizontal = 34235;

  /// Vertical video content (e.g., short videos).
  static const int videoVertical = 34236;

  /// Group metadata for display or management.
  static const int groupMetadata = 39000;

  /// List of group admins.
  static const int groupAdmins = 39001;

  /// List of group members.
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
