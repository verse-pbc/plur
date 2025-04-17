// Web stub for cookie operations
// This file provides stub implementations for cookie operations
// used on web platform where they need different handling

// Mock Cookie class for web
class WebCookie {
  final String name;
  final String value;
  final String? domain;
  final String? path;
  final DateTime? expires;
  final bool httpOnly;
  final bool secure;
  
  WebCookie(
    this.name,
    this.value, {
    this.domain,
    this.path,
    this.expires,
    this.httpOnly = false,
    this.secure = false,
  });
  
  @override
  String toString() {
    return '$name=$value';
  }
}

// Method to convert a WebCookie to a Map (used by cookie_jar)
Map<String, String> cookieToMap(WebCookie cookie) {
  return {
    'name': cookie.name,
    'value': cookie.value,
    'domain': cookie.domain ?? '',
    'path': cookie.path ?? '/',
  };
}