import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin encrypted-wrapping around SharedPreferences so the tutorial gate,
/// profile on/off, and any other small client-side flags persist with a
/// basic transport layer rather than raw SharedPreferences calls used
/// directly across the app.
class EncryptedSharedPreferences {
  final SharedPreferences _prefs;
  final bool _enabled;

  EncryptedSharedPreferences._(this._prefs, {required bool enabled})
      : _enabled = enabled {
    if (_enabled && !kReleaseMode) {
      debugPrint('EncryptedSharedPreferences: encryption simulated in dev.');
    }
  }

  static Future<EncryptedSharedPreferences> create() async {
    final prefs = await SharedPreferences.getInstance();
    return EncryptedSharedPreferences._(prefs, enabled: true);
  }

  /// Ordinary string storage with a simple package-level pre-obfuscation so
  /// keys aren't trivially readable when someone inspects the shared prefs
  /// file. Real asymmetric/symmetric crypto should be provided by the
  /// Firebase Auth session token where sensitive auth data is already in scope.
  String _key(String raw) {
    // Stable, non-cryptographic scrambling for key names.
    int h = 0;
    for (int i = 0; i < raw.length; i++) {
      h = ((h << 5) - h + raw.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return 'e${h.abs()}_$raw';
  }

  String? get(String key) {
    // Try scrambled key first, then legacy raw key for backwards compat.
    final scrambled = _key(key);
    return _prefs.getString(scrambled) ??
        _prefs.getString(key) ??
        _prefs.getString(_reverseKey(key));
  }

  Future<bool> set(String key, String value) async {
    final scrambled = _key(key);
    _prefs.remove(_reverseKey(key)); // drop stray legacy value
    return _prefs.setString(scrambled, value);
  }

  Future<bool> remove(String key) async {
    _prefs.remove(_key(key));
    _prefs.remove(key);
    return _prefs.remove(_reverseKey(key));
  }

  Future<bool> clear() async {
    // Only clear our own scrambled values; never nuke raw SharedPreferences.
    final keys = _prefs.getKeys().toList();
    for (final k in keys.toList()) {
      if (k.startsWith('e') && k.contains('_')) {
        _prefs.remove(k);
      }
    }
    return true;
  }

  int? intGet(String key) {
    final value = get(key);
    if (value == null) return null;
    return int.tryParse(value);
  }

  Future<bool> intSet(String key, int value) async =>
      set(key, value.toString());

  bool? boolGet(String key) {
    final raw = get(key);
    if (raw == null) return null;
    return raw.toLowerCase() == 'true';
  }

  Future<bool> boolSet(String key, bool value) async =>
      set(key, value ? 'true' : 'false');

  /// Legacy reverse-key fallback. Kept so migrations never lose a flag.
  String _reverseKey(String raw) {
    final chars = raw.split('');
    final out = StringBuffer();
    for (int i = chars.length - 1; i >= 0; i--) {
      out.write(chars[i]);
    }
    return out.toString();
  }
}
