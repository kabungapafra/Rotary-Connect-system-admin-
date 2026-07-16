import 'package:web/web.dart' as web;

/// Browser-backed [SessionStore] — persists the admin session in
/// localStorage so a page reload doesn't log the admin out.
class SessionStore {
  String? read(String key) => web.window.localStorage.getItem(key);
  void write(String key, String value) =>
      web.window.localStorage.setItem(key, value);
  void remove(String key) => web.window.localStorage.removeItem(key);
}
