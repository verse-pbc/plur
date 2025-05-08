import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/event/event_id_router_widget.dart';
import 'package:nostrmo/data/join_group_parameters.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/provider/relay_provider.dart';
import 'package:provider/provider.dart';

import '../consts/router_path.dart';
import '../util/router_util.dart';
import 'content/content_widget.dart';
import 'webview_widget.dart';

/// Utility class for handling all types of deep links and navigation based on URLs.
class LinkRouterUtil {
  /// Main entry point for processing URLs/links from any source
  static void router(BuildContext context, String link) {
    log('Router processing link: $link', name: 'DeepLink');
    
    // Handle Universal Links from chus.me, rabble.communities, or rabble.community domain
    if (link.startsWith("https://chus.me") || link.startsWith("https://rabble.communities") || link.startsWith("https://rabble.community")) {
      _handleCommunityLink(context, link);
      return;
    }
    
    // Handle plur:// protocol links
    if (link.startsWith("plur://")) {
      try {
        Uri uri = Uri.parse(link);
        
        if (uri.host == "join-community") {
          String? groupId = uri.queryParameters['group-id'];
          String? code = uri.queryParameters['code'];
          String? relay = uri.queryParameters['relay'];
          
          if (groupId != null && groupId.isNotEmpty) {
            _joinGroup(context, relay ?? RelayProvider.defaultGroupsRelayAddress, groupId, code);
            return;
          }
        } else if (uri.host == "group") {
          // Handle direct group navigation format plur://group/{groupId}
          List<String> pathSegments = uri.pathSegments;
          if (pathSegments.isNotEmpty) {
            String groupId = pathSegments[0];
            String? relay = uri.queryParameters['relay'];
            String? code = uri.queryParameters['code'];
            
            _joinGroup(context, relay ?? RelayProvider.defaultGroupsRelayAddress, groupId, code);
            return;
          }
        }
      } catch (e) {
        log('Error parsing plur:// URL: $e', name: 'DeepLink');
      }
    }
    
    // Handle rabble:// protocol links
    if (link.startsWith("rabble://")) {
      try {
        Uri uri = Uri.parse(link);
        
        if (uri.host == "invite") {
          List<String> pathSegments = uri.pathSegments;
          if (pathSegments.isNotEmpty) {
            String code = pathSegments[0];
            log('Received rabble://invite/$code shortcode - this requires API access', name: 'DeepLink');
            // Note: API-based code resolution is handled in native code on iOS
            // For Android we would need to implement the API call here
            return;
          }
        }
      } catch (e) {
        log('Error parsing rabble:// URL: $e', name: 'DeepLink');
      }
    }
    
    // Handle normal http links
    if (link.startsWith("http")) {
      WebViewWidget.open(context, link);
      return;
    }

    // Handle Nostr-specific links
    _handleNostrFormat(context, link);
  }
  
  /// Handle Nostr-specific link formats
  static void _handleNostrFormat(BuildContext context, String link) {
    var key = link.replaceFirst("nostr:", "");

    if (Nip19.isPubkey(key)) {
      if (key.length > npubLength) {
        key = key.substring(0, npubLength);
      }
      key = Nip19.decode(key);
      RouterUtil.router(context, RouterPath.user, key);
    } else if (Nip19.isNoteId(key)) {
      if (key.length > noteIdLength) {
        key = key.substring(0, noteIdLength);
      }
      key = Nip19.decode(key);
      RouterUtil.router(context, RouterPath.threadTrace, key);
    } else if (NIP19Tlv.isNprofile(key)) {
      var index = Nip19.checkBech32End(key);
      if (index != null) {
        key = key.substring(0, index);
      }

      var nprofile = NIP19Tlv.decodeNprofile(key);
      if (nprofile != null) {
        RouterUtil.router(context, RouterPath.user, nprofile.pubkey);
      }
    } else if (NIP19Tlv.isNevent(key)) {
      var index = Nip19.checkBech32End(key);
      if (index != null) {
        key = key.substring(0, index);
      }

      var nevent = NIP19Tlv.decodeNevent(key);
      if (nevent != null) {
        var relayAddr = (nevent.relays != null && nevent.relays!.isNotEmpty)
            ? nevent.relays![0]
            : null;
        EventIdRouterWidget.router(context, nevent.id, relayAddr: relayAddr);
      }
    } else if (NIP19Tlv.isNaddr(key)) {
      var index = Nip19.checkBech32End(key);
      if (index != null) {
        key = key.substring(0, index);
      }

      var naddr = NIP19Tlv.decodeNaddr(key);
      if (naddr != null) {
        if (naddr.kind == EventKind.textNote &&
            StringUtil.isNotBlank(naddr.id)) {
          var relayAddr = (naddr.relays != null && naddr.relays!.isNotEmpty)
              ? naddr.relays![0]
              : null;
          EventIdRouterWidget.router(context, naddr.id,
              relayAddr: relayAddr);
        } else if (naddr.kind == EventKind.longForm &&
            StringUtil.isNotBlank(naddr.id)) {
          // TODO load long form
        } else if (StringUtil.isNotBlank(naddr.author) &&
            naddr.kind == EventKind.metadata) {
          RouterUtil.router(context, RouterPath.user, naddr.author);
        }
      }
    }
  }
  
