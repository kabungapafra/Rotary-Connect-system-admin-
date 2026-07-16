/// Non-web fallback for [SessionStore] — keeps values in memory only, so
/// widget tests (which run on the Dart VM) can construct DashboardState
/// without touching browser APIs.
class SessionStore {
  final Map<String, String> _values = {};

  String? read(String key) => _values[key];
  void write(String key, String value) => _values[key] = value;
  void remove(String key) => _values.remove(key);
}
