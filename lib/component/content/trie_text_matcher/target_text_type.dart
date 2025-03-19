class TargetTextType {
  static const int pureText = 1;

  // md link: [xxx](http://xxxx)
  static const int mdLink = 101;

  // md image: ![xxx](http://xxxx)
  static const int mdImage = 102;

  // md bold: **xxx** or __xxx__
  static const int mdBold = 103;

  // md italic: *xxx* or _xxx_
  static const int mdItalic = 104;

  // md delete: ~~xxx~~
  static const int mdDelete = 105;

  // md highlight: ==xxx==
  static const int mdHighlight = 106;

  // md italic: `xxx` or ```xxx```
  static const int mdInlineCode = 107;

  // md All bold and italic: ***xx***
  static const int mdBoldAndItalic = 108;

  // nostr emoji: :xxx:
  static const int nostrCustomEmoji = 1010;
}
