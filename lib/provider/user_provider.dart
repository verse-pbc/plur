import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/nip05status.dart';
import 'package:nostrmo/data/event_db.dart';
import 'package:nostrmo/data/db.dart';

import '../data/user.dart';
import '../data/user_db.dart';
import '../main.dart';

class UserProvider extends ChangeNotifier with LaterFunction {
  final Map<String, RelayListMetadata> _relayListMetadataCache = {};

  final Map<String, User> _userCache = {};

  final Map<String, int> _handingPubkeys = {};

  final Map<String, ContactList> _contactListMap = {};
  
  // Used to store the initial username during signup
  String? _initialUserName;
  
  /// Sets the initial username for a new user account
  set userName(String name) {
    _initialUserName = name;
    
    // If we have nostr already, update the metadata
    if (nostr != null) {
      try {
        // Create metadata with the username
        var metadata = <String, dynamic>{
          'name': name,
          'display_name': name,
        };
        
        // Create and publish the metadata event
        var content = jsonEncode(metadata);
        // Use Event.create for named parameters
        var event = Event.create(
          pubkey: nostr!.publicKey,
          kind: EventKind.metadata,
          content: content,
          tags: [],
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );
        nostr!.sendEvent(event);
        
        // Also update the local cache
        if (nostr!.publicKey.isNotEmpty) {
          final user = _userCache[nostr!.publicKey] ?? User();
          user.pubkey = nostr!.publicKey;
          user.name = name;
          user.displayName = name;
          user.updatedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          _userCache[nostr!.publicKey] = user;
          
          // Save to database
          UserDB.update(user);
          
          notifyListeners();
        }
      } catch (e) {
        debugPrint("Error updating metadata: $e");
      }
    }
  }

  static UserProvider? _userProvider;

  static Future<UserProvider> getInstance() async {
    if (_userProvider == null) {
      _userProvider = UserProvider();

      var list = await UserDB.all();
      for (var md in list) {
        if (md.valid == Nip05Status.nip05Invalid) {
          md.valid = null;
        }
        _userProvider!._userCache[md.pubkey!] = md;
      }

      var events = await EventDB.list(Base.defaultDataIndex,
          [EventKind.relayListMetadata, EventKind.contactList], 0, 1000000);
      _userProvider!._contactListMap.clear();
      for (var e in events) {
        if (e.kind == EventKind.relayListMetadata) {
          var relayListMetadata = RelayListMetadata.fromEvent(e);
          _userProvider!._relayListMetadataCache[relayListMetadata.pubkey] =
              relayListMetadata;
        } else if (e.kind == EventKind.contactList) {
          var contactList = ContactList.fromJson(e.tags, e.createdAt);
          _userProvider!._contactListMap[e.pubkey] = contactList;
        }
      }

      // lazyTimeMS begin bigger and request less
      _userProvider!.laterTimeMS = 2000;
    }

    return _userProvider!;
  }

  List<User> findUser(String str, {int? limit = 5}) {
    List<User> list = [];
    if (StringUtil.isNotBlank(str)) {
      var values = _userCache.values;
      for (final user in values) {
        if ((user.displayName != null && user.displayName!.contains(str)) ||
            (user.name != null && user.name!.contains(str)) ||
            (user.nip05 != null && user.nip05!.contains(str))) {
          list.add(user);

          if (limit != null && list.length >= limit) {
            break;
          }
        }
      }
    }
    return list;
  }
  
  /// Returns all cached users.
  /// 
  /// This is useful for custom search implementations.
  List<User> getAllUsers() {
    return _userCache.values.toList();
  }

  void _laterCallback() {
    if (_needUpdatePubKeys.isNotEmpty) {
      _laterSearch();
    }

    if (!_pendingEvents.isEmpty()) {
      _handlePendingEvents();
    }
  }

  final List<String> _needUpdatePubKeys = [];

  /// Schedules an update for a user's metadata from standard relays.
  /// 
  /// This method adds the pubkey to the list of keys that need updating
  /// and triggers the delayed update process.
  /// 
  /// @param pubkey The public key of the user to update
  void update(String pubkey) {
    if (!_needUpdatePubKeys.contains(pubkey)) {
      _needUpdatePubKeys.add(pubkey);
    }
    later(_laterCallback);
  }
  
