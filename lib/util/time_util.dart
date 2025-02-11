/// Returns the current Unix timestamp in seconds
int currentUnixTimestamp() {
  return DateTime.now().millisecondsSinceEpoch ~/ 1000;
}
