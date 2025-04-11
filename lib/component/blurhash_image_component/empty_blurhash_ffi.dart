// Empty stub file for iOS/macOS platforms
// This is used for conditional imports
library empty_blurhash_ffi;

class BlurhashFfiImage {
  final String hash;
  final int decodingWidth;
  final int decodingHeight;

  BlurhashFfiImage(this.hash, {required this.decodingWidth, required this.decodingHeight});
}