  /// Forces an immediate refresh of a user's profile from reliable relays.
  /// 
  /// This method is useful when you need to ensure you have the latest
  /// profile data for a user, and don't want to wait for the regular
  /// update cycle. It queries reliable relays directly and updates
  /// the cache and database as soon as data is received.
  /// 
  /// @param pubkey The public key of the user to refresh
  /// @return A Future that resolves to true if the profile was found and updated
  Future<bool> forceProfileRefresh(String pubkey) async {
    // Mark the user as being handled to prevent duplicate requests
    _handingPubkeys[pubkey] = 1;
    
    // Request the profile from reliable relays
    final found = await fetchUserProfileFromReliableRelays(pubkey);
    
    // If not found in reliable relays, also try standard update
    if (!found) {
      update(pubkey);
    }
    
    return found;
  }

  /// Gets a user's metadata from the cache, or schedules a fetch if not found.
  /// 
  /// This method first checks the in-memory cache, and if the user isn't found,
  /// it schedules a fetch from the regular relay pool. Additionally, for users
  /// that aren't found, it also initiates a lookup from reliable relays.
  /// 
  /// @param pubkey The public key of the user to fetch
  /// @param tryReliableRelays Whether to try reliable relays if user not found
  /// @return The user metadata if found in cache, null otherwise
  User? getUser(String pubkey, {bool tryReliableRelays = true}) {
    final user = _userCache[pubkey];
    if (user != null) {
      return user;
    }

    // Schedule regular update from user's relays
    if (!_needUpdatePubKeys.contains(pubkey) &&
        !_handingPubkeys.containsKey(pubkey)) {
      _needUpdatePubKeys.add(pubkey);
    }
    later(_laterCallback);
    
    // For users not found in cache, also try reliable relays
    if (tryReliableRelays) {
      // Launch the reliable relay lookup in the background
      // This won't block the UI and will update the cache when data arrives
      _initiateReliableRelayLookup(pubkey);
    }

    return null;
  }
  
  /// Initiates a background lookup for a user on reliable relays
  void _initiateReliableRelayLookup(String pubkey) {
    // Use Future.microtask to avoid blocking the UI thread
    Future.microtask(() async {
      // Don't start another lookup if we're already handling this pubkey
      if (_handingPubkeys.containsKey(pubkey)) {
        return;
      }
      
      // Mark this pubkey as being handled
      _handingPubkeys[pubkey] = 1;
      
      // Try to fetch the profile from reliable relays
      await fetchUserProfileFromReliableRelays(pubkey);
      
      // If the lookup completes without finding anything,
      // _handingPubkeys will be cleared in _processSingleMetadataEvent
      // or will time out and remain in the handling state
    });
  }

  int getNip05Status(String pubkey) {
    var user = getUser(pubkey);

    if (PlatformUtil.isWeb()) {
      // web can't valid NIP05 due to cors
      if (user != null) {
        if (user.nip05 != null) {
          return Nip05Status.nip05Valid;
        }

        return Nip05Status.nip05Invalid;
      }

      return Nip05Status.nip05NotFound;
    }

    if (user == null) {
      return Nip05Status.metadataNotFound;
    } else if (StringUtil.isNotBlank(user.nip05)) {
      if (user.valid == null) {
        // Schedule NIP05 validation outside of any potential transaction
        Future.microtask(() async {
          try {
            final valid = await Nip05Validator.valid(user.nip05!, pubkey);
            if (valid != null) {
              if (valid) {
                user.valid = Nip05Status.nip05Valid;
                // Update the database with the validated user
                await DB.transaction((txn) async {
                  await UserDB.update(user, db: txn);
                });
              } else {
                // only update cache, next open app will validate again
                user.valid = Nip05Status.nip05Invalid;
              }
              notifyListeners();
            }
          } catch (e) {
            // Handle validation errors
            print("NIP05 validation error: $e");
          }
        });

        return Nip05Status.nip05Invalid;
      } else if (user.valid! == Nip05Status.nip05Valid) {
        return Nip05Status.nip05Valid;
      }

      return Nip05Status.nip05Invalid;
    }

    return Nip05Status.nip05NotFound;
  }

  final EventMemBox _pendingEvents = EventMemBox(sortAfterAdd: false);

