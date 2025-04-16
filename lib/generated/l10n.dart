// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Confirm`
  String get confirm {
    return Intl.message(
      'Confirm',
      name: 'confirm',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Discard`
  String get discard {
    return Intl.message(
      'Discard',
      name: 'discard',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to discard unsaved changes?`
  String get confirmDiscard {
    return Intl.message(
      'Are you sure you want to discard unsaved changes?',
      name: 'confirmDiscard',
      desc: '',
      args: [],
    );
  }

  /// `Error`
  String get error {
    return Intl.message(
      'Error',
      name: 'error',
      desc: '',
      args: [],
    );
  }

  /// `Retry`
  String get retry {
    return Intl.message(
      'Retry',
      name: 'retry',
      desc: '',
      args: [],
    );
  }

  /// `Communities`
  String get communities {
    return Intl.message(
      'Communities',
      name: 'communities',
      desc: '',
      args: [],
    );
  }

  /// `Community Guidelines`
  String get communityGuidelines {
    return Intl.message(
      'Community Guidelines',
      name: 'communityGuidelines',
      desc: '',
      args: [],
    );
  }

  /// `Posting to`
  String get postingTo {
    return Intl.message(
      'Posting to',
      name: 'postingTo',
      desc: '',
      args: [],
    );
  }

  /// `New Post`
  String get newPost {
    return Intl.message(
      'New Post',
      name: 'newPost',
      desc: '',
      args: [],
    );
  }

  /// `Open`
  String get open {
    return Intl.message(
      'Open',
      name: 'open',
      desc: '',
      args: [],
    );
  }

  /// `Close`
  String get close {
    return Intl.message(
      'Close',
      name: 'close',
      desc: '',
      args: [],
    );
  }

  /// `Show`
  String get show {
    return Intl.message(
      'Show',
      name: 'show',
      desc: '',
      args: [],
    );
  }

  /// `Hide`
  String get hide {
    return Intl.message(
      'Hide',
      name: 'hide',
      desc: '',
      args: [],
    );
  }

  /// `Auto`
  String get auto {
    return Intl.message(
      'Auto',
      name: 'auto',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get language {
    return Intl.message(
      'Language',
      name: 'language',
      desc: '',
      args: [],
    );
  }

  /// `Follow System`
  String get followSystem {
    return Intl.message(
      'Follow System',
      name: 'followSystem',
      desc: '',
      args: [],
    );
  }

  /// `Light`
  String get light {
    return Intl.message(
      'Light',
      name: 'light',
      desc: '',
      args: [],
    );
  }

  /// `Dark`
  String get dark {
    return Intl.message(
      'Dark',
      name: 'dark',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: '',
      args: [],
    );
  }

  /// `Default Color`
  String get defaultColor {
    return Intl.message(
      'Default Color',
      name: 'defaultColor',
      desc: '',
      args: [],
    );
  }

  /// `Custom Color`
  String get customColor {
    return Intl.message(
      'Custom Color',
      name: 'customColor',
      desc: '',
      args: [],
    );
  }

  /// `Image Compress`
  String get imageCompress {
    return Intl.message(
      'Image Compress',
      name: 'imageCompress',
      desc: '',
      args: [],
    );
  }

  /// `Don't Compress`
  String get dontCompress {
    return Intl.message(
      'Don\'t Compress',
      name: 'dontCompress',
      desc: '',
      args: [],
    );
  }

  /// `Default Font Family`
  String get defaultFontFamily {
    return Intl.message(
      'Default Font Family',
      name: 'defaultFontFamily',
      desc: '',
      args: [],
    );
  }

  /// `Custom Font Family`
  String get customFontFamily {
    return Intl.message(
      'Custom Font Family',
      name: 'customFontFamily',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Lock`
  String get privacyLock {
    return Intl.message(
      'Privacy Lock',
      name: 'privacyLock',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get password {
    return Intl.message(
      'Password',
      name: 'password',
      desc: '',
      args: [],
    );
  }

  /// `Face`
  String get face {
    return Intl.message(
      'Face',
      name: 'face',
      desc: '',
      args: [],
    );
  }

  /// `Fingerprint`
  String get fingerprint {
    return Intl.message(
      'Fingerprint',
      name: 'fingerprint',
      desc: '',
      args: [],
    );
  }

  /// `Please authenticate to turn off the privacy lock`
  String get pleaseAuthenticateToTurnOffThePrivacyLock {
    return Intl.message(
      'Please authenticate to turn off the privacy lock',
      name: 'pleaseAuthenticateToTurnOffThePrivacyLock',
      desc: '',
      args: [],
    );
  }

  /// `Please authenticate to turn on the privacy lock`
  String get pleaseAuthenticateToTurnOnThePrivacyLock {
    return Intl.message(
      'Please authenticate to turn on the privacy lock',
      name: 'pleaseAuthenticateToTurnOnThePrivacyLock',
      desc: '',
      args: [],
    );
  }

  /// `Please authenticate to use app`
  String get pleaseAuthenticateToUseApp {
    return Intl.message(
      'Please authenticate to use app',
      name: 'pleaseAuthenticateToUseApp',
      desc: '',
      args: [],
    );
  }

  /// `Authenticat need`
  String get authenticatNeed {
    return Intl.message(
      'Authenticat need',
      name: 'authenticatNeed',
      desc: '',
      args: [],
    );
  }

  /// `Verify error`
  String get verifyError {
    return Intl.message(
      'Verify error',
      name: 'verifyError',
      desc: '',
      args: [],
    );
  }

  /// `Verify failure`
  String get verifyFailure {
    return Intl.message(
      'Verify failure',
      name: 'verifyFailure',
      desc: '',
      args: [],
    );
  }

  /// `Default index`
  String get defaultIndex {
    return Intl.message(
      'Default index',
      name: 'defaultIndex',
      desc: '',
      args: [],
    );
  }

  /// `Timeline`
  String get timeline {
    return Intl.message(
      'Timeline',
      name: 'timeline',
      desc: '',
      args: [],
    );
  }

  /// `Global`
  String get global {
    return Intl.message(
      'Global',
      name: 'global',
      desc: '',
      args: [],
    );
  }

  /// `Default tab`
  String get defaultTab {
    return Intl.message(
      'Default tab',
      name: 'defaultTab',
      desc: '',
      args: [],
    );
  }

  /// `Posts`
  String get posts {
    return Intl.message(
      'Posts',
      name: 'posts',
      desc: '',
      args: [],
    );
  }

  /// `Posts & Replies`
  String get postsAndReplies {
    return Intl.message(
      'Posts & Replies',
      name: 'postsAndReplies',
      desc: '',
      args: [],
    );
  }

  /// `Mentions`
  String get mentions {
    return Intl.message(
      'Mentions',
      name: 'mentions',
      desc: '',
      args: [],
    );
  }

  /// `Notes`
  String get notes {
    return Intl.message(
      'Notes',
      name: 'notes',
      desc: '',
      args: [],
    );
  }

  /// `Users`
  String get users {
    return Intl.message(
      'Users',
      name: 'users',
      desc: '',
      args: [],
    );
  }

  /// `Topics`
  String get topics {
    return Intl.message(
      'Topics',
      name: 'topics',
      desc: '',
      args: [],
    );
  }

  /// `Search`
  String get search {
    return Intl.message(
      'Search',
      name: 'search',
      desc: '',
      args: [],
    );
  }

  /// `Request`
  String get request {
    return Intl.message(
      'Request',
      name: 'request',
      desc: '',
      args: [],
    );
  }

  /// `Link preview`
  String get linkPreview {
    return Intl.message(
      'Link preview',
      name: 'linkPreview',
      desc: '',
      args: [],
    );
  }

  /// `Video preview in list`
  String get videoPreviewInList {
    return Intl.message(
      'Video preview in list',
      name: 'videoPreviewInList',
      desc: '',
      args: [],
    );
  }

  /// `Network`
  String get network {
    return Intl.message(
      'Network',
      name: 'network',
      desc: '',
      args: [],
    );
  }

  /// `The network will take effect the next time the app is launched`
  String get networkTakeEffectTip {
    return Intl.message(
      'The network will take effect the next time the app is launched',
      name: 'networkTakeEffectTip',
      desc: '',
      args: [],
    );
  }

  /// `Image service`
  String get imageService {
    return Intl.message(
      'Image service',
      name: 'imageService',
      desc: '',
      args: [],
    );
  }

  /// `Forbid image`
  String get forbidImage {
    return Intl.message(
      'Forbid image',
      name: 'forbidImage',
      desc: '',
      args: [],
    );
  }

  /// `Forbid video`
  String get forbidVideo {
    return Intl.message(
      'Forbid video',
      name: 'forbidVideo',
      desc: '',
      args: [],
    );
  }

  /// `Forbid profile picture`
  String get forbidProfilePicture {
    return Intl.message(
      'Forbid profile picture',
      name: 'forbidProfilePicture',
      desc: '',
      args: [],
    );
  }

  /// `Please input`
  String get pleaseInput {
    return Intl.message(
      'Please input',
      name: 'pleaseInput',
      desc: '',
      args: [],
    );
  }

  /// `Notice`
  String get notice {
    return Intl.message(
      'Notice',
      name: 'notice',
      desc: '',
      args: [],
    );
  }

  /// `Write a message`
  String get writeAMessage {
    return Intl.message(
      'Write a message',
      name: 'writeAMessage',
      desc: '',
      args: [],
    );
  }

  /// `Add to known list`
  String get addToKnownList {
    return Intl.message(
      'Add to known list',
      name: 'addToKnownList',
      desc: '',
      args: [],
    );
  }

  /// `Buy me a coffee!`
  String get buyMeACoffee {
    return Intl.message(
      'Buy me a coffee!',
      name: 'buyMeACoffee',
      desc: '',
      args: [],
    );
  }

  /// `Donate`
  String get donate {
    return Intl.message(
      'Donate',
      name: 'donate',
      desc: '',
      args: [],
    );
  }

  /// `What's happening?`
  String get whatSHappening {
    return Intl.message(
      'What\'s happening?',
      name: 'whatSHappening',
      desc: '',
      args: [],
    );
  }

  /// `Publish`
  String get send {
    return Intl.message(
      'Publish',
      name: 'send',
      desc: '',
      args: [],
    );
  }

  /// `Please input event id`
  String get pleaseInputEventId {
    return Intl.message(
      'Please input event id',
      name: 'pleaseInputEventId',
      desc: '',
      args: [],
    );
  }

  /// `Please input user pubkey`
  String get pleaseInputUserPubkey {
    return Intl.message(
      'Please input user pubkey',
      name: 'pleaseInputUserPubkey',
      desc: '',
      args: [],
    );
  }

  /// `Please input lnbc text`
  String get pleaseInputLnbcText {
    return Intl.message(
      'Please input lnbc text',
      name: 'pleaseInputLnbcText',
      desc: '',
      args: [],
    );
  }

  /// `Please input Topic text`
  String get pleaseInputTopicText {
    return Intl.message(
      'Please input Topic text',
      name: 'pleaseInputTopicText',
      desc: '',
      args: [],
    );
  }

  /// `Text can't contain blank space`
  String get textCantContainBlankSpace {
    return Intl.message(
      'Text can\'t contain blank space',
      name: 'textCantContainBlankSpace',
      desc: '',
      args: [],
    );
  }

  /// `Text can't contain new line`
  String get textCantContainNewLine {
    return Intl.message(
      'Text can\'t contain new line',
      name: 'textCantContainNewLine',
      desc: '',
      args: [],
    );
  }

  /// `replied`
  String get replied {
    return Intl.message(
      'replied',
      name: 'replied',
      desc: '',
      args: [],
    );
  }

  /// `boosted`
  String get boosted {
    return Intl.message(
      'boosted',
      name: 'boosted',
      desc: '',
      args: [],
    );
  }

  /// `liked`
  String get liked {
    return Intl.message(
      'liked',
      name: 'liked',
      desc: '',
      args: [],
    );
  }

  /// `view key`
  String get viewKey {
    return Intl.message(
      'view key',
      name: 'viewKey',
      desc: '',
      args: [],
    );
  }

  /// `The key has been copied!`
  String get keyHasBeenCopy {
    return Intl.message(
      'The key has been copied!',
      name: 'keyHasBeenCopy',
      desc: '',
      args: [],
    );
  }

  /// `Input dirtyword.`
  String get inputDirtyword {
    return Intl.message(
      'Input dirtyword.',
      name: 'inputDirtyword',
      desc: '',
      args: [],
    );
  }

  /// `Word can't be null.`
  String get wordCantBeNull {
    return Intl.message(
      'Word can\'t be null.',
      name: 'wordCantBeNull',
      desc: '',
      args: [],
    );
  }

  /// `Blocks`
  String get blocks {
    return Intl.message(
      'Blocks',
      name: 'blocks',
      desc: '',
      args: [],
    );
  }

  /// `Dirtywords`
  String get dirtywords {
    return Intl.message(
      'Dirtywords',
      name: 'dirtywords',
      desc: '',
      args: [],
    );
  }

  /// `loading`
  String get loading {
    return Intl.message(
      'loading',
      name: 'loading',
      desc: '',
      args: [],
    );
  }

  /// `Account Manager`
  String get accountManager {
    return Intl.message(
      'Account Manager',
      name: 'accountManager',
      desc: '',
      args: [],
    );
  }

  /// `Add Account`
  String get addAccount {
    return Intl.message(
      'Add Account',
      name: 'addAccount',
      desc: '',
      args: [],
    );
  }

  /// `Input account private key`
  String get inputAccountPrivateKey {
    return Intl.message(
      'Input account private key',
      name: 'inputAccountPrivateKey',
      desc: '',
      args: [],
    );
  }

  /// `Add account and login?`
  String get addAccountAndLogin {
    return Intl.message(
      'Add account and login?',
      name: 'addAccountAndLogin',
      desc: '',
      args: [],
    );
  }

  /// `Wrong Private Key format`
  String get wrongPrivateKeyFormat {
    return Intl.message(
      'Wrong Private Key format',
      name: 'wrongPrivateKeyFormat',
      desc: '',
      args: [],
    );
  }

  /// `Filter`
  String get filter {
    return Intl.message(
      'Filter',
      name: 'filter',
      desc: '',
      args: [],
    );
  }

  /// `Relays`
  String get relays {
    return Intl.message(
      'Relays',
      name: 'relays',
      desc: '',
      args: [],
    );
  }

  /// `Please do not disclose or share the key to anyone.`
  String get pleaseDoNotDiscloseOrShareTheKeyToAnyone {
    return Intl.message(
      'Please do not disclose or share the key to anyone.',
      name: 'pleaseDoNotDiscloseOrShareTheKeyToAnyone',
      desc: '',
      args: [],
    );
  }

  /// `Nostrmo developers will never require a key from you.`
  String get nostrmoDevelopersWillNeverRequireAKeyFromYou {
    return Intl.message(
      'Nostrmo developers will never require a key from you.',
      name: 'nostrmoDevelopersWillNeverRequireAKeyFromYou',
      desc: '',
      args: [],
    );
  }

  /// `Please keep the key properly for account recovery.`
  String get pleaseKeepTheKeyProperlyForAccountRecovery {
    return Intl.message(
      'Please keep the key properly for account recovery.',
      name: 'pleaseKeepTheKeyProperlyForAccountRecovery',
      desc: '',
      args: [],
    );
  }

  /// `Backup and Safety tips`
  String get backupAndSafetyTips {
    return Intl.message(
      'Backup and Safety tips',
      name: 'backupAndSafetyTips',
      desc: '',
      args: [],
    );
  }

  /// `The key is a random string that resembles your account password. Anyone with this key can access and control your account.`
  String get theKeyIsARandomStringThatResembles {
    return Intl.message(
      'The key is a random string that resembles your account password. Anyone with this key can access and control your account.',
      name: 'theKeyIsARandomStringThatResembles',
      desc: '',
      args: [],
    );
  }

  /// `Copy Key`
  String get copyKey {
    return Intl.message(
      'Copy Key',
      name: 'copyKey',
      desc: '',
      args: [],
    );
  }

  /// `Copy & Continue`
  String get copyAndContinue {
    return Intl.message(
      'Copy & Continue',
      name: 'copyAndContinue',
      desc: '',
      args: [],
    );
  }

  /// `Copy Hex Key`
  String get copyHexKey {
    return Intl.message(
      'Copy Hex Key',
      name: 'copyHexKey',
      desc: '',
      args: [],
    );
  }

  /// `Please check the tips.`
  String get pleaseCheckTheTips {
    return Intl.message(
      'Please check the tips.',
      name: 'pleaseCheckTheTips',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get login {
    return Intl.message(
      'Login',
      name: 'login',
      desc: '',
      args: [],
    );
  }

  /// `Sign Up`
  String get signup {
    return Intl.message(
      'Sign Up',
      name: 'signup',
      desc: '',
      args: [],
    );
  }

  /// `Your private key`
  String get yourPrivateKey {
    return Intl.message(
      'Your private key',
      name: 'yourPrivateKey',
      desc: '',
      args: [],
    );
  }

  /// `Generate a new private key`
  String get generateANewPrivateKey {
    return Intl.message(
      'Generate a new private key',
      name: 'generateANewPrivateKey',
      desc: '',
      args: [],
    );
  }

  /// `By continuing, you accept our <accent>terms of service</accent>`
  String get acceptTermsOfService {
    return Intl.message(
      'By continuing, you accept our <accent>terms of service</accent>',
      name: 'acceptTermsOfService',
      desc: '',
      args: [],
    );
  }

  /// `This is the key to your account`
  String get thisIsTheKeyToYourAccount {
    return Intl.message(
      'This is the key to your account',
      name: 'thisIsTheKeyToYourAccount',
      desc: '',
      args: [],
    );
  }

  /// `I understand that I should not share this key with anyone, and I should back it up safely (e.g. in a password manager).`
  String get iUnderstandIShouldntShareThisKey {
    return Intl.message(
      'I understand that I should not share this key with anyone, and I should back it up safely (e.g. in a password manager).',
      name: 'iUnderstandIShouldntShareThisKey',
      desc: '',
      args: [],
    );
  }

  /// `Private key is null.`
  String get privateKeyIsNull {
    return Intl.message(
      'Private key is null.',
      name: 'privateKeyIsNull',
      desc: '',
      args: [],
    );
  }

  /// `Submit`
  String get submit {
    return Intl.message(
      'Submit',
      name: 'submit',
      desc: '',
      args: [],
    );
  }

  /// `Display Name`
  String get displayName {
    return Intl.message(
      'Display Name',
      name: 'displayName',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get name {
    return Intl.message(
      'Name',
      name: 'name',
      desc: '',
      args: [],
    );
  }

  /// `About`
  String get about {
    return Intl.message(
      'About',
      name: 'about',
      desc: '',
      args: [],
    );
  }

  /// `Picture`
  String get picture {
    return Intl.message(
      'Picture',
      name: 'picture',
      desc: '',
      args: [],
    );
  }

  /// `Banner`
  String get banner {
    return Intl.message(
      'Banner',
      name: 'banner',
      desc: '',
      args: [],
    );
  }

  /// `Website`
  String get website {
    return Intl.message(
      'Website',
      name: 'website',
      desc: '',
      args: [],
    );
  }

  /// `Nip05`
  String get nip05 {
    return Intl.message(
      'Nip05',
      name: 'nip05',
      desc: '',
      args: [],
    );
  }

  /// `Lud16`
  String get lud16 {
    return Intl.message(
      'Lud16',
      name: 'lud16',
      desc: '',
      args: [],
    );
  }

  /// `Input relay address.`
  String get inputRelayAddress {
    return Intl.message(
      'Input relay address.',
      name: 'inputRelayAddress',
      desc: '',
      args: [],
    );
  }

  /// `Address can't be null.`
  String get addressCantBeNull {
    return Intl.message(
      'Address can\'t be null.',
      name: 'addressCantBeNull',
      desc: '',
      args: [],
    );
  }

  /// `or`
  String get or {
    return Intl.message(
      'or',
      name: 'or',
      desc: '',
      args: [],
    );
  }

  /// `Empty text may be ban by relays.`
  String get emptyTextMayBeBanByRelays {
    return Intl.message(
      'Empty text may be ban by relays.',
      name: 'emptyTextMayBeBanByRelays',
      desc: '',
      args: [],
    );
  }

  /// `Note loading...`
  String get noteLoading {
    return Intl.message(
      'Note loading...',
      name: 'noteLoading',
      desc: '',
      args: [],
    );
  }

  /// `Following`
  String get following {
    return Intl.message(
      'Following',
      name: 'following',
      desc: '',
      args: [],
    );
  }

  /// `Read`
  String get read {
    return Intl.message(
      'Read',
      name: 'read',
      desc: '',
      args: [],
    );
  }

  /// `Write`
  String get write {
    return Intl.message(
      'Write',
      name: 'write',
      desc: '',
      args: [],
    );
  }

  /// `Copy current Url`
  String get copyCurrentUrl {
    return Intl.message(
      'Copy current Url',
      name: 'copyCurrentUrl',
      desc: '',
      args: [],
    );
  }

  /// `Copy init Url`
  String get copyInitUrl {
    return Intl.message(
      'Copy init Url',
      name: 'copyInitUrl',
      desc: '',
      args: [],
    );
  }

  /// `Open in browser`
  String get openInBrowser {
    return Intl.message(
      'Open in browser',
      name: 'openInBrowser',
      desc: '',
      args: [],
    );
  }

  /// `Copy success!`
  String get copySuccess {
    return Intl.message(
      'Copy success!',
      name: 'copySuccess',
      desc: '',
      args: [],
    );
  }

  /// `Boost`
  String get boost {
    return Intl.message(
      'Boost',
      name: 'boost',
      desc: '',
      args: [],
    );
  }

  /// `Quote`
  String get quote {
    return Intl.message(
      'Quote',
      name: 'quote',
      desc: '',
      args: [],
    );
  }

  /// `Replying`
  String get replying {
    return Intl.message(
      'Replying',
      name: 'replying',
      desc: '',
      args: [],
    );
  }

  /// `Copy Note Json`
  String get copyNoteJson {
    return Intl.message(
      'Copy Note Json',
      name: 'copyNoteJson',
      desc: '',
      args: [],
    );
  }

  /// `Copy Note Pubkey`
  String get copyNotePubkey {
    return Intl.message(
      'Copy Note Pubkey',
      name: 'copyNotePubkey',
      desc: '',
      args: [],
    );
  }

  /// `Copy Note Id`
  String get copyNoteId {
    return Intl.message(
      'Copy Note Id',
      name: 'copyNoteId',
      desc: '',
      args: [],
    );
  }

  /// `Detail`
  String get detail {
    return Intl.message(
      'Detail',
      name: 'detail',
      desc: '',
      args: [],
    );
  }

  /// `Share`
  String get share {
    return Intl.message(
      'Share',
      name: 'share',
      desc: '',
      args: [],
    );
  }

  /// `Broadcast`
  String get broadcast {
    return Intl.message(
      'Broadcast',
      name: 'broadcast',
      desc: '',
      args: [],
    );
  }

  /// `Block`
  String get block {
    return Intl.message(
      'Block',
      name: 'block',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get delete {
    return Intl.message(
      'Delete',
      name: 'delete',
      desc: '',
      args: [],
    );
  }

  /// `Metadata can not be found.`
  String get metadataCanNotBeFound {
    return Intl.message(
      'Metadata can not be found.',
      name: 'metadataCanNotBeFound',
      desc: '',
      args: [],
    );
  }

  /// `not found`
  String get notFound {
    return Intl.message(
      'not found',
      name: 'notFound',
      desc: '',
      args: [],
    );
  }

  /// `Gen invoice code error.`
  String get genInvoiceCodeError {
    return Intl.message(
      'Gen invoice code error.',
      name: 'genInvoiceCodeError',
      desc: '',
      args: [],
    );
  }

  /// `Notices`
  String get notices {
    return Intl.message(
      'Notices',
      name: 'notices',
      desc: '',
      args: [],
    );
  }

  /// `Please input search content`
  String get pleaseInputSearchContent {
    return Intl.message(
      'Please input search content',
      name: 'pleaseInputSearchContent',
      desc: '',
      args: [],
    );
  }

  /// `Open User page`
  String get openUserPage {
    return Intl.message(
      'Open User page',
      name: 'openUserPage',
      desc: '',
      args: [],
    );
  }

  /// `Open Note detail`
  String get openNoteDetail {
    return Intl.message(
      'Open Note detail',
      name: 'openNoteDetail',
      desc: '',
      args: [],
    );
  }

  /// `Search User from cache`
  String get searchUserFromCache {
    return Intl.message(
      'Search User from cache',
      name: 'searchUserFromCache',
      desc: '',
      args: [],
    );
  }

  /// `Open Event from cache`
  String get openEventFromCache {
    return Intl.message(
      'Open Event from cache',
      name: 'openEventFromCache',
      desc: '',
      args: [],
    );
  }

  /// `Search pubkey event`
  String get searchPubkeyEvent {
    return Intl.message(
      'Search pubkey event',
      name: 'searchPubkeyEvent',
      desc: '',
      args: [],
    );
  }

  /// `Search note content`
  String get searchNoteContent {
    return Intl.message(
      'Search note content',
      name: 'searchNoteContent',
      desc: '',
      args: [],
    );
  }

  /// `Data`
  String get data {
    return Intl.message(
      'Data',
      name: 'data',
      desc: '',
      args: [],
    );
  }

  /// `Delete Account`
  String get deleteAccount {
    return Intl.message(
      'Delete Account',
      name: 'deleteAccount',
      desc: '',
      args: [],
    );
  }

  /// `We will try to delete you infomation. When you login with this Key again, you will lose your data.`
  String get deleteAccountTips {
    return Intl.message(
      'We will try to delete you infomation. When you login with this Key again, you will lose your data.',
      name: 'deleteAccountTips',
      desc: '',
      args: [],
    );
  }

  /// `Lnurl and Lud16 can't found.`
  String get lnurlAndLud16CantFound {
    return Intl.message(
      'Lnurl and Lud16 can\'t found.',
      name: 'lnurlAndLud16CantFound',
      desc: '',
      args: [],
    );
  }

  /// `Add now`
  String get addNow {
    return Intl.message(
      'Add now',
      name: 'addNow',
      desc: '',
      args: [],
    );
  }

  /// `Input Sats num to gen lightning invoice`
  String get inputSatsNumToGenLightningInvoice {
    return Intl.message(
      'Input Sats num to gen lightning invoice',
      name: 'inputSatsNumToGenLightningInvoice',
      desc: '',
      args: [],
    );
  }

  /// `Input Sats num`
  String get inputSatsNum {
    return Intl.message(
      'Input Sats num',
      name: 'inputSatsNum',
      desc: '',
      args: [],
    );
  }

  /// `Number parse error`
  String get numberParseError {
    return Intl.message(
      'Number parse error',
      name: 'numberParseError',
      desc: '',
      args: [],
    );
  }

  /// `Input`
  String get input {
    return Intl.message(
      'Input',
      name: 'input',
      desc: '',
      args: [],
    );
  }

  /// `Topic`
  String get topic {
    return Intl.message(
      'Topic',
      name: 'topic',
      desc: '',
      args: [],
    );
  }

  /// `Note Id`
  String get noteId {
    return Intl.message(
      'Note Id',
      name: 'noteId',
      desc: '',
      args: [],
    );
  }

  /// `User Pubkey`
  String get userPubkey {
    return Intl.message(
      'User Pubkey',
      name: 'userPubkey',
      desc: '',
      args: [],
    );
  }

  /// `Translate`
  String get translate {
    return Intl.message(
      'Translate',
      name: 'translate',
      desc: '',
      args: [],
    );
  }

  /// `Translate Source Language`
  String get translateSourceLanguage {
    return Intl.message(
      'Translate Source Language',
      name: 'translateSourceLanguage',
      desc: '',
      args: [],
    );
  }

  /// `Translate Target Language`
  String get translateTargetLanguage {
    return Intl.message(
      'Translate Target Language',
      name: 'translateTargetLanguage',
      desc: '',
      args: [],
    );
  }

  /// `Begin to download translate model`
  String get beginToDownloadTranslateModel {
    return Intl.message(
      'Begin to download translate model',
      name: 'beginToDownloadTranslateModel',
      desc: '',
      args: [],
    );
  }

  /// `Upload fail.`
  String get uploadFail {
    return Intl.message(
      'Upload fail.',
      name: 'uploadFail',
      desc: '',
      args: [],
    );
  }

  /// `notes updated`
  String get notesUpdated {
    return Intl.message(
      'notes updated',
      name: 'notesUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Add this relay to local?`
  String get addThisRelayToLocal {
    return Intl.message(
      'Add this relay to local?',
      name: 'addThisRelayToLocal',
      desc: '',
      args: [],
    );
  }

  /// `Broadcast When Boost`
  String get broadcastWhenBoost {
    return Intl.message(
      'Broadcast When Boost',
      name: 'broadcastWhenBoost',
      desc: '',
      args: [],
    );
  }

  /// `Find clouded relay list, do you want to download it?`
  String get findCloudedRelayListDoYouWantToDownload {
    return Intl.message(
      'Find clouded relay list, do you want to download it?',
      name: 'findCloudedRelayListDoYouWantToDownload',
      desc: '',
      args: [],
    );
  }

  /// `Input can not be null`
  String get inputCanNotBeNull {
    return Intl.message(
      'Input can not be null',
      name: 'inputCanNotBeNull',
      desc: '',
      args: [],
    );
  }

  /// `Input parse error`
  String get inputParseError {
    return Intl.message(
      'Input parse error',
      name: 'inputParseError',
      desc: '',
      args: [],
    );
  }

  /// `You had voted with`
  String get youHadVotedWith {
    return Intl.message(
      'You had voted with',
      name: 'youHadVotedWith',
      desc: '',
      args: [],
    );
  }

  /// `Close at`
  String get closeAt {
    return Intl.message(
      'Close at',
      name: 'closeAt',
      desc: '',
      args: [],
    );
  }

  /// `Zap num can not smaller then`
  String get zapNumCanNotSmallerThen {
    return Intl.message(
      'Zap num can not smaller then',
      name: 'zapNumCanNotSmallerThen',
      desc: '',
      args: [],
    );
  }

  /// `Zap num can not bigger then`
  String get zapNumCanNotBiggerThen {
    return Intl.message(
      'Zap num can not bigger then',
      name: 'zapNumCanNotBiggerThen',
      desc: '',
      args: [],
    );
  }

  /// `min zap num`
  String get minZapNum {
    return Intl.message(
      'min zap num',
      name: 'minZapNum',
      desc: '',
      args: [],
    );
  }

  /// `max zap num`
  String get maxZapNum {
    return Intl.message(
      'max zap num',
      name: 'maxZapNum',
      desc: '',
      args: [],
    );
  }

  /// `poll option info`
  String get pollOptionInfo {
    return Intl.message(
      'poll option info',
      name: 'pollOptionInfo',
      desc: '',
      args: [],
    );
  }

  /// `add poll option`
  String get addPollOption {
    return Intl.message(
      'add poll option',
      name: 'addPollOption',
      desc: '',
      args: [],
    );
  }

  /// `Forbid`
  String get forbid {
    return Intl.message(
      'Forbid',
      name: 'forbid',
      desc: '',
      args: [],
    );
  }

  /// `Sign fail`
  String get signFail {
    return Intl.message(
      'Sign fail',
      name: 'signFail',
      desc: '',
      args: [],
    );
  }

  /// `Method`
  String get method {
    return Intl.message(
      'Method',
      name: 'method',
      desc: '',
      args: [],
    );
  }

  /// `Content`
  String get content {
    return Intl.message(
      'Content',
      name: 'content',
      desc: '',
      args: [],
    );
  }

  /// `Use lightning wallet scan and send sats.`
  String get useLightningWalletScanAndSendSats {
    return Intl.message(
      'Use lightning wallet scan and send sats.',
      name: 'useLightningWalletScanAndSendSats',
      desc: '',
      args: [],
    );
  }

  /// `Any`
  String get any {
    return Intl.message(
      'Any',
      name: 'any',
      desc: '',
      args: [],
    );
  }

  /// `Lightning Invoice`
  String get lightningInvoice {
    return Intl.message(
      'Lightning Invoice',
      name: 'lightningInvoice',
      desc: '',
      args: [],
    );
  }

  /// `Pay`
  String get pay {
    return Intl.message(
      'Pay',
      name: 'pay',
      desc: '',
      args: [],
    );
  }

  /// `There should be an universe here`
  String get thereShouldBeAnUniverseHere {
    return Intl.message(
      'There should be an universe here',
      name: 'thereShouldBeAnUniverseHere',
      desc: '',
      args: [],
    );
  }

  /// `More`
  String get more {
    return Intl.message(
      'More',
      name: 'more',
      desc: '',
      args: [],
    );
  }

  /// `Add a Note`
  String get addANote {
    return Intl.message(
      'Add a Note',
      name: 'addANote',
      desc: '',
      args: [],
    );
  }

  /// `Home`
  String get home {
    return Intl.message(
      'Home',
      name: 'home',
      desc: '',
      args: [],
    );
  }

  /// `Begin to load Contact History`
  String get beginToLoadContactHistory {
    return Intl.message(
      'Begin to load Contact History',
      name: 'beginToLoadContactHistory',
      desc: '',
      args: [],
    );
  }

  /// `Recovery`
  String get recovery {
    return Intl.message(
      'Recovery',
      name: 'recovery',
      desc: '',
      args: [],
    );
  }

  /// `Source`
  String get source {
    return Intl.message(
      'Source',
      name: 'source',
      desc: '',
      args: [],
    );
  }

  /// `Image save success`
  String get imageSaveSuccess {
    return Intl.message(
      'Image save success',
      name: 'imageSaveSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Publish failed`
  String get sendFail {
    return Intl.message(
      'Publish failed',
      name: 'sendFail',
      desc: '',
      args: [],
    );
  }

  /// `Show web`
  String get showWeb {
    return Intl.message(
      'Show web',
      name: 'showWeb',
      desc: '',
      args: [],
    );
  }

  /// `Web Utils`
  String get webUtils {
    return Intl.message(
      'Web Utils',
      name: 'webUtils',
      desc: '',
      args: [],
    );
  }

  /// `Input Comment`
  String get inputComment {
    return Intl.message(
      'Input Comment',
      name: 'inputComment',
      desc: '',
      args: [],
    );
  }

  /// `Optional`
  String get optional {
    return Intl.message(
      'Optional',
      name: 'optional',
      desc: '',
      args: [],
    );
  }

  /// `Notify`
  String get notify {
    return Intl.message(
      'Notify',
      name: 'notify',
      desc: '',
      args: [],
    );
  }

  /// `Content warning`
  String get contentWarning {
    return Intl.message(
      'Content warning',
      name: 'contentWarning',
      desc: '',
      args: [],
    );
  }

  /// `This note contains sensitive content`
  String get thisNoteContainsSensitiveContent {
    return Intl.message(
      'This note contains sensitive content',
      name: 'thisNoteContainsSensitiveContent',
      desc: '',
      args: [],
    );
  }

  /// `Please input title`
  String get pleaseInputTitle {
    return Intl.message(
      'Please input title',
      name: 'pleaseInputTitle',
      desc: '',
      args: [],
    );
  }

  /// `Hour`
  String get hour {
    return Intl.message(
      'Hour',
      name: 'hour',
      desc: '',
      args: [],
    );
  }

  /// `Minute`
  String get minute {
    return Intl.message(
      'Minute',
      name: 'minute',
      desc: '',
      args: [],
    );
  }

  /// `Add Custom Emoji`
  String get addCustomEmoji {
    return Intl.message(
      'Add Custom Emoji',
      name: 'addCustomEmoji',
      desc: '',
      args: [],
    );
  }

  /// `Input Custom Emoji Name`
  String get inputCustomEmojiName {
    return Intl.message(
      'Input Custom Emoji Name',
      name: 'inputCustomEmojiName',
      desc: '',
      args: [],
    );
  }

  /// `Custom`
  String get custom {
    return Intl.message(
      'Custom',
      name: 'custom',
      desc: '',
      args: [],
    );
  }

  /// `Followed Tags`
  String get followedTags {
    return Intl.message(
      'Followed Tags',
      name: 'followedTags',
      desc: '',
      args: [],
    );
  }

  /// `From`
  String get from {
    return Intl.message(
      'From',
      name: 'from',
      desc: '',
      args: [],
    );
  }

  /// `Followed Communities`
  String get followedCommunities {
    return Intl.message(
      'Followed Communities',
      name: 'followedCommunities',
      desc: '',
      args: [],
    );
  }

  /// `Followed`
  String get followed {
    return Intl.message(
      'Followed',
      name: 'followed',
      desc: '',
      args: [],
    );
  }

  /// `Auto Open Sensitive Content`
  String get autoOpenSensitiveContent {
    return Intl.message(
      'Auto Open Sensitive Content',
      name: 'autoOpenSensitiveContent',
      desc: '',
      args: [],
    );
  }

  /// `Goal Amount In Sats`
  String get goalAmountInSats {
    return Intl.message(
      'Goal Amount In Sats',
      name: 'goalAmountInSats',
      desc: '',
      args: [],
    );
  }

  /// `Relay Mode`
  String get relayMode {
    return Intl.message(
      'Relay Mode',
      name: 'relayMode',
      desc: '',
      args: [],
    );
  }

  /// `Event Sign Check`
  String get eventSignCheck {
    return Intl.message(
      'Event Sign Check',
      name: 'eventSignCheck',
      desc: '',
      args: [],
    );
  }

  /// `Fast Mode`
  String get fastMode {
    return Intl.message(
      'Fast Mode',
      name: 'fastMode',
      desc: '',
      args: [],
    );
  }

  /// `Base Mode`
  String get baseMode {
    return Intl.message(
      'Base Mode',
      name: 'baseMode',
      desc: '',
      args: [],
    );
  }

  /// `WebRTC Permission`
  String get webRTCPermission {
    return Intl.message(
      'WebRTC Permission',
      name: 'webRTCPermission',
      desc: '',
      args: [],
    );
  }

  /// `Get Public Key`
  String get nip07GetPublicKey {
    return Intl.message(
      'Get Public Key',
      name: 'nip07GetPublicKey',
      desc: '',
      args: [],
    );
  }

  /// `Sign Event`
  String get nip07SignEvent {
    return Intl.message(
      'Sign Event',
      name: 'nip07SignEvent',
      desc: '',
      args: [],
    );
  }

  /// `Get Relays`
  String get nip07GetRelays {
    return Intl.message(
      'Get Relays',
      name: 'nip07GetRelays',
      desc: '',
      args: [],
    );
  }

  /// `Encrypt`
  String get nip07Encrypt {
    return Intl.message(
      'Encrypt',
      name: 'nip07Encrypt',
      desc: '',
      args: [],
    );
  }

  /// `Decrypt`
  String get nip07Decrypt {
    return Intl.message(
      'Decrypt',
      name: 'nip07Decrypt',
      desc: '',
      args: [],
    );
  }

  /// `Lightning payment`
  String get nip07Lightning {
    return Intl.message(
      'Lightning payment',
      name: 'nip07Lightning',
      desc: '',
      args: [],
    );
  }

  /// `Show more`
  String get showMore {
    return Intl.message(
      'Show more',
      name: 'showMore',
      desc: '',
      args: [],
    );
  }

  /// `Limit Note Height`
  String get limitNoteHeight {
    return Intl.message(
      'Limit Note Height',
      name: 'limitNoteHeight',
      desc: '',
      args: [],
    );
  }

  /// `Add to private bookmark`
  String get addToPrivateBookmark {
    return Intl.message(
      'Add to private bookmark',
      name: 'addToPrivateBookmark',
      desc: '',
      args: [],
    );
  }

  /// `Add to public bookmark`
  String get addToPublicBookmark {
    return Intl.message(
      'Add to public bookmark',
      name: 'addToPublicBookmark',
      desc: '',
      args: [],
    );
  }

  /// `Remove from private bookmark`
  String get removeFromPrivateBookmark {
    return Intl.message(
      'Remove from private bookmark',
      name: 'removeFromPrivateBookmark',
      desc: '',
      args: [],
    );
  }

  /// `Remove from public bookmark`
  String get removeFromPublicBookmark {
    return Intl.message(
      'Remove from public bookmark',
      name: 'removeFromPublicBookmark',
      desc: '',
      args: [],
    );
  }

  /// `Private`
  String get private {
    return Intl.message(
      'Private',
      name: 'private',
      desc: '',
      args: [],
    );
  }

  /// `Public`
  String get public {
    return Intl.message(
      'Public',
      name: 'public',
      desc: '',
      args: [],
    );
  }

  /// `Creator`
  String get creator {
    return Intl.message(
      'Creator',
      name: 'creator',
      desc: '',
      args: [],
    );
  }

  /// `Wear`
  String get wear {
    return Intl.message(
      'Wear',
      name: 'wear',
      desc: '',
      args: [],
    );
  }

  /// `Private Direct Message is a new message type that some clients do not yet support.`
  String get privateDMNotice {
    return Intl.message(
      'Private Direct Message is a new message type that some clients do not yet support.',
      name: 'privateDMNotice',
      desc: '',
      args: [],
    );
  }

  /// `Local Relay`
  String get localRelay {
    return Intl.message(
      'Local Relay',
      name: 'localRelay',
      desc: '',
      args: [],
    );
  }

  /// `My Relays`
  String get myRelays {
    return Intl.message(
      'My Relays',
      name: 'myRelays',
      desc: '',
      args: [],
    );
  }

  /// `Temp Relays`
  String get tempRelays {
    return Intl.message(
      'Temp Relays',
      name: 'tempRelays',
      desc: '',
      args: [],
    );
  }

  /// `Url`
  String get url {
    return Intl.message(
      'Url',
      name: 'url',
      desc: '',
      args: [],
    );
  }

  /// `Owner`
  String get owner {
    return Intl.message(
      'Owner',
      name: 'owner',
      desc: '',
      args: [],
    );
  }

  /// `Contact`
  String get contact {
    return Intl.message(
      'Contact',
      name: 'contact',
      desc: '',
      args: [],
    );
  }

  /// `Soft`
  String get soft {
    return Intl.message(
      'Soft',
      name: 'soft',
      desc: '',
      args: [],
    );
  }

  /// `Version`
  String get version {
    return Intl.message(
      'Version',
      name: 'version',
      desc: '',
      args: [],
    );
  }

  /// `Relay Info`
  String get relayInfo {
    return Intl.message(
      'Relay Info',
      name: 'relayInfo',
      desc: '',
      args: [],
    );
  }

  /// `DMs`
  String get dms {
    return Intl.message(
      'DMs',
      name: 'dms',
      desc: '',
      args: [],
    );
  }

  /// `Close Private DM`
  String get closePrivateDM {
    return Intl.message(
      'Close Private DM',
      name: 'closePrivateDM',
      desc: '',
      args: [],
    );
  }

  /// `Open Private DM`
  String get openPrivateDM {
    return Intl.message(
      'Open Private DM',
      name: 'openPrivateDM',
      desc: '',
      args: [],
    );
  }

  /// `Image or Video`
  String get imageOrVideo {
    return Intl.message(
      'Image or Video',
      name: 'imageOrVideo',
      desc: '',
      args: [],
    );
  }

  /// `Take photo`
  String get takePhoto {
    return Intl.message(
      'Take photo',
      name: 'takePhoto',
      desc: '',
      args: [],
    );
  }

  /// `Take video`
  String get takeVideo {
    return Intl.message(
      'Take video',
      name: 'takeVideo',
      desc: '',
      args: [],
    );
  }

  /// `Custom Emoji`
  String get customEmoji {
    return Intl.message(
      'Custom Emoji',
      name: 'customEmoji',
      desc: '',
      args: [],
    );
  }

  /// `Emoji`
  String get emoji {
    return Intl.message(
      'Emoji',
      name: 'emoji',
      desc: '',
      args: [],
    );
  }

  /// `Mention User`
  String get mentionUser {
    return Intl.message(
      'Mention User',
      name: 'mentionUser',
      desc: '',
      args: [],
    );
  }

  /// `Hashtag`
  String get hashtag {
    return Intl.message(
      'Hashtag',
      name: 'hashtag',
      desc: '',
      args: [],
    );
  }

  /// `Sensitive Content`
  String get sensitiveContent {
    return Intl.message(
      'Sensitive Content',
      name: 'sensitiveContent',
      desc: '',
      args: [],
    );
  }

  /// `Subject`
  String get subject {
    return Intl.message(
      'Subject',
      name: 'subject',
      desc: '',
      args: [],
    );
  }

  /// `Delay Send`
  String get delaySend {
    return Intl.message(
      'Delay Send',
      name: 'delaySend',
      desc: '',
      args: [],
    );
  }

  /// `Poll`
  String get poll {
    return Intl.message(
      'Poll',
      name: 'poll',
      desc: '',
      args: [],
    );
  }

  /// `Zap Goals`
  String get zapGoals {
    return Intl.message(
      'Zap Goals',
      name: 'zapGoals',
      desc: '',
      args: [],
    );
  }

  /// `Data Sync Mode`
  String get dataSyncMode {
    return Intl.message(
      'Data Sync Mode',
      name: 'dataSyncMode',
      desc: '',
      args: [],
    );
  }

  /// `Backup my notes`
  String get backupMyNotes {
    return Intl.message(
      'Backup my notes',
      name: 'backupMyNotes',
      desc: '',
      args: [],
    );
  }

  /// `Import notes`
  String get importNotes {
    return Intl.message(
      'Import notes',
      name: 'importNotes',
      desc: '',
      args: [],
    );
  }

  /// `File save success`
  String get fileSaveSuccess {
    return Intl.message(
      'File save success',
      name: 'fileSaveSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Sync Upload`
  String get syncUpload {
    return Intl.message(
      'Sync Upload',
      name: 'syncUpload',
      desc: '',
      args: [],
    );
  }

  /// `Upload num`
  String get uploadNum {
    return Intl.message(
      'Upload num',
      name: 'uploadNum',
      desc: '',
      args: [],
    );
  }

  /// `Send interval`
  String get sendInterval {
    return Intl.message(
      'Send interval',
      name: 'sendInterval',
      desc: '',
      args: [],
    );
  }

  /// `Select relay to upload`
  String get selectRelayToUpload {
    return Intl.message(
      'Select relay to upload',
      name: 'selectRelayToUpload',
      desc: '',
      args: [],
    );
  }

  /// `Please select relays`
  String get pleaseSelectRelays {
    return Intl.message(
      'Please select relays',
      name: 'pleaseSelectRelays',
      desc: '',
      args: [],
    );
  }

  /// `Follow set`
  String get followSet {
    return Intl.message(
      'Follow set',
      name: 'followSet',
      desc: '',
      args: [],
    );
  }

  /// `Follow set name edit`
  String get followSetNameEdit {
    return Intl.message(
      'Follow set name edit',
      name: 'followSetNameEdit',
      desc: '',
      args: [],
    );
  }

  /// `Input follow set name`
  String get inputFollowSetName {
    return Intl.message(
      'Input follow set name',
      name: 'inputFollowSetName',
      desc: '',
      args: [],
    );
  }

  /// `Edit name`
  String get editName {
    return Intl.message(
      'Edit name',
      name: 'editName',
      desc: '',
      args: [],
    );
  }

  /// `Edit`
  String get edit {
    return Intl.message(
      'Edit',
      name: 'edit',
      desc: '',
      args: [],
    );
  }

  /// `Thread Mode`
  String get threadMode {
    return Intl.message(
      'Thread Mode',
      name: 'threadMode',
      desc: '',
      args: [],
    );
  }

  /// `Max Sub Notes`
  String get maxSubNotes {
    return Intl.message(
      'Max Sub Notes',
      name: 'maxSubNotes',
      desc: '',
      args: [],
    );
  }

  /// `Full Mode`
  String get fullMode {
    return Intl.message(
      'Full Mode',
      name: 'fullMode',
      desc: '',
      args: [],
    );
  }

  /// `Trace Mode`
  String get traceMode {
    return Intl.message(
      'Trace Mode',
      name: 'traceMode',
      desc: '',
      args: [],
    );
  }

  /// `Please input the max sub notes number`
  String get pleaseInputTheMaxSubNotesNumber {
    return Intl.message(
      'Please input the max sub notes number',
      name: 'pleaseInputTheMaxSubNotesNumber',
      desc: '',
      args: [],
    );
  }

  /// `Show more replies`
  String get showMoreReplies {
    return Intl.message(
      'Show more replies',
      name: 'showMoreReplies',
      desc: '',
      args: [],
    );
  }

  /// `This operation cannot be undo`
  String get thisOperationCannotBeUndo {
    return Intl.message(
      'This operation cannot be undo',
      name: 'thisOperationCannotBeUndo',
      desc: '',
      args: [],
    );
  }

  /// `Data Length`
  String get dataLength {
    return Intl.message(
      'Data Length',
      name: 'dataLength',
      desc: '',
      args: [],
    );
  }

  /// `File Size`
  String get fileSize {
    return Intl.message(
      'File Size',
      name: 'fileSize',
      desc: '',
      args: [],
    );
  }

  /// `Clear All Data`
  String get clearAllData {
    return Intl.message(
      'Clear All Data',
      name: 'clearAllData',
      desc: '',
      args: [],
    );
  }

  /// `Clear Not My Data`
  String get clearNotMyData {
    return Intl.message(
      'Clear Not My Data',
      name: 'clearNotMyData',
      desc: '',
      args: [],
    );
  }

  /// `File is too big for NIP-95`
  String get fileIsTooBigForNIP95 {
    return Intl.message(
      'File is too big for NIP-95',
      name: 'fileIsTooBigForNIP95',
      desc: '',
      args: [],
    );
  }

  /// `Address`
  String get address {
    return Intl.message(
      'Address',
      name: 'address',
      desc: '',
      args: [],
    );
  }

  /// `Lightning Address`
  String get lightningAddress {
    return Intl.message(
      'Lightning Address',
      name: 'lightningAddress',
      desc: '',
      args: [],
    );
  }

  /// `Hide Relay Notices`
  String get hideRelayNotices {
    return Intl.message(
      'Hide Relay Notices',
      name: 'hideRelayNotices',
      desc: '',
      args: [],
    );
  }

  /// `Popular Users`
  String get popularUsers {
    return Intl.message(
      'Popular Users',
      name: 'popularUsers',
      desc: '',
      args: [],
    );
  }

  /// `Split and Transfer Zap`
  String get splitAndTransferZap {
    return Intl.message(
      'Split and Transfer Zap',
      name: 'splitAndTransferZap',
      desc: '',
      args: [],
    );
  }

  /// `The support client will split and transfer zaps to the users you had added.`
  String get splitZapTip {
    return Intl.message(
      'The support client will split and transfer zaps to the users you had added.',
      name: 'splitZapTip',
      desc: '',
      args: [],
    );
  }

  /// `Add User`
  String get addUser {
    return Intl.message(
      'Add User',
      name: 'addUser',
      desc: '',
      args: [],
    );
  }

  /// `Zap number not enough`
  String get zapNumberNotEnough {
    return Intl.message(
      'Zap number not enough',
      name: 'zapNumberNotEnough',
      desc: '',
      args: [],
    );
  }

  /// `NWC is Nostr Wallet Connect, with NWC Setting you zap within the app.`
  String get nwcTip1 {
    return Intl.message(
      'NWC is Nostr Wallet Connect, with NWC Setting you zap within the app.',
      name: 'nwcTip1',
      desc: '',
      args: [],
    );
  }

  /// `NWC URL is like`
  String get nwcTip2 {
    return Intl.message(
      'NWC URL is like',
      name: 'nwcTip2',
      desc: '',
      args: [],
    );
  }

  /// `PLease input NWC URL`
  String get pleaseInputNWCURL {
    return Intl.message(
      'PLease input NWC URL',
      name: 'pleaseInputNWCURL',
      desc: '',
      args: [],
    );
  }

  /// `is sending`
  String get isSending {
    return Intl.message(
      'is sending',
      name: 'isSending',
      desc: '',
      args: [],
    );
  }

  /// `Image service path`
  String get imageServicePath {
    return Intl.message(
      'Image service path',
      name: 'imageServicePath',
      desc: '',
      args: [],
    );
  }

  /// `Image`
  String get image {
    return Intl.message(
      'Image',
      name: 'image',
      desc: '',
      args: [],
    );
  }

  /// `Download`
  String get download {
    return Intl.message(
      'Download',
      name: 'download',
      desc: '',
      args: [],
    );
  }

  /// `Pubkey`
  String get pubkey {
    return Intl.message(
      'Pubkey',
      name: 'pubkey',
      desc: '',
      args: [],
    );
  }

  /// `Login fail`
  String get loginFail {
    return Intl.message(
      'Login fail',
      name: 'loginFail',
      desc: '',
      args: [],
    );
  }

  /// `You are logged in in read-only mode.`
  String get readonlyLoginTip {
    return Intl.message(
      'You are logged in in read-only mode.',
      name: 'readonlyLoginTip',
      desc: '',
      args: [],
    );
  }

  /// `Login With Android Signer`
  String get loginWithAndroidSigner {
    return Intl.message(
      'Login With Android Signer',
      name: 'loginWithAndroidSigner',
      desc: '',
      args: [],
    );
  }

  /// `Read Only`
  String get readOnly {
    return Intl.message(
      'Read Only',
      name: 'readOnly',
      desc: '',
      args: [],
    );
  }

  /// `Login With NIP07 Extension`
  String get loginWithNIP07Extension {
    return Intl.message(
      'Login With NIP07 Extension',
      name: 'loginWithNIP07Extension',
      desc: '',
      args: [],
    );
  }

  /// `Group`
  String get group {
    return Intl.message(
      'Group',
      name: 'group',
      desc: '',
      args: [],
    );
  }

  /// `Groups`
  String get groups {
    return Intl.message(
      'Groups',
      name: 'groups',
      desc: '',
      args: [],
    );
  }

  /// `Admins`
  String get admins {
    return Intl.message(
      'Admins',
      name: 'admins',
      desc: '',
      args: [],
    );
  }

  /// `Members`
  String get members {
    return Intl.message(
      'Members',
      name: 'members',
      desc: '',
      args: [],
    );
  }

  /// `Relay`
  String get relay {
    return Intl.message(
      'Relay',
      name: 'relay',
      desc: '',
      args: [],
    );
  }

  /// `GroupId`
  String get groupId {
    return Intl.message(
      'GroupId',
      name: 'groupId',
      desc: '',
      args: [],
    );
  }

  /// `public`
  String get publicType {
    return Intl.message(
      'public',
      name: 'publicType',
      desc: '',
      args: [],
    );
  }

  /// `private`
  String get privateType {
    return Intl.message(
      'private',
      name: 'privateType',
      desc: '',
      args: [],
    );
  }

  /// `closed`
  String get closedType {
    return Intl.message(
      'closed',
      name: 'closedType',
      desc: '',
      args: [],
    );
  }

  /// `Chat`
  String get chat {
    return Intl.message(
      'Chat',
      name: 'chat',
      desc: '',
      args: [],
    );
  }

  /// `Add`
  String get add {
    return Intl.message(
      'Add',
      name: 'add',
      desc: '',
      args: [],
    );
  }

  /// `Join Group`
  String get joinGroup {
    return Intl.message(
      'Join Group',
      name: 'joinGroup',
      desc: '',
      args: [],
    );
  }

  /// `Create Group`
  String get createGroup {
    return Intl.message(
      'Create Group',
      name: 'createGroup',
      desc: '',
      args: [],
    );
  }

  /// `Cache Relay`
  String get cacheRelay {
    return Intl.message(
      'Cache Relay',
      name: 'cacheRelay',
      desc: '',
      args: [],
    );
  }

  /// `Normal`
  String get normal {
    return Intl.message(
      'Normal',
      name: 'normal',
      desc: '',
      args: [],
    );
  }

  /// `Cache`
  String get cache {
    return Intl.message(
      'Cache',
      name: 'cache',
      desc: '',
      args: [],
    );
  }

  /// `Copy`
  String get copy {
    return Intl.message(
      'Copy',
      name: 'copy',
      desc: '',
      args: [],
    );
  }

  /// `Please input summary`
  String get pleaseInputSummary {
    return Intl.message(
      'Please input summary',
      name: 'pleaseInputSummary',
      desc: '',
      args: [],
    );
  }

  /// `Opened`
  String get opened {
    return Intl.message(
      'Opened',
      name: 'opened',
      desc: '',
      args: [],
    );
  }

  /// `Closed`
  String get closed {
    return Intl.message(
      'Closed',
      name: 'closed',
      desc: '',
      args: [],
    );
  }

  /// `Member`
  String get member {
    return Intl.message(
      'Member',
      name: 'member',
      desc: '',
      args: [],
    );
  }

  /// `group`
  String get groupType {
    return Intl.message(
      'group',
      name: 'groupType',
      desc: '',
      args: [],
    );
  }

  /// `Group Info`
  String get groupInfo {
    return Intl.message(
      'Group Info',
      name: 'groupInfo',
      desc: '',
      args: [],
    );
  }

  /// `Your Groups`
  String get yourGroups {
    return Intl.message(
      'Your Groups',
      name: 'yourGroups',
      desc: '',
      args: [],
    );
  }

  /// `Admin`
  String get admin {
    return Intl.message(
      'Admin',
      name: 'admin',
      desc: '',
      args: [],
    );
  }

  /// `Admin Panel`
  String get adminPanel {
    return Intl.message(
      'Admin Panel',
      name: 'adminPanel',
      desc: '',
      args: [],
    );
  }

  /// `Update Image`
  String get updateImage {
    return Intl.message(
      'Update Image',
      name: 'updateImage',
      desc: '',
      args: [],
    );
  }

  /// `Community Name`
  String get communityNameHeader {
    return Intl.message(
      'Community Name',
      name: 'communityNameHeader',
      desc: '',
      args: [],
    );
  }

  /// `Enter a name for your community`
  String get enterCommunityName {
    return Intl.message(
      'Enter a name for your community',
      name: 'enterCommunityName',
      desc: '',
      args: [],
    );
  }

  /// `Enter a description of your community`
  String get enterCommunityDescription {
    return Intl.message(
      'Enter a description of your community',
      name: 'enterCommunityDescription',
      desc: '',
      args: [],
    );
  }

  /// `Enter the guidelines of your community`
  String get enterCommunityGuidelines {
    return Intl.message(
      'Enter the guidelines of your community',
      name: 'enterCommunityGuidelines',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get description {
    return Intl.message(
      'Description',
      name: 'description',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message(
      'Save',
      name: 'save',
      desc: '',
      args: [],
    );
  }

  /// `An error occurred while trying to save your data.`
  String get saveFailed {
    return Intl.message(
      'An error occurred while trying to save your data.',
      name: 'saveFailed',
      desc: '',
      args: [],
    );
  }

  /// `Image upload failed`
  String get imageUploadFailed {
    return Intl.message(
      'Image upload failed',
      name: 'imageUploadFailed',
      desc: '',
      args: [],
    );
  }

  /// `All media is publicly accessible to anyone with the URL.`
  String get allMediaPublic {
    return Intl.message(
      'All media is publicly accessible to anyone with the URL.',
      name: 'allMediaPublic',
      desc: '',
      args: [],
    );
  }

  /// `Development`
  String get development {
    return Intl.message(
      'Development',
      name: 'development',
      desc: '',
      args: [],
    );
  }

  /// `Closed group`
  String get closedGroup {
    return Intl.message(
      'Closed group',
      name: 'closedGroup',
      desc: '',
      args: [],
    );
  }

  /// `Open group`
  String get openGroup {
    return Intl.message(
      'Open group',
      name: 'openGroup',
      desc: '',
      args: [],
    );
  }

  /// `{number} Member`
  String groupMember(int number) {
    return Intl.message(
      '$number Member',
      name: 'groupMember',
      desc: '',
      args: [number],
    );
  }

  /// `{number} Members`
  String groupMembers(int number) {
    return Intl.message(
      '$number Members',
      name: 'groupMembers',
      desc: '',
      args: [number],
    );
  }

  /// `Are you over 16 years old?`
  String get ageVerificationQuestion {
    return Intl.message(
      'Are you over 16 years old?',
      name: 'ageVerificationQuestion',
      desc: '',
      args: [],
    );
  }

  /// `For legal reasons, we need to make sure you're over this age to use Plur.`
  String get ageVerificationMessage {
    return Intl.message(
      'For legal reasons, we need to make sure you\'re over this age to use Plur.',
      name: 'ageVerificationMessage',
      desc: '',
      args: [],
    );
  }

  /// `No`
  String get no {
    return Intl.message(
      'No',
      name: 'no',
      desc: '',
      args: [],
    );
  }

  /// `Yes`
  String get yes {
    return Intl.message(
      'Yes',
      name: 'yes',
      desc: '',
      args: [],
    );
  }

  /// `Create your community`
  String get createYourCommunity {
    return Intl.message(
      'Create your community',
      name: 'createYourCommunity',
      desc: '',
      args: [],
    );
  }

  /// `community name`
  String get communityName {
    return Intl.message(
      'community name',
      name: 'communityName',
      desc: '',
      args: [],
    );
  }

  /// `Name your community`
  String get nameYourCommunity {
    return Intl.message(
      'Name your community',
      name: 'nameYourCommunity',
      desc: '',
      args: [],
    );
  }

  /// `Start or join a community`
  String get startOrJoinACommunity {
    return Intl.message(
      'Start or join a community',
      name: 'startOrJoinACommunity',
      desc: '',
      args: [],
    );
  }

  /// `Connect with others by creating your own community or joining an existing one with an invite link.`
  String get connectWithOthers {
    return Intl.message(
      'Connect with others by creating your own community or joining an existing one with an invite link.',
      name: 'connectWithOthers',
      desc: '',
      args: [],
    );
  }

  /// `Have an invite link? Tap on it to join a community.`
  String get haveInviteLink {
    return Intl.message(
      'Have an invite link? Tap on it to join a community.',
      name: 'haveInviteLink',
      desc: '',
      args: [],
    );
  }

  /// `What should we call you?`
  String get onboardingNameInputTitle {
    return Intl.message(
      'What should we call you?',
      name: 'onboardingNameInputTitle',
      desc: '',
      args: [],
    );
  }

  /// `Your name or nickname`
  String get onboardingNameInputHint {
    return Intl.message(
      'Your name or nickname',
      name: 'onboardingNameInputHint',
      desc: '',
      args: [],
    );
  }

  /// `Continue`
  String get continueButton {
    return Intl.message(
      'Continue',
      name: 'continueButton',
      desc: '',
      args: [],
    );
  }

  /// `Find Group`
  String get findGroup {
    return Intl.message(
      'Find Group',
      name: 'findGroup',
      desc: '',
      args: [],
    );
  }

  /// `Discover Groups`
  String get discoverGroups {
    return Intl.message(
      'Discover Groups',
      name: 'discoverGroups',
      desc: '',
      args: [],
    );
  }

  /// `Search for public groups`
  String get searchForPublicGroups {
    return Intl.message(
      'Search for public groups',
      name: 'searchForPublicGroups',
      desc: '',
      args: [],
    );
  }

  /// `Active`
  String get active {
    return Intl.message(
      'Active',
      name: 'active',
      desc: '',
      args: [],
    );
  }

  /// `Actions`
  String get actions {
    return Intl.message(
      'Actions',
      name: 'actions',
      desc: '',
      args: [],
    );
  }

  /// `Invite`
  String get invite {
    return Intl.message(
      'Invite',
      name: 'invite',
      desc: '',
      args: [],
    );
  }

  /// `Leave Group`
  String get leaveGroup {
    return Intl.message(
      'Leave Group',
      name: 'leaveGroup',
      desc: '',
      args: [],
    );
  }

  /// `Leave Group?`
  String get leaveGroupQuestion {
    return Intl.message(
      'Leave Group?',
      name: 'leaveGroupQuestion',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to leave this group?`
  String get leaveGroupConfirmation {
    return Intl.message(
      'Are you sure you want to leave this group?',
      name: 'leaveGroupConfirmation',
      desc: '',
      args: [],
    );
  }

  /// `Leave`
  String get leave {
    return Intl.message(
      'Leave',
      name: 'leave',
      desc: '',
      args: [],
    );
  }

  /// `Menu`
  String get menu {
    return Intl.message(
      'Menu',
      name: 'menu',
      desc: '',
      args: [],
    );
  }

  /// `Media`
  String get media {
    return Intl.message(
      'Media',
      name: 'media',
      desc: '',
      args: [],
    );
  }

  /// `Links`
  String get links {
    return Intl.message(
      'Links',
      name: 'links',
      desc: '',
      args: [],
    );
  }

  /// `Places`
  String get places {
    return Intl.message(
      'Places',
      name: 'places',
      desc: '',
      args: [],
    );
  }

  /// `Events`
  String get events {
    return Intl.message(
      'Events',
      name: 'events',
      desc: '',
      args: [],
    );
  }

  /// `No Media found`
  String get noMediaFound {
    return Intl.message(
      'No Media found',
      name: 'noMediaFound',
      desc: '',
      args: [],
    );
  }

  /// `Add photos to your posts to see them here.`
  String get addPhotosToYourPosts {
    return Intl.message(
      'Add photos to your posts to see them here.',
      name: 'addPhotosToYourPosts',
      desc: '',
      args: [],
    );
  }

  /// `Edit Group`
  String get editGroup {
    return Intl.message(
      'Edit Group',
      name: 'editGroup',
      desc: '',
      args: [],
    );
  }

  /// `Edit Details`
  String get editDetails {
    return Intl.message(
      'Edit Details',
      name: 'editDetails',
      desc: '',
      args: [],
    );
  }

  /// `Remove`
  String get remove {
    return Intl.message(
      'Remove',
      name: 'remove',
      desc: '',
      args: [],
    );
  }

  /// `Changes saved successfully`
  String get changesSaved {
    return Intl.message(
      'Changes saved successfully',
      name: 'changesSaved',
      desc: '',
      args: [],
    );
  }

  /// `Error saving changes`
  String get saveError {
    return Intl.message(
      'Error saving changes',
      name: 'saveError',
      desc: '',
      args: [],
    );
  }

  /// `Community name is required`
  String get communityNameRequired {
    return Intl.message(
      'Community name is required',
      name: 'communityNameRequired',
      desc: '',
      args: [],
    );
  }

  /// `Visible to everyone in the network`
  String get groupPublicDescription {
    return Intl.message(
      'Visible to everyone in the network',
      name: 'groupPublicDescription',
      desc: '',
      args: [],
    );
  }

  /// `Only visible to members of this group`
  String get groupPrivateDescription {
    return Intl.message(
      'Only visible to members of this group',
      name: 'groupPrivateDescription',
      desc: '',
      args: [],
    );
  }

  /// `Anyone can join without approval`
  String get groupOpenDescription {
    return Intl.message(
      'Anyone can join without approval',
      name: 'groupOpenDescription',
      desc: '',
      args: [],
    );
  }

  /// `Requires invitation or approval to join`
  String get groupClosedDescription {
    return Intl.message(
      'Requires invitation or approval to join',
      name: 'groupClosedDescription',
      desc: '',
      args: [],
    );
  }

  /// `Invite people to join this group`
  String get invitePeopleToJoin {
    return Intl.message(
      'Invite people to join this group',
      name: 'invitePeopleToJoin',
      desc: '',
      args: [],
    );
  }

  /// `Done`
  String get done {
    return Intl.message(
      'Done',
      name: 'done',
      desc: '',
      args: [],
    );
  }

  /// `Share this link with people you want to invite to the group.`
  String get shareInviteDescription {
    return Intl.message(
      'Share this link with people you want to invite to the group.',
      name: 'shareInviteDescription',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ar'),
      Locale.fromSubtags(languageCode: 'bg'),
      Locale.fromSubtags(languageCode: 'cs'),
      Locale.fromSubtags(languageCode: 'da'),
      Locale.fromSubtags(languageCode: 'de'),
      Locale.fromSubtags(languageCode: 'el'),
      Locale.fromSubtags(languageCode: 'es'),
      Locale.fromSubtags(languageCode: 'et'),
      Locale.fromSubtags(languageCode: 'fi'),
      Locale.fromSubtags(languageCode: 'fr'),
      Locale.fromSubtags(languageCode: 'hu'),
      Locale.fromSubtags(languageCode: 'it'),
      Locale.fromSubtags(languageCode: 'ja'),
      Locale.fromSubtags(languageCode: 'ko'),
      Locale.fromSubtags(languageCode: 'nl'),
      Locale.fromSubtags(languageCode: 'pl'),
      Locale.fromSubtags(languageCode: 'pt'),
      Locale.fromSubtags(languageCode: 'ro'),
      Locale.fromSubtags(languageCode: 'ru'),
      Locale.fromSubtags(languageCode: 'sl'),
      Locale.fromSubtags(languageCode: 'sv'),
      Locale.fromSubtags(languageCode: 'th'),
      Locale.fromSubtags(languageCode: 'vi'),
      Locale.fromSubtags(languageCode: 'zh'),
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
