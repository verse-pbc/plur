
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/widgets.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../generated/l10n.dart';
import '../main.dart';
import 'lightning_util.dart';

class ZapAction {
  /// zap to single pubkey.
  static Future<void> handleZap(BuildContext context, int sats, String pubkey,
      {String? eventId, String? pollOption, String? comment}) async {
    final localization = S.of(context);
    var cancelFunc = BotToast.showLoading();
    try {
      var invoiceCode = await _doGenInvoiceCode(context, sats, pubkey,
          eventId: eventId, pollOption: pollOption, comment: comment);

      if (StringUtil.isBlank(invoiceCode)) {
        BotToast.showText(text: localization.genInvoiceCodeError);
        return;
      }

      if (!context.mounted) return;
      await LightningUtil.goToPay(context, invoiceCode!, zapNum: sats);
    } finally {
      cancelFunc.call();
    }
  }

  static Future<String?> genInvoiceCode(
      BuildContext context, int sats, String pubkey,
      {String? eventId, String? pollOption, String? comment}) async {
    var cancelFunc = BotToast.showLoading();
    try {
      return await _doGenInvoiceCode(context, sats, pubkey,
          eventId: eventId, pollOption: pollOption, comment: comment);
    } finally {
      cancelFunc.call();
    }
  }

  static Future<String?> _doGenInvoiceCode(
      BuildContext context, int sats, String pubkey,
      {String? eventId, String? pollOption, String? comment}) async {
    final localization = S.of(context);
    final user = userProvider.getUser(pubkey);
    if (user == null) {
      BotToast.showText(text: localization.metadataCanNotBeFound);
      return null;
    }

    var relays = relayProvider.relayAddrs;

    // lud06 like: LNURL1DP68GURN8GHJ7MRW9E6XJURN9UH8WETVDSKKKMN0WAHZ7MRWW4EXCUP0XPURJCEKXVERVDEJXCMKYDFHV43KX2HK8GT
    // lud16 like: pavol@rusnak.io
    // but some people set lud16 to lud06
    String? lnurl = user.lud06;
    String? lud16Link;

    if (StringUtil.isBlank(lnurl)) {
      if (StringUtil.isNotBlank(user.lud16)) {
        lnurl = Zap.getLnurlFromLud16(user.lud16!);
      }
    }
    if (StringUtil.isBlank(lnurl)) {
      BotToast.showText(text: "Lnurl ${localization.notFound}");
      return null;
    }
    // check if user set wrong
    if (lnurl!.contains("@")) {
      lnurl = Zap.getLnurlFromLud16(user.lud16!);
    }

    if (StringUtil.isBlank(lud16Link)) {
      if (StringUtil.isNotBlank(user.lud16)) {
        lud16Link = Zap.getLud16LinkFromLud16(user.lud16!);
      }
    }
    if (StringUtil.isBlank(lud16Link)) {
      if (StringUtil.isNotBlank(user.lud06)) {
        lud16Link = Zap.decodeLud06Link(user.lud06!);
      }
    }

    return await Zap.getInvoiceCode(
      lnurl: lnurl!,
      lud16Link: lud16Link!,
      sats: sats,
      recipientPubkey: pubkey,
      targetNostr: nostr!,
      relays: relays,
      eventId: eventId,
      pollOption: pollOption,
      comment: comment,
    );
  }
}
