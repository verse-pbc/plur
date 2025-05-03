import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_ar.dart';
import 'l10n_bg.dart';
import 'l10n_cs.dart';
import 'l10n_da.dart';
import 'l10n_de.dart';
import 'l10n_el.dart';
import 'l10n_en.dart';
import 'l10n_es.dart';
import 'l10n_et.dart';
import 'l10n_fi.dart';
import 'l10n_fr.dart';
import 'l10n_hi.dart';
import 'l10n_hu.dart';
import 'l10n_it.dart';
import 'l10n_ja.dart';
import 'l10n_ko.dart';
import 'l10n_nl.dart';
import 'l10n_pl.dart';
import 'l10n_pt.dart';
import 'l10n_ro.dart';
import 'l10n_ru.dart';
import 'l10n_sl.dart';
import 'l10n_sv.dart';
import 'l10n_th.dart';
import 'l10n_vi.dart';
import 'l10n_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bg'),
    Locale('cs'),
    Locale('da'),
    Locale('de'),
    Locale('el'),
    Locale('en'),
    Locale('es'),
    Locale('et'),
    Locale('fi'),
    Locale('fr'),
    Locale('hi'),
    Locale('hu'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('ro'),
    Locale('ru'),
    Locale('sl'),
    Locale('sv'),
    Locale('th'),
    Locale('vi'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @confirmDiscard.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to discard unsaved changes?'**
  String get confirmDiscard;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @communities.
  ///
  /// In en, this message translates to:
  /// **'Communities'**
  String get communities;

  /// No description provided for @communityGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Community Guidelines'**
  String get communityGuidelines;

  /// No description provided for @postingTo.
  ///
  /// In en, this message translates to:
  /// **'Posting to'**
  String get postingTo;

  /// No description provided for @newPost.
  ///
  /// In en, this message translates to:
  /// **'New Post'**
  String get newPost;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get followSystem;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @alertsAvailable.
  ///
  /// In en, this message translates to:
  /// **'ICE WATCH ALERTS'**
  String get alertsAvailable;

  /// No description provided for @noRecentPosts.
  ///
  /// In en, this message translates to:
  /// **'No recent posts...'**
  String get noRecentPosts;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @defaultColor.
  ///
  /// In en, this message translates to:
  /// **'Default Color'**
  String get defaultColor;

  /// No description provided for @customColor.
  ///
  /// In en, this message translates to:
  /// **'Custom Color'**
  String get customColor;

  /// No description provided for @imageCompress.
  ///
  /// In en, this message translates to:
  /// **'Image Compress'**
  String get imageCompress;

  /// No description provided for @dontCompress.
  ///
  /// In en, this message translates to:
  /// **'Don\'t Compress'**
  String get dontCompress;

  /// No description provided for @defaultFontFamily.
  ///
  /// In en, this message translates to:
  /// **'Default Font Family'**
  String get defaultFontFamily;

  /// No description provided for @customFontFamily.
  ///
  /// In en, this message translates to:
  /// **'Custom Font Family'**
  String get customFontFamily;

  /// No description provided for @privacyLock.
  ///
  /// In en, this message translates to:
  /// **'Privacy Lock'**
  String get privacyLock;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @face.
  ///
  /// In en, this message translates to:
  /// **'Face'**
  String get face;

  /// No description provided for @fingerprint.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint'**
  String get fingerprint;

  /// No description provided for @pleaseAuthenticateToTurnOffThePrivacyLock.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to turn off the privacy lock'**
  String get pleaseAuthenticateToTurnOffThePrivacyLock;

  /// No description provided for @pleaseAuthenticateToTurnOnThePrivacyLock.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to turn on the privacy lock'**
  String get pleaseAuthenticateToTurnOnThePrivacyLock;

  /// No description provided for @pleaseAuthenticateToUseApp.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to use app'**
  String get pleaseAuthenticateToUseApp;

  /// No description provided for @authenticatNeed.
  ///
  /// In en, this message translates to:
  /// **'Authenticat need'**
  String get authenticatNeed;

  /// No description provided for @verifyError.
  ///
  /// In en, this message translates to:
  /// **'Verify error'**
  String get verifyError;

  /// No description provided for @verifyFailure.
  ///
  /// In en, this message translates to:
  /// **'Verify failure'**
  String get verifyFailure;

  /// No description provided for @defaultIndex.
  ///
  /// In en, this message translates to:
  /// **'Default index'**
  String get defaultIndex;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @global.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get global;

  /// No description provided for @defaultTab.
  ///
  /// In en, this message translates to:
  /// **'Default tab'**
  String get defaultTab;

  /// No description provided for @posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @postsAndReplies.
  ///
  /// In en, this message translates to:
  /// **'Posts & Replies'**
  String get postsAndReplies;

  /// No description provided for @mentions.
  ///
  /// In en, this message translates to:
  /// **'Mentions'**
  String get mentions;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @topics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get topics;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// No description provided for @linkPreview.
  ///
  /// In en, this message translates to:
  /// **'Link preview'**
  String get linkPreview;

  /// No description provided for @videoPreviewInList.
  ///
  /// In en, this message translates to:
  /// **'Video preview in list'**
  String get videoPreviewInList;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @networkTakeEffectTip.
  ///
  /// In en, this message translates to:
  /// **'The network will take effect the next time the app is launched'**
  String get networkTakeEffectTip;

  /// No description provided for @imageService.
  ///
  /// In en, this message translates to:
  /// **'Image service'**
  String get imageService;

  /// No description provided for @forbidImage.
  ///
  /// In en, this message translates to:
  /// **'Forbid image'**
  String get forbidImage;

  /// No description provided for @forbidVideo.
  ///
  /// In en, this message translates to:
  /// **'Forbid video'**
  String get forbidVideo;

  /// No description provided for @forbidProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Forbid profile picture'**
  String get forbidProfilePicture;

  /// No description provided for @pleaseInput.
  ///
  /// In en, this message translates to:
  /// **'Please input'**
  String get pleaseInput;

  /// No description provided for @notice.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get notice;

  /// No description provided for @writeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message'**
  String get writeAMessage;

  /// No description provided for @addToKnownList.
  ///
  /// In en, this message translates to:
  /// **'Add to known list'**
  String get addToKnownList;

  /// No description provided for @buyMeACoffee.
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee!'**
  String get buyMeACoffee;

  /// No description provided for @donate.
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get donate;

  /// No description provided for @whatsHappening.
  ///
  /// In en, this message translates to:
  /// **'What\'s happening?'**
  String get whatsHappening;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get send;

  /// No description provided for @pleaseInputEventId.
  ///
  /// In en, this message translates to:
  /// **'Please input event id'**
  String get pleaseInputEventId;

  /// No description provided for @pleaseInputUserPubkey.
  ///
  /// In en, this message translates to:
  /// **'Please input user pubkey'**
  String get pleaseInputUserPubkey;

  /// No description provided for @pleaseInputLnbcText.
  ///
  /// In en, this message translates to:
  /// **'Please input lnbc text'**
  String get pleaseInputLnbcText;

  /// No description provided for @pleaseInputTopicText.
  ///
  /// In en, this message translates to:
  /// **'Please input Topic text'**
  String get pleaseInputTopicText;

  /// No description provided for @textCantContainBlankSpace.
  ///
  /// In en, this message translates to:
  /// **'Text can\'t contain blank space'**
  String get textCantContainBlankSpace;

  /// No description provided for @textCantContainNewLine.
  ///
  /// In en, this message translates to:
  /// **'Text can\'t contain new line'**
  String get textCantContainNewLine;

  /// No description provided for @replied.
  ///
  /// In en, this message translates to:
  /// **'replied'**
  String get replied;

  /// No description provided for @boosted.
  ///
  /// In en, this message translates to:
  /// **'boosted'**
  String get boosted;

  /// No description provided for @liked.
  ///
  /// In en, this message translates to:
  /// **'liked'**
  String get liked;

  /// No description provided for @viewKey.
  ///
  /// In en, this message translates to:
  /// **'view key'**
  String get viewKey;

  /// No description provided for @keyHasBeenCopy.
  ///
  /// In en, this message translates to:
  /// **'The key has been copied!'**
  String get keyHasBeenCopy;

  /// No description provided for @inputDirtyword.
  ///
  /// In en, this message translates to:
  /// **'Input dirtyword.'**
  String get inputDirtyword;

  /// No description provided for @wordCantBeNull.
  ///
  /// In en, this message translates to:
  /// **'Word can\'t be null.'**
  String get wordCantBeNull;

  /// No description provided for @blocks.
  ///
  /// In en, this message translates to:
  /// **'Blocks'**
  String get blocks;

  /// No description provided for @dirtywords.
  ///
  /// In en, this message translates to:
  /// **'Dirtywords'**
  String get dirtywords;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'loading'**
  String get loading;

  /// No description provided for @accountManager.
  ///
  /// In en, this message translates to:
  /// **'Account Manager'**
  String get accountManager;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get addAccount;

  /// No description provided for @inputAccountPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Input account private key'**
  String get inputAccountPrivateKey;

  /// No description provided for @addAccountAndLogin.
  ///
  /// In en, this message translates to:
  /// **'Add account and login?'**
  String get addAccountAndLogin;

  /// No description provided for @wrongPrivateKeyFormat.
  ///
  /// In en, this message translates to:
  /// **'Wrong Private Key format'**
  String get wrongPrivateKeyFormat;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @relays.
  ///
  /// In en, this message translates to:
  /// **'Relays'**
  String get relays;

  /// No description provided for @pleaseDoNotDiscloseOrShareTheKeyToAnyone.
  ///
  /// In en, this message translates to:
  /// **'Please do not disclose or share the key to anyone.'**
  String get pleaseDoNotDiscloseOrShareTheKeyToAnyone;

  /// No description provided for @nostrmoDevelopersWillNeverRequireAKeyFromYou.
  ///
  /// In en, this message translates to:
  /// **'Nostrmo developers will never require a key from you.'**
  String get nostrmoDevelopersWillNeverRequireAKeyFromYou;

  /// No description provided for @pleaseKeepTheKeyProperlyForAccountRecovery.
  ///
  /// In en, this message translates to:
  /// **'Please keep the key properly for account recovery.'**
  String get pleaseKeepTheKeyProperlyForAccountRecovery;

  /// No description provided for @backupAndSafetyTips.
  ///
  /// In en, this message translates to:
  /// **'Backup and Safety tips'**
  String get backupAndSafetyTips;

  /// No description provided for @theKeyIsARandomStringThatResembles.
  ///
  /// In en, this message translates to:
  /// **'The key is a random string that resembles your account password. Anyone with this key can access and control your account.'**
  String get theKeyIsARandomStringThatResembles;

  /// No description provided for @copyKey.
  ///
  /// In en, this message translates to:
  /// **'Copy Key'**
  String get copyKey;

  /// No description provided for @copyAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Copy & Continue'**
  String get copyAndContinue;

  /// No description provided for @copyHexKey.
  ///
  /// In en, this message translates to:
  /// **'Copy Hex Key'**
  String get copyHexKey;

  /// No description provided for @pleaseCheckTheTips.
  ///
  /// In en, this message translates to:
  /// **'Please check the tips.'**
  String get pleaseCheckTheTips;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @yourPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Your private key'**
  String get yourPrivateKey;

  /// No description provided for @generateANewPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Generate a new private key'**
  String get generateANewPrivateKey;

  /// No description provided for @acceptTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you accept our <accent>terms of service</accent>'**
  String get acceptTermsOfService;

  /// No description provided for @thisIsTheKeyToYourAccount.
  ///
  /// In en, this message translates to:
  /// **'This is the key to your account'**
  String get thisIsTheKeyToYourAccount;

  /// No description provided for @iUnderstandIShouldntShareThisKey.
  ///
  /// In en, this message translates to:
  /// **'I understand that I should not share this key with anyone, and I should back it up safely (e.g. in a password manager).'**
  String get iUnderstandIShouldntShareThisKey;

  /// No description provided for @privateKeyIsNull.
  ///
  /// In en, this message translates to:
  /// **'Private key is null.'**
  String get privateKeyIsNull;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @picture.
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get picture;

  /// No description provided for @banner.
  ///
  /// In en, this message translates to:
  /// **'Banner'**
  String get banner;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @nip05.
  ///
  /// In en, this message translates to:
  /// **'Nip05'**
  String get nip05;

  /// No description provided for @lud16.
  ///
  /// In en, this message translates to:
  /// **'Lud16'**
  String get lud16;

  /// No description provided for @inputRelayAddress.
  ///
  /// In en, this message translates to:
  /// **'Input relay address.'**
  String get inputRelayAddress;

  /// No description provided for @addressCantBeNull.
  ///
  /// In en, this message translates to:
  /// **'Address can\'t be null.'**
  String get addressCantBeNull;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @emptyTextMayBeBanByRelays.
  ///
  /// In en, this message translates to:
  /// **'Empty text may be ban by relays.'**
  String get emptyTextMayBeBanByRelays;

  /// No description provided for @noteLoading.
  ///
  /// In en, this message translates to:
  /// **'Note loading...'**
  String get noteLoading;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read;

  /// No description provided for @write.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get write;

  /// No description provided for @copyCurrentUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy current Url'**
  String get copyCurrentUrl;

  /// No description provided for @copyInitUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy init Url'**
  String get copyInitUrl;

  /// No description provided for @openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get openInBrowser;

  /// No description provided for @copySuccess.
  ///
  /// In en, this message translates to:
  /// **'Copy success!'**
  String get copySuccess;

  /// No description provided for @boost.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get boost;

  /// No description provided for @quote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get quote;

  /// No description provided for @replying.
  ///
  /// In en, this message translates to:
  /// **'Replying'**
  String get replying;

  /// No description provided for @copyNoteJson.
  ///
  /// In en, this message translates to:
  /// **'Copy Note Json'**
  String get copyNoteJson;

  /// No description provided for @copyNotePubkey.
  ///
  /// In en, this message translates to:
  /// **'Copy Note Pubkey'**
  String get copyNotePubkey;

  /// No description provided for @copyNoteId.
  ///
  /// In en, this message translates to:
  /// **'Copy Note Id'**
  String get copyNoteId;

  /// No description provided for @detail.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get detail;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @broadcast.
  ///
  /// In en, this message translates to:
  /// **'Broadcast'**
  String get broadcast;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @metadataCanNotBeFound.
  ///
  /// In en, this message translates to:
  /// **'Metadata can not be found.'**
  String get metadataCanNotBeFound;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'not found'**
  String get notFound;

  /// No description provided for @genInvoiceCodeError.
  ///
  /// In en, this message translates to:
  /// **'Gen invoice code error.'**
  String get genInvoiceCodeError;

  /// No description provided for @notices.
  ///
  /// In en, this message translates to:
  /// **'Notices'**
  String get notices;

  /// No description provided for @pleaseInputSearchContent.
  ///
  /// In en, this message translates to:
  /// **'Please input search content'**
  String get pleaseInputSearchContent;

  /// No description provided for @openUserPage.
  ///
  /// In en, this message translates to:
  /// **'Open User page'**
  String get openUserPage;

  /// No description provided for @openNoteDetail.
  ///
  /// In en, this message translates to:
  /// **'Open Note detail'**
  String get openNoteDetail;

  /// No description provided for @searchUserFromCache.
  ///
  /// In en, this message translates to:
  /// **'Search User from cache'**
  String get searchUserFromCache;

  /// No description provided for @openEventFromCache.
  ///
  /// In en, this message translates to:
  /// **'Open Event from cache'**
  String get openEventFromCache;

  /// No description provided for @searchPubkeyEvent.
  ///
  /// In en, this message translates to:
  /// **'Search pubkey event'**
  String get searchPubkeyEvent;

  /// No description provided for @searchNoteContent.
  ///
  /// In en, this message translates to:
  /// **'Search note content'**
  String get searchNoteContent;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTips.
  ///
  /// In en, this message translates to:
  /// **'We will try to delete you infomation. When you login with this Key again, you will lose your data.'**
  String get deleteAccountTips;

  /// No description provided for @lnurlAndLud16CantFound.
  ///
  /// In en, this message translates to:
  /// **'Lnurl and Lud16 can\'t found.'**
  String get lnurlAndLud16CantFound;

  /// No description provided for @addNow.
  ///
  /// In en, this message translates to:
  /// **'Add now'**
  String get addNow;

  /// No description provided for @inputSatsNumToGenLightningInvoice.
  ///
  /// In en, this message translates to:
  /// **'Input Sats num to gen lightning invoice'**
  String get inputSatsNumToGenLightningInvoice;

  /// No description provided for @inputSatsNum.
  ///
  /// In en, this message translates to:
  /// **'Input Sats num'**
  String get inputSatsNum;

  /// No description provided for @numberParseError.
  ///
  /// In en, this message translates to:
  /// **'Number parse error'**
  String get numberParseError;

  /// No description provided for @input.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get input;

  /// No description provided for @topic.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get topic;

  /// No description provided for @noteId.
  ///
  /// In en, this message translates to:
  /// **'Note Id'**
  String get noteId;

  /// No description provided for @userPubkey.
  ///
  /// In en, this message translates to:
  /// **'User Pubkey'**
  String get userPubkey;

  /// No description provided for @translate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get translate;

  /// No description provided for @translateSourceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Translate Source Language'**
  String get translateSourceLanguage;

  /// No description provided for @translateTargetLanguage.
  ///
  /// In en, this message translates to:
  /// **'Translate Target Language'**
  String get translateTargetLanguage;

  /// No description provided for @beginToDownloadTranslateModel.
  ///
  /// In en, this message translates to:
  /// **'Begin to download translate model'**
  String get beginToDownloadTranslateModel;

  /// No description provided for @uploadFail.
  ///
  /// In en, this message translates to:
  /// **'Upload fail.'**
  String get uploadFail;

  /// No description provided for @notesUpdated.
  ///
  /// In en, this message translates to:
  /// **'notes updated'**
  String get notesUpdated;

  /// No description provided for @addThisRelayToLocal.
  ///
  /// In en, this message translates to:
  /// **'Add this relay to local?'**
  String get addThisRelayToLocal;

  /// No description provided for @broadcastWhenBoost.
  ///
  /// In en, this message translates to:
  /// **'Broadcast When Boost'**
  String get broadcastWhenBoost;

  /// No description provided for @findCloudedRelayListDoYouWantToDownload.
  ///
  /// In en, this message translates to:
  /// **'Find clouded relay list, do you want to download it?'**
  String get findCloudedRelayListDoYouWantToDownload;

  /// No description provided for @inputCanNotBeNull.
  ///
  /// In en, this message translates to:
  /// **'Input can not be null'**
  String get inputCanNotBeNull;

  /// No description provided for @inputParseError.
  ///
  /// In en, this message translates to:
  /// **'Input parse error'**
  String get inputParseError;

  /// No description provided for @youHadVotedWith.
  ///
  /// In en, this message translates to:
  /// **'You had voted with'**
  String get youHadVotedWith;

  /// No description provided for @closeAt.
  ///
  /// In en, this message translates to:
  /// **'Close at'**
  String get closeAt;

  /// No description provided for @zapNumCanNotSmallerThen.
  ///
  /// In en, this message translates to:
  /// **'Zap num can not smaller then'**
  String get zapNumCanNotSmallerThen;

  /// No description provided for @zapNumCanNotBiggerThen.
  ///
  /// In en, this message translates to:
  /// **'Zap num can not bigger then'**
  String get zapNumCanNotBiggerThen;

  /// No description provided for @minZapNum.
  ///
  /// In en, this message translates to:
  /// **'min zap num'**
  String get minZapNum;

  /// No description provided for @maxZapNum.
  ///
  /// In en, this message translates to:
  /// **'max zap num'**
  String get maxZapNum;

  /// No description provided for @pollOptionInfo.
  ///
  /// In en, this message translates to:
  /// **'poll option info'**
  String get pollOptionInfo;

  /// No description provided for @addPollOption.
  ///
  /// In en, this message translates to:
  /// **'add poll option'**
  String get addPollOption;

  /// No description provided for @forbid.
  ///
  /// In en, this message translates to:
  /// **'Forbid'**
  String get forbid;

  /// No description provided for @signFail.
  ///
  /// In en, this message translates to:
  /// **'Sign fail'**
  String get signFail;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @useLightningWalletScanAndSendSats.
  ///
  /// In en, this message translates to:
  /// **'Use lightning wallet scan and send sats.'**
  String get useLightningWalletScanAndSendSats;

  /// No description provided for @any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// No description provided for @lightningInvoice.
  ///
  /// In en, this message translates to:
  /// **'Lightning Invoice'**
  String get lightningInvoice;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @thereShouldBeAnUniverseHere.
  ///
  /// In en, this message translates to:
  /// **'There should be an universe here'**
  String get thereShouldBeAnUniverseHere;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @addANote.
  ///
  /// In en, this message translates to:
  /// **'Add a Note'**
  String get addANote;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @beginToLoadContactHistory.
  ///
  /// In en, this message translates to:
  /// **'Begin to load Contact History'**
  String get beginToLoadContactHistory;

  /// No description provided for @recovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get recovery;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @imageSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Image save success'**
  String get imageSaveSuccess;

  /// No description provided for @sendFail.
  ///
  /// In en, this message translates to:
  /// **'Publish failed'**
  String get sendFail;

  /// No description provided for @showWeb.
  ///
  /// In en, this message translates to:
  /// **'Show web'**
  String get showWeb;

  /// No description provided for @webUtils.
  ///
  /// In en, this message translates to:
  /// **'Web Utils'**
  String get webUtils;

  /// No description provided for @inputComment.
  ///
  /// In en, this message translates to:
  /// **'Input Comment'**
  String get inputComment;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @notify.
  ///
  /// In en, this message translates to:
  /// **'Notify'**
  String get notify;

  /// No description provided for @contentWarning.
  ///
  /// In en, this message translates to:
  /// **'Content warning'**
  String get contentWarning;

  /// No description provided for @thisNoteContainsSensitiveContent.
  ///
  /// In en, this message translates to:
  /// **'This note contains sensitive content'**
  String get thisNoteContainsSensitiveContent;

  /// No description provided for @pleaseInputTitle.
  ///
  /// In en, this message translates to:
  /// **'Please input title'**
  String get pleaseInputTitle;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get hour;

  /// No description provided for @minute.
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get minute;

  /// No description provided for @addCustomEmoji.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Emoji'**
  String get addCustomEmoji;

  /// No description provided for @inputCustomEmojiName.
  ///
  /// In en, this message translates to:
  /// **'Input Custom Emoji Name'**
  String get inputCustomEmojiName;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @followedTags.
  ///
  /// In en, this message translates to:
  /// **'Followed Tags'**
  String get followedTags;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @followedCommunities.
  ///
  /// In en, this message translates to:
  /// **'Followed Communities'**
  String get followedCommunities;

  /// No description provided for @followed.
  ///
  /// In en, this message translates to:
  /// **'Followed'**
  String get followed;

  /// No description provided for @autoOpenSensitiveContent.
  ///
  /// In en, this message translates to:
  /// **'Auto Open Sensitive Content'**
  String get autoOpenSensitiveContent;

  /// No description provided for @goalAmountInSats.
  ///
  /// In en, this message translates to:
  /// **'Goal Amount In Sats'**
  String get goalAmountInSats;

  /// No description provided for @relayMode.
  ///
  /// In en, this message translates to:
  /// **'Relay Mode'**
  String get relayMode;

  /// No description provided for @eventSignCheck.
  ///
  /// In en, this message translates to:
  /// **'Event Sign Check'**
  String get eventSignCheck;

  /// No description provided for @fastMode.
  ///
  /// In en, this message translates to:
  /// **'Fast Mode'**
  String get fastMode;

  /// No description provided for @baseMode.
  ///
  /// In en, this message translates to:
  /// **'Base Mode'**
  String get baseMode;

  /// No description provided for @webRTCPermission.
  ///
  /// In en, this message translates to:
  /// **'WebRTC Permission'**
  String get webRTCPermission;

  /// No description provided for @nip07GetPublicKey.
  ///
  /// In en, this message translates to:
  /// **'Get Public Key'**
  String get nip07GetPublicKey;

  /// No description provided for @nip07SignEvent.
  ///
  /// In en, this message translates to:
  /// **'Sign Event'**
  String get nip07SignEvent;

  /// No description provided for @nip07GetRelays.
  ///
  /// In en, this message translates to:
  /// **'Get Relays'**
  String get nip07GetRelays;

  /// No description provided for @nip07Encrypt.
  ///
  /// In en, this message translates to:
  /// **'Encrypt'**
  String get nip07Encrypt;

  /// No description provided for @nip07Decrypt.
  ///
  /// In en, this message translates to:
  /// **'Decrypt'**
  String get nip07Decrypt;

  /// No description provided for @nip07Lightning.
  ///
  /// In en, this message translates to:
  /// **'Lightning payment'**
  String get nip07Lightning;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @limitNoteHeight.
  ///
  /// In en, this message translates to:
  /// **'Limit Note Height'**
  String get limitNoteHeight;

  /// No description provided for @addToPrivateBookmark.
  ///
  /// In en, this message translates to:
  /// **'Add to private bookmark'**
  String get addToPrivateBookmark;

  /// No description provided for @addToPublicBookmark.
  ///
  /// In en, this message translates to:
  /// **'Add to public bookmark'**
  String get addToPublicBookmark;

  /// No description provided for @removeFromPrivateBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove from private bookmark'**
  String get removeFromPrivateBookmark;

  /// No description provided for @removeFromPublicBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove from public bookmark'**
  String get removeFromPublicBookmark;

  /// No description provided for @private.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get private;

  /// No description provided for @public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get public;

  /// No description provided for @creator.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get creator;

  /// No description provided for @wear.
  ///
  /// In en, this message translates to:
  /// **'Wear'**
  String get wear;

  /// No description provided for @privateDMNotice.
  ///
  /// In en, this message translates to:
  /// **'Private Direct Message is a new message type that some clients do not yet support.'**
  String get privateDMNotice;

  /// No description provided for @localRelay.
  ///
  /// In en, this message translates to:
  /// **'Local Relay'**
  String get localRelay;

  /// No description provided for @myRelays.
  ///
  /// In en, this message translates to:
  /// **'My Relays'**
  String get myRelays;

  /// No description provided for @tempRelays.
  ///
  /// In en, this message translates to:
  /// **'Temp Relays'**
  String get tempRelays;

  /// No description provided for @url.
  ///
  /// In en, this message translates to:
  /// **'Url'**
  String get url;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @soft.
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get soft;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @relayInfo.
  ///
  /// In en, this message translates to:
  /// **'Relay Info'**
  String get relayInfo;

  /// No description provided for @dms.
  ///
  /// In en, this message translates to:
  /// **'DMs'**
  String get dms;

  /// No description provided for @closePrivateDM.
  ///
  /// In en, this message translates to:
  /// **'Close Private DM'**
  String get closePrivateDM;

  /// No description provided for @openPrivateDM.
  ///
  /// In en, this message translates to:
  /// **'Open Private DM'**
  String get openPrivateDM;

  /// No description provided for @imageOrVideo.
  ///
  /// In en, this message translates to:
  /// **'Image or Video'**
  String get imageOrVideo;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @takeVideo.
  ///
  /// In en, this message translates to:
  /// **'Take video'**
  String get takeVideo;

  /// No description provided for @customEmoji.
  ///
  /// In en, this message translates to:
  /// **'Custom Emoji'**
  String get customEmoji;

  /// No description provided for @emoji.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get emoji;

  /// No description provided for @mentionUser.
  ///
  /// In en, this message translates to:
  /// **'Mention User'**
  String get mentionUser;

  /// No description provided for @hashtag.
  ///
  /// In en, this message translates to:
  /// **'Hashtag'**
  String get hashtag;

  /// No description provided for @sensitiveContent.
  ///
  /// In en, this message translates to:
  /// **'Sensitive Content'**
  String get sensitiveContent;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @delaySend.
  ///
  /// In en, this message translates to:
  /// **'Delay Send'**
  String get delaySend;

  /// No description provided for @poll.
  ///
  /// In en, this message translates to:
  /// **'Poll'**
  String get poll;

  /// No description provided for @zapGoals.
  ///
  /// In en, this message translates to:
  /// **'Zap Goals'**
  String get zapGoals;

  /// No description provided for @dataSyncMode.
  ///
  /// In en, this message translates to:
  /// **'Data Sync Mode'**
  String get dataSyncMode;

  /// No description provided for @backupMyNotes.
  ///
  /// In en, this message translates to:
  /// **'Backup my notes'**
  String get backupMyNotes;

  /// No description provided for @importNotes.
  ///
  /// In en, this message translates to:
  /// **'Import notes'**
  String get importNotes;

  /// No description provided for @fileSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'File save success'**
  String get fileSaveSuccess;

  /// No description provided for @syncUpload.
  ///
  /// In en, this message translates to:
  /// **'Sync Upload'**
  String get syncUpload;

  /// No description provided for @uploadNum.
  ///
  /// In en, this message translates to:
  /// **'Upload num'**
  String get uploadNum;

  /// No description provided for @sendInterval.
  ///
  /// In en, this message translates to:
  /// **'Send interval'**
  String get sendInterval;

  /// No description provided for @selectRelayToUpload.
  ///
  /// In en, this message translates to:
  /// **'Select relay to upload'**
  String get selectRelayToUpload;

  /// No description provided for @pleaseSelectRelays.
  ///
  /// In en, this message translates to:
  /// **'Please select relays'**
  String get pleaseSelectRelays;

  /// No description provided for @followSet.
  ///
  /// In en, this message translates to:
  /// **'Follow set'**
  String get followSet;

  /// No description provided for @followSetNameEdit.
  ///
  /// In en, this message translates to:
  /// **'Follow set name edit'**
  String get followSetNameEdit;

  /// No description provided for @inputFollowSetName.
  ///
  /// In en, this message translates to:
  /// **'Input follow set name'**
  String get inputFollowSetName;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get editName;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @threadMode.
  ///
  /// In en, this message translates to:
  /// **'Thread Mode'**
  String get threadMode;

  /// No description provided for @maxSubNotes.
  ///
  /// In en, this message translates to:
  /// **'Max Sub Notes'**
  String get maxSubNotes;

  /// No description provided for @fullMode.
  ///
  /// In en, this message translates to:
  /// **'Full Mode'**
  String get fullMode;

  /// No description provided for @traceMode.
  ///
  /// In en, this message translates to:
  /// **'Trace Mode'**
  String get traceMode;

  /// No description provided for @pleaseInputTheMaxSubNotesNumber.
  ///
  /// In en, this message translates to:
  /// **'Please input the max sub notes number'**
  String get pleaseInputTheMaxSubNotesNumber;

  /// No description provided for @showMoreReplies.
  ///
  /// In en, this message translates to:
  /// **'Show more replies'**
  String get showMoreReplies;

  /// No description provided for @thisOperationCannotBeUndo.
  ///
  /// In en, this message translates to:
  /// **'This operation cannot be undo'**
  String get thisOperationCannotBeUndo;

  /// No description provided for @dataLength.
  ///
  /// In en, this message translates to:
  /// **'Data Length'**
  String get dataLength;

  /// No description provided for @fileSize.
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get fileSize;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllData;

  /// No description provided for @clearNotMyData.
  ///
  /// In en, this message translates to:
  /// **'Clear Not My Data'**
  String get clearNotMyData;

  /// No description provided for @fileIsTooBigForNIP95.
  ///
  /// In en, this message translates to:
  /// **'File is too big for NIP-95'**
  String get fileIsTooBigForNIP95;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @lightningAddress.
  ///
  /// In en, this message translates to:
  /// **'Lightning Address'**
  String get lightningAddress;

  /// No description provided for @hideRelayNotices.
  ///
  /// In en, this message translates to:
  /// **'Hide Relay Notices'**
  String get hideRelayNotices;

  /// No description provided for @popularUsers.
  ///
  /// In en, this message translates to:
  /// **'Popular Users'**
  String get popularUsers;

  /// No description provided for @splitAndTransferZap.
  ///
  /// In en, this message translates to:
  /// **'Split and Transfer Zap'**
  String get splitAndTransferZap;

  /// No description provided for @splitZapTip.
  ///
  /// In en, this message translates to:
  /// **'The support client will split and transfer zaps to the users you had added.'**
  String get splitZapTip;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No description provided for @zapNumberNotEnough.
  ///
  /// In en, this message translates to:
  /// **'Zap number not enough'**
  String get zapNumberNotEnough;

  /// No description provided for @nwcTip1.
  ///
  /// In en, this message translates to:
  /// **'NWC is Nostr Wallet Connect, with NWC Setting you zap within the app.'**
  String get nwcTip1;

  /// No description provided for @nwcTip2.
  ///
  /// In en, this message translates to:
  /// **'NWC URL is like'**
  String get nwcTip2;

  /// No description provided for @pleaseInputNWCURL.
  ///
  /// In en, this message translates to:
  /// **'PLease input NWC URL'**
  String get pleaseInputNWCURL;

  /// No description provided for @isSending.
  ///
  /// In en, this message translates to:
  /// **'is sending'**
  String get isSending;

  /// No description provided for @imageServicePath.
  ///
  /// In en, this message translates to:
  /// **'Image service path'**
  String get imageServicePath;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @pubkey.
  ///
  /// In en, this message translates to:
  /// **'Pubkey'**
  String get pubkey;

  /// No description provided for @loginFail.
  ///
  /// In en, this message translates to:
  /// **'Login fail'**
  String get loginFail;

  /// No description provided for @readonlyLoginTip.
  ///
  /// In en, this message translates to:
  /// **'You are logged in in read-only mode.'**
  String get readonlyLoginTip;

  /// No description provided for @loginWithAndroidSigner.
  ///
  /// In en, this message translates to:
  /// **'Login With Android Signer'**
  String get loginWithAndroidSigner;

  /// No description provided for @readOnly.
  ///
  /// In en, this message translates to:
  /// **'Read Only'**
  String get readOnly;

  /// No description provided for @loginWithNIP07Extension.
  ///
  /// In en, this message translates to:
  /// **'Login With NIP07 Extension'**
  String get loginWithNIP07Extension;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @admins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get admins;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @relay.
  ///
  /// In en, this message translates to:
  /// **'Relay'**
  String get relay;

  /// No description provided for @groupId.
  ///
  /// In en, this message translates to:
  /// **'GroupId'**
  String get groupId;

  /// No description provided for @publicType.
  ///
  /// In en, this message translates to:
  /// **'public'**
  String get publicType;

  /// No description provided for @privateType.
  ///
  /// In en, this message translates to:
  /// **'private'**
  String get privateType;

  /// No description provided for @closedType.
  ///
  /// In en, this message translates to:
  /// **'closed'**
  String get closedType;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @joinGroup.
  ///
  /// In en, this message translates to:
  /// **'Join Group'**
  String get joinGroup;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroup;

  /// No description provided for @cacheRelay.
  ///
  /// In en, this message translates to:
  /// **'Cache Relay'**
  String get cacheRelay;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @cache.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get cache;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @pleaseInputSummary.
  ///
  /// In en, this message translates to:
  /// **'Please input summary'**
  String get pleaseInputSummary;

  /// No description provided for @opened.
  ///
  /// In en, this message translates to:
  /// **'Opened'**
  String get opened;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @groupType.
  ///
  /// In en, this message translates to:
  /// **'group'**
  String get groupType;

  /// No description provided for @groupInfo.
  ///
  /// In en, this message translates to:
  /// **'Group Info'**
  String get groupInfo;

  /// No description provided for @yourGroups.
  ///
  /// In en, this message translates to:
  /// **'Your Groups'**
  String get yourGroups;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @updateImage.
  ///
  /// In en, this message translates to:
  /// **'Update Image'**
  String get updateImage;

  /// No description provided for @communityNameHeader.
  ///
  /// In en, this message translates to:
  /// **'Community Name'**
  String get communityNameHeader;

  /// No description provided for @enterCommunityName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for your community'**
  String get enterCommunityName;

  /// No description provided for @enterCommunityDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter a description of your community'**
  String get enterCommunityDescription;

  /// No description provided for @enterCommunityGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Enter the guidelines of your community'**
  String get enterCommunityGuidelines;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while trying to save your data.'**
  String get saveFailed;

  /// No description provided for @imageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed'**
  String get imageUploadFailed;

  /// No description provided for @allMediaPublic.
  ///
  /// In en, this message translates to:
  /// **'All media is publicly accessible to anyone with the URL.'**
  String get allMediaPublic;

  /// No description provided for @development.
  ///
  /// In en, this message translates to:
  /// **'Development'**
  String get development;

  /// No description provided for @closedGroup.
  ///
  /// In en, this message translates to:
  /// **'Closed group'**
  String get closedGroup;

  /// No description provided for @openGroup.
  ///
  /// In en, this message translates to:
  /// **'Open group'**
  String get openGroup;

  /// No description provided for @groupMember.
  ///
  /// In en, this message translates to:
  /// **'{number} Member'**
  String groupMember(int number);

  /// No description provided for @groupMembers.
  ///
  /// In en, this message translates to:
  /// **'{number} Members'**
  String groupMembers(int number);

  /// No description provided for @ageVerificationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you over 16 years old?'**
  String get ageVerificationQuestion;

  /// No description provided for @ageVerificationMessage.
  ///
  /// In en, this message translates to:
  /// **'For legal reasons, we need to make sure you\'re over this age to use Plur.'**
  String get ageVerificationMessage;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @createYourCommunity.
  ///
  /// In en, this message translates to:
  /// **'Create your community'**
  String get createYourCommunity;

  /// No description provided for @communityName.
  ///
  /// In en, this message translates to:
  /// **'community name'**
  String get communityName;

  /// No description provided for @nameYourCommunity.
  ///
  /// In en, this message translates to:
  /// **'Name your community'**
  String get nameYourCommunity;

  /// No description provided for @startOrJoinACommunity.
  ///
  /// In en, this message translates to:
  /// **'Start or join a community'**
  String get startOrJoinACommunity;

  /// No description provided for @connectWithOthers.
  ///
  /// In en, this message translates to:
  /// **'Connect with others by creating your own community or joining an existing one with an invite link.'**
  String get connectWithOthers;

  /// No description provided for @haveInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Have an invite link? Tap on it to join a community.'**
  String get haveInviteLink;

  /// No description provided for @onboardingNameInputTitle.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get onboardingNameInputTitle;

  /// No description provided for @onboardingNameInputHint.
  ///
  /// In en, this message translates to:
  /// **'Your name or nickname'**
  String get onboardingNameInputHint;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @findGroup.
  ///
  /// In en, this message translates to:
  /// **'Find Group'**
  String get findGroup;

  /// No description provided for @discoverGroups.
  ///
  /// In en, this message translates to:
  /// **'Discover Groups'**
  String get discoverGroups;

  /// No description provided for @searchForPublicGroups.
  ///
  /// In en, this message translates to:
  /// **'Search for public groups'**
  String get searchForPublicGroups;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @leaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave Group'**
  String get leaveGroup;

  /// No description provided for @leaveGroupQuestion.
  ///
  /// In en, this message translates to:
  /// **'Leave Group?'**
  String get leaveGroupQuestion;

  /// No description provided for @leaveGroupConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this group?'**
  String get leaveGroupConfirmation;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @media.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get media;

  /// No description provided for @links.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get links;

  /// No description provided for @places.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get places;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @noMediaFound.
  ///
  /// In en, this message translates to:
  /// **'No Media found'**
  String get noMediaFound;

  /// No description provided for @addPhotosToYourPosts.
  ///
  /// In en, this message translates to:
  /// **'Add photos to your posts to see them here.'**
  String get addPhotosToYourPosts;

  /// No description provided for @editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit Group'**
  String get editGroup;

  /// No description provided for @editDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Details'**
  String get editDetails;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @changesSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved successfully'**
  String get changesSaved;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving changes'**
  String get saveError;

  /// No description provided for @communityNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Community name is required'**
  String get communityNameRequired;

  /// No description provided for @asks.
  ///
  /// In en, this message translates to:
  /// **'Asks'**
  String get asks;

  /// No description provided for @offers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get offers;

  /// No description provided for @asksAndOffers.
  ///
  /// In en, this message translates to:
  /// **'Asks & Offers'**
  String get asksAndOffers;

  /// No description provided for @postAnAsk.
  ///
  /// In en, this message translates to:
  /// **'Post an Ask'**
  String get postAnAsk;

  /// No description provided for @postAnOffer.
  ///
  /// In en, this message translates to:
  /// **'Post an Offer'**
  String get postAnOffer;

  /// No description provided for @noAsksPostedYet.
  ///
  /// In en, this message translates to:
  /// **'No asks posted yet.\nBe the first to ask for something!'**
  String get noAsksPostedYet;

  /// No description provided for @noOffersPostedYet.
  ///
  /// In en, this message translates to:
  /// **'No offers posted yet.\nBe the first to offer something!'**
  String get noOffersPostedYet;

  /// No description provided for @noAsksOrOffersPostedYet.
  ///
  /// In en, this message translates to:
  /// **'No asks or offers posted yet.\nGet started by posting something!'**
  String get noAsksOrOffersPostedYet;

  /// No description provided for @errorWhileLoadingListings.
  ///
  /// In en, this message translates to:
  /// **'Error loading listings'**
  String get errorWhileLoadingListings;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @groupPublicDescription.
  ///
  /// In en, this message translates to:
  /// **'Visible to everyone in the network'**
  String get groupPublicDescription;

  /// No description provided for @groupPrivateDescription.
  ///
  /// In en, this message translates to:
  /// **'Only visible to members of this group'**
  String get groupPrivateDescription;

  /// No description provided for @groupOpenDescription.
  ///
  /// In en, this message translates to:
  /// **'Anyone can join without approval'**
  String get groupOpenDescription;

  /// No description provided for @groupClosedDescription.
  ///
  /// In en, this message translates to:
  /// **'Requires invitation or approval to join'**
  String get groupClosedDescription;

  /// No description provided for @invitePeopleToJoin.
  ///
  /// In en, this message translates to:
  /// **'Invite people to join this group'**
  String get invitePeopleToJoin;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @shareInviteDescription.
  ///
  /// In en, this message translates to:
  /// **'Share this link with people you want to invite to the group.'**
  String get shareInviteDescription;

  /// No description provided for @newCommunity.
  ///
  /// In en, this message translates to:
  /// **'New Community'**
  String get newCommunity;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @whatSHappening.
  ///
  /// In en, this message translates to:
  /// **'What\'s happening?'**
  String get whatSHappening;

  /// No description provided for @switchToFeedView.
  ///
  /// In en, this message translates to:
  /// **'Switch to Feed View'**
  String get switchToFeedView;

  /// No description provided for @switchToGridView.
  ///
  /// In en, this message translates to:
  /// **'Switch to Grid View'**
  String get switchToGridView;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// No description provided for @pastEvents.
  ///
  /// In en, this message translates to:
  /// **'Past Events'**
  String get pastEvents;

  /// No description provided for @allVisibility.
  ///
  /// In en, this message translates to:
  /// **'All Visibility'**
  String get allVisibility;

  /// No description provided for @unlisted.
  ///
  /// In en, this message translates to:
  /// **'Unlisted'**
  String get unlisted;

  /// No description provided for @noEventsFound.
  ///
  /// In en, this message translates to:
  /// **'No events found'**
  String get noEventsFound;

  /// No description provided for @noUpcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events'**
  String get noUpcomingEvents;

  /// No description provided for @noEventsForSelectedDay.
  ///
  /// In en, this message translates to:
  /// **'No events for selected day'**
  String get noEventsForSelectedDay;

  /// No description provided for @createAnEvent.
  ///
  /// In en, this message translates to:
  /// **'Create an Event'**
  String get createAnEvent;

  /// No description provided for @calendarView.
  ///
  /// In en, this message translates to:
  /// **'Calendar View'**
  String get calendarView;

  /// No description provided for @mapView.
  ///
  /// In en, this message translates to:
  /// **'Map View'**
  String get mapView;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @errorWhileLoadingEvents.
  ///
  /// In en, this message translates to:
  /// **'Error loading events'**
  String get errorWhileLoadingEvents;

  /// No description provided for @createEvent.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get createEvent;

  /// No description provided for @editEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get editEvent;

  /// No description provided for @eventCreated.
  ///
  /// In en, this message translates to:
  /// **'Event created successfully'**
  String get eventCreated;

  /// No description provided for @eventUpdated.
  ///
  /// In en, this message translates to:
  /// **'Event updated successfully'**
  String get eventUpdated;

  /// No description provided for @eventDeleted.
  ///
  /// In en, this message translates to:
  /// **'Event deleted successfully'**
  String get eventDeleted;

  /// No description provided for @errorDeletingEvent.
  ///
  /// In en, this message translates to:
  /// **'Error deleting event'**
  String get errorDeletingEvent;

  /// No description provided for @deleteEventConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this event?'**
  String get deleteEventConfirmation;

  /// No description provided for @deleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Delete Event'**
  String get deleteEvent;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @eventTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Add a title for your event'**
  String get eventTitleHint;

  /// No description provided for @eventDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what your event is about'**
  String get eventDescriptionHint;

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get dateAndTime;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @includeEndDateTime.
  ///
  /// In en, this message translates to:
  /// **'Include end date/time'**
  String get includeEndDateTime;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @eventLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Add a location or virtual meeting link'**
  String get eventLocationHint;

  /// No description provided for @visibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get visibility;

  /// No description provided for @additionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Additional Info'**
  String get additionalInfo;

  /// No description provided for @coverImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Cover Image URL'**
  String get coverImageUrl;

  /// No description provided for @capacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get capacity;

  /// No description provided for @cost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get cost;

  /// No description provided for @eventTags.
  ///
  /// In en, this message translates to:
  /// **'Event Tags'**
  String get eventTags;

  /// No description provided for @noTagsAdded.
  ///
  /// In en, this message translates to:
  /// **'No tags added'**
  String get noTagsAdded;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add Tag'**
  String get addTag;

  /// No description provided for @tagName.
  ///
  /// In en, this message translates to:
  /// **'Tag Name'**
  String get tagName;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @endTimeMustBeAfterStart.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get endTimeMustBeAfterStart;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterTitle;

  /// No description provided for @pleaseEnterDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description'**
  String get pleaseEnterDescription;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @errorLoadingResponses.
  ///
  /// In en, this message translates to:
  /// **'Error loading responses'**
  String get errorLoadingResponses;

  /// No description provided for @responses.
  ///
  /// In en, this message translates to:
  /// **'Responses'**
  String get responses;

  /// No description provided for @noResponsesYet.
  ///
  /// In en, this message translates to:
  /// **'No responses yet'**
  String get noResponsesYet;

  /// No description provided for @rsvpSubmitted.
  ///
  /// In en, this message translates to:
  /// **'RSVP submitted'**
  String get rsvpSubmitted;

  /// No description provided for @errorSubmittingRSVP.
  ///
  /// In en, this message translates to:
  /// **'Error submitting RSVP'**
  String get errorSubmittingRSVP;

  /// No description provided for @organizers.
  ///
  /// In en, this message translates to:
  /// **'Organizers'**
  String get organizers;

  /// No description provided for @attendees.
  ///
  /// In en, this message translates to:
  /// **'Attendees'**
  String get attendees;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @going.
  ///
  /// In en, this message translates to:
  /// **'Going'**
  String get going;

  /// No description provided for @interested.
  ///
  /// In en, this message translates to:
  /// **'Interested'**
  String get interested;

  /// No description provided for @notGoing.
  ///
  /// In en, this message translates to:
  /// **'Can\'t Go'**
  String get notGoing;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @openLink.
  ///
  /// In en, this message translates to:
  /// **'Open Link'**
  String get openLink;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @inviteLink.
  ///
  /// In en, this message translates to:
  /// **'Invite Link'**
  String get inviteLink;

  /// No description provided for @inviteByName.
  ///
  /// In en, this message translates to:
  /// **'Invite by Name'**
  String get inviteByName;

  /// No description provided for @groupNotFound.
  ///
  /// In en, this message translates to:
  /// **'Group not found'**
  String get groupNotFound;

  /// No description provided for @inviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invite sent successfully'**
  String get inviteSent;

  /// No description provided for @searchContacts.
  ///
  /// In en, this message translates to:
  /// **'Search contacts'**
  String get searchContacts;

  /// No description provided for @searchContactsToInvite.
  ///
  /// In en, this message translates to:
  /// **'Search contacts to invite'**
  String get searchContactsToInvite;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @expires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expires;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @oneDay.
  ///
  /// In en, this message translates to:
  /// **'1 Day'**
  String get oneDay;

  /// No description provided for @oneWeek.
  ///
  /// In en, this message translates to:
  /// **'1 Week'**
  String get oneWeek;

  /// No description provided for @oneMonth.
  ///
  /// In en, this message translates to:
  /// **'1 Month'**
  String get oneMonth;

  /// No description provided for @reusable.
  ///
  /// In en, this message translates to:
  /// **'Reusable'**
  String get reusable;

  /// No description provided for @sendInvite.
  ///
  /// In en, this message translates to:
  /// **'Send Invite'**
  String get sendInvite;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

  /// No description provided for @communityInvite.
  ///
  /// In en, this message translates to:
  /// **'Community Invite'**
  String get communityInvite;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @inviteExpired.
  ///
  /// In en, this message translates to:
  /// **'This invite has expired'**
  String get inviteExpired;

  /// No description provided for @joinCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join Community'**
  String get joinCommunity;

  /// No description provided for @expiringNow.
  ///
  /// In en, this message translates to:
  /// **'Expiring now'**
  String get expiringNow;

  /// No description provided for @lnbc.
  ///
  /// In en, this message translates to:
  /// **'Lightning Invoice'**
  String get lnbc;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bg',
    'cs',
    'da',
    'de',
    'el',
    'en',
    'es',
    'et',
    'fi',
    'fr',
    'hi',
    'hu',
    'it',
    'ja',
    'ko',
    'nl',
    'pl',
    'pt',
    'ro',
    'ru',
    'sl',
    'sv',
    'th',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return SZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return SAr();
    case 'bg':
      return SBg();
    case 'cs':
      return SCs();
    case 'da':
      return SDa();
    case 'de':
      return SDe();
    case 'el':
      return SEl();
    case 'en':
      return SEn();
    case 'es':
      return SEs();
    case 'et':
      return SEt();
    case 'fi':
      return SFi();
    case 'fr':
      return SFr();
    case 'hi':
      return SHi();
    case 'hu':
      return SHu();
    case 'it':
      return SIt();
    case 'ja':
      return SJa();
    case 'ko':
      return SKo();
    case 'nl':
      return SNl();
    case 'pl':
      return SPl();
    case 'pt':
      return SPt();
    case 'ro':
      return SRo();
    case 'ru':
      return SRu();
    case 'sl':
      return SSl();
    case 'sv':
      return SSv();
    case 'th':
      return STh();
    case 'vi':
      return SVi();
    case 'zh':
      return SZh();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