  /// Handle community links (Universal Links) from rabble.community domains
  static void _handleCommunityLink(BuildContext context, String link) {
    try {
      log('Processing community link: $link', name: 'DeepLink');
      
      Uri uri = Uri.parse(link);
      List<String> pathSegments = uri.pathSegments;
      
      // Handle different path structures
      if (pathSegments.isNotEmpty) {
        // 1. Handle /i/{code} pattern for API-based invites
        if (pathSegments.length >= 2 && pathSegments[0] == 'i') {
          String pathSegment = pathSegments[1];
          
          // Check if it's a direct protocol URL embedded in the universal link
          if (pathSegment.startsWith('plur://')) {
            // Process the embedded protocol URL
            router(context, pathSegment);
          } else {
            // Simple invite code - this is typically handled in native code
            // but we could implement the API call here for Android
            log('Received API based invite shortcode: $pathSegment', name: 'DeepLink');
          }
          return;
        }
        
        // 2. Handle /join/{group-id} format
        else if (pathSegments.length >= 2 && pathSegments[0] == 'join') {
          String groupId = pathSegments[1];
          String? code = uri.queryParameters['code'];
          String? relay = uri.queryParameters['relay'];
          
          _joinGroup(context, relay ?? RelayProvider.defaultGroupsRelayAddress, groupId, code);
          return;
        }
        
        // 3. Handle /join-community?group-id=X format
        else if (pathSegments.contains('join-community') || pathSegments[0] == 'join-community') {
          String? groupId = uri.queryParameters['group-id'];
          String? code = uri.queryParameters['code'];
          String? relay = uri.queryParameters['relay'];
          
          if (groupId == null || groupId.isEmpty) {
            log('Group ID is null or empty in Universal Link, aborting.', name: 'DeepLink');
            return;
          }
          
          _joinGroup(context, relay ?? RelayProvider.defaultGroupsRelayAddress, groupId, code);
          return;
        }
        
        // 4. Handle /g/{group-id} pattern (direct group navigation)
        else if (pathSegments.length >= 2 && pathSegments[0] == 'g') {
          String groupId = pathSegments[1];
          String? code = uri.queryParameters['code'];
          String? relay = uri.queryParameters['relay'];
          
          _joinGroup(context, relay ?? RelayProvider.defaultGroupsRelayAddress, groupId, code);
          return;
        }
      }
      
      // If we got here, no special handling was applied - open as a web page
      WebViewWidget.open(context, link);
      
    } catch (e) {
      log('Error processing community link: $e', name: 'DeepLink');
      // Fallback to web view if we can't parse the URL
      WebViewWidget.open(context, link);
    }
  }
  
  /// Process a community join action with the given parameters
  static void _joinGroup(
    BuildContext context,
    String host,
    String groupId,
    String? code,
  ) {
    log('Joining group - ID: $groupId, Host: $host, Code: ${code ?? "none"}', name: 'DeepLink');
    
    try {
      final listProvider = Provider.of<ListProvider>(context, listen: false);
      final groupIdentifier = JoinGroupParameters(host, groupId, code: code);
      listProvider.joinGroup(groupIdentifier, context: context);
    } catch (e) {
      log('Error joining group: $e', name: 'DeepLink');
    }
  }
}