  Future<void> _handlePendingEvents() async {
    final events = _pendingEvents.all();
    if (events.isEmpty) {
      return;
    }
    
    // Process events in batches to reduce transaction overhead
    const batchSize = 10;
    for (var i = 0; i < events.length; i += batchSize) {
      final end = (i + batchSize < events.length) ? i + batchSize : events.length;
      final batch = events.sublist(i, end);
      
      // Process this batch in a transaction
      await DB.transaction((txn) async {
        for (var event in batch) {
          if (event.kind == EventKind.metadata) {
            if (StringUtil.isBlank(event.content)) {
              continue;
            }

            _handingPubkeys.remove(event.pubkey);

            var jsonObj = jsonDecode(event.content);
            var user = User.fromJson(jsonObj);
            user.pubkey = event.pubkey;
            user.updatedAt = event.createdAt;

            // check cache
            final oldUser = _userCache[user.pubkey];
            if (oldUser == null) {
              // db - use the transaction
              await UserDB.insert(user, db: txn);
              // cache
              _userCache[user.pubkey!] = user;
              // refresh
            } else if (oldUser.updatedAt! < user.updatedAt!) {
              // db - use the transaction
              await UserDB.update(user, db: txn);
              // cache
              _userCache[user.pubkey!] = user;
              // refresh
            }
          } else if (event.kind == EventKind.relayListMetadata) {
            // this is relayInfoMetadata, only set to cache, not update UI
            var oldRelayListMetadata = _relayListMetadataCache[event.pubkey];
            if (oldRelayListMetadata == null) {
              // insert - use transaction
              await EventDB.insert(Base.defaultDataIndex, event, db: txn);
              _eventToRelayListCache(event);
            } else if (event.createdAt > oldRelayListMetadata.createdAt) {
              // update, remove old event and insert new event - use transaction
              await txn.execute(
                  "delete from event where key_index = ? and kind = ? and pubkey = ?",
                  [
                    Base.defaultDataIndex,
                    EventKind.relayListMetadata,
                    event.pubkey
                  ]);
              await EventDB.insert(Base.defaultDataIndex, event, db: txn);
              _eventToRelayListCache(event);
            }
          } else if (event.kind == EventKind.contactList) {
            var oldContactList = _contactListMap[event.pubkey];
            if (oldContactList == null) {
              // insert - use transaction
              await EventDB.insert(Base.defaultDataIndex, event, db: txn);
              _eventToContactList(event);
            } else if (event.createdAt > oldContactList.createdAt) {
              // update, remove old event and insert new event - use transaction
              await txn.execute(
                  "delete from event where key_index = ? and kind = ? and pubkey = ?",
                  [Base.defaultDataIndex, EventKind.contactList, event.pubkey]);
              await EventDB.insert(Base.defaultDataIndex, event, db: txn);
              _eventToContactList(event);
            }
          }
        } // end for loop over batch
      }); // end transaction
    } // end for loop over batches
    
    _pendingEvents.clear();
    notifyListeners();
  }

  void onEvent(Event event) {
    _pendingEvents.add(event);
    later(_laterCallback);
  }

  void _laterSearch() {
    if (_needUpdatePubKeys.isEmpty) {
      return;
    }

    // if (!nostr!.readable()) {
    //   // the nostr isn't readable later handle it again.
    //   later(_laterCallback, null);
    //   return;
    // }

    List<Map<String, dynamic>> filters = [];
    for (var pubkey in _needUpdatePubKeys) {
      {
        var filter = Filter(
          kinds: [
            EventKind.metadata,
          ],
          authors: [pubkey],
          limit: 1,
        );
        filters.add(filter.toJson());
      }
      {
        var filter = Filter(
          kinds: [
            EventKind.relayListMetadata,
          ],
          authors: [pubkey],
          limit: 1,
        );
        filters.add(filter.toJson());
      }
      {
        var filter = Filter(
          kinds: [
            EventKind.contactList,
          ],
          authors: [pubkey],
          limit: 1,
        );
        filters.add(filter.toJson());
      }
      if (filters.length > 20) {
        nostr!.query(filters, onEvent);
        filters = [];
      }
    }
    if (filters.isNotEmpty) {
      nostr!.query(filters, onEvent);
    }

    for (var pubkey in _needUpdatePubKeys) {
      _handingPubkeys[pubkey] = 1;
    }
    _needUpdatePubKeys.clear();
  }

