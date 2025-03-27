/// Class holding constants for relay types.
class RelayType {
  /// Normal relay.
  static const int normal = 1;

  /// Temporary relay.
  static const int temp = 2;

  /// Local relay.
  /// This relay type is used for local storage.
  static const int local = 3;

  /// Cache relay.
  static const int cache = 4;

  /// Cache and local relays.
  static const List<int> cacheAndLocal = [local, cache];
  
  /// Temporary and local relays.
  static const List<int> tempAndLocal = [temp, local];

  /// Only normal relays.
  static const List<int> onlyNormal = [normal];

  /// Only temporary relays.
  static const List<int> onlyTemp = [temp];

  /// All relays.
  static const List<int> all = [normal, temp, local, cache];
}
