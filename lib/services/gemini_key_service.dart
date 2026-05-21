// gemini_key_service.dart
//
// Thin wrapper around FlutterSecureStorage that provides typed read/write/clear
// operations for the user-supplied Gemini API key.
//
// WHY THIS EXISTS:
//   The Gemini API key is sensitive — it authenticates to Google's paid AI
//   quota. Storing it in plain SharedPreferences or Hive would leave it readable
//   by other apps on rooted devices. FlutterSecureStorage uses iOS Keychain and
//   Android EncryptedSharedPreferences, which are the platform-recommended
//   mechanisms for secrets.
//
// CRITICAL INVARIANTS:
//   - The key is ONLY stored in secure storage, never in Hive or plain prefs.
//   - GeminiKeyService must never log or print the key value.
//   - The optional [storage] constructor parameter exists solely for dependency
//     injection in tests — production code always uses the default instance.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Storage key for the user-supplied Gemini API key.
// Stored in platform secure storage (Keychain on iOS, EncryptedSharedPreferences
// on Android) — never in Hive or plain SharedPreferences.
const _kGeminiKeyStorageKey = 'gemini_api_key';

/// Service responsible for persisting and retrieving the Gemini API key from
/// platform-secure storage.
///
/// Inject a custom [FlutterSecureStorage] instance in tests to avoid touching
/// real device storage.
class GeminiKeyService {
  final FlutterSecureStorage _storage;

  GeminiKeyService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// Reads the stored key; returns null if none has been saved yet.
  Future<String?> readKey() async => _storage.read(key: _kGeminiKeyStorageKey);

  /// Persists the key to secure storage.
  ///
  /// Overwrites any previously stored value. The caller is responsible for
  /// validating the key format before calling this method.
  Future<void> saveKey(String key) async =>
      _storage.write(key: _kGeminiKeyStorageKey, value: key);

  /// Deletes the stored key.
  ///
  /// Safe to call even when no key has been stored — [FlutterSecureStorage]
  /// silently no-ops in that case.
  Future<void> clearKey() async => _storage.delete(key: _kGeminiKeyStorageKey);

  /// Returns true if a key is currently stored.
  Future<bool> hasKey() async => (await readKey()) != null;
}