  void clear() {
    _userCache.clear();
    UserDB.deleteAll();
  }

  ContactList? getContactList(String pubkey) {
    return _contactListMap[pubkey];
  }

  RelayListMetadata? getRelayListMetadata(String pubkey) {
    return _relayListMetadataCache[pubkey];
  }

  void _eventToRelayListCache(Event event) {
    RelayListMetadata rlm = RelayListMetadata.fromEvent(event);
    _relayListMetadataCache[rlm.pubkey] = rlm;
  }

  void _eventToContactList(Event event) {
    var contactList = ContactList.fromJson(event.tags, event.createdAt);
    _contactListMap[event.pubkey] = contactList;
  }

  List<String> getExtralRelays(String pubkey, bool isWrite) {
    List<String> tempRelays = [];
    var relayListMetadata = userProvider.getRelayListMetadata(pubkey);
    if (relayListMetadata != null) {
      late List<String> relays;
      if (isWrite) {
        relays = relayListMetadata.writeAbleRelays;
      } else {
        relays = relayListMetadata.readAbleRelays;
      }
      tempRelays = nostr!.getExtralReadableRelays(relays, 3);
    }
    return tempRelays;
  }
  
  /// Fetches a user's metadata (kind 0) from specific reliable relays.
  /// 
  /// This method is used when a user's profile is missing or needs to be refreshed.
  /// It makes a targeted request to known reliable relays (purplepag.es and relay.nos.social)
  /// to fetch the latest user metadata.
  /// 
  /// The method doesn't lock up the UI and will automatically update the user's data
  /// in the cache and database once received.
  /// 
  /// @param pubkey The public key of the user whose metadata needs to be fetched
  /// @return A Future<bool> that resolves to true if the profile was found, false otherwise
  Future<bool> fetchUserProfileFromReliableRelays(String pubkey) async {
    if (pubkey.isEmpty) {
      return false;
    }
    
    // Create a completer to manage the async result
    final completer = Completer<bool>();
    
    // Define reliable relays that are more likely to have user metadata
    final reliableRelays = [
      "wss://purplepag.es",
      "wss://relay.nos.social"
    ];
    
    // Create a filter specifically for kind 0 (metadata) events from this user
    final filters = [
      Filter(
        kinds: [EventKind.metadata],
        authors: [pubkey],
        limit: 1,
      ).toJson()
    ];
    
    var found = false;
    
    // Set a timeout to resolve the completer if no data comes back
    Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.complete(found);
      }
    });
    
    // Make the query to the specific relays
    nostr!.query(
      filters,
      (event) {
        // We found a metadata event, process it
        if (event.kind == EventKind.metadata && event.pubkey == pubkey) {
          found = true;
          
          // Process the event and update cache/DB
          _processSingleMetadataEvent(event);
          
          // If we haven't completed yet, complete with success
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        }
      },
      tempRelays: reliableRelays,
      targetRelays: reliableRelays,
      onComplete: () {
        // Query completed without finding data
        if (!completer.isCompleted) {
          completer.complete(found);
        }
      },
    );
    
    return completer.future;
  }
  
  /// Process a single metadata event and update user data accordingly
  void _processSingleMetadataEvent(Event event) {
    if (event.kind != EventKind.metadata || StringUtil.isBlank(event.content)) {
      return;
    }
    
    try {
      var jsonObj = jsonDecode(event.content);
      var user = User.fromJson(jsonObj);
      user.pubkey = event.pubkey;
      user.updatedAt = event.createdAt;
      
      // Check if we already have this user in cache
      final oldUser = _userCache[user.pubkey];
      
      if (oldUser == null) {
        // New user, insert into DB and cache
        UserDB.insert(user);
        _userCache[user.pubkey!] = user;
      } else if (oldUser.updatedAt! < user.updatedAt!) {
        // User exists but we have newer data, update
        UserDB.update(user);
        _userCache[user.pubkey!] = user;
      }
      
      // Remove this pubkey from the pending list
      _handingPubkeys.remove(event.pubkey);
      
      // Notify listeners that we've updated user data
      notifyListeners();
    } catch (e) {
      debugPrint("Error processing metadata event: $e");
    }
  }
}
