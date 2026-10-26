import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal key/value abstraction so storage can be swapped (e.g. tests).
abstract interface class SecureVault {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Encrypted-at-rest storage:
/// - Android: AES-GCM with keys wrapped by the Android Keystore (RSA-OAEP).
/// - iOS: Keychain, only accessible while the device is unlocked and never
///   migrated to other devices/backups (`*_this_device`).
class PlatformSecureVault implements SecureVault {
  PlatformSecureVault()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.unlocked_this_device,
          ),
        );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Volatile in-memory vault (widget tests / fallback when keystore fails).
class MemoryVault implements SecureVault {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);
}
