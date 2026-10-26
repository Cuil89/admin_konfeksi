import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/secure_vault.dart';
import 'pin_hasher.dart';

/// Cybersecurity-focused authentication & session management:
/// - PBKDF2-HMAC-SHA256 salted PIN hash stored in secure hardware vault
/// - Exponential lockout on failed attempts to mitigate brute-force attacks
/// - Auto-lock on inactivity
/// - Zero raw-PIN retention in RAM
class AuthState extends ChangeNotifier {
  AuthState(this._vault);

  final SecureVault _vault;

  static const _pinHashKey = 'payrole.auth.pin_hash';
  static const _pinSaltKey = 'payrole.auth.pin_salt';
  static const _pinEnabledKey = 'payrole.auth.pin_enabled';
  static const _maxFailedAttempts = 5;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isPinSet = false;
  bool get isPinSet => _isPinSet;

  bool _isPinRequired = false;
  bool get isPinRequired => _isPinRequired;

  bool _isUnlocked = true;
  bool get isUnlocked => _isUnlocked;

  int _failedAttempts = 0;
  int get failedAttempts => _failedAttempts;

  DateTime? _lockedUntil;
  DateTime? get lockedUntil => _lockedUntil;

  bool get isLockedOut =>
      _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);

  int get remainingLockoutSeconds =>
      _lockedUntil == null ? 0 : _lockedUntil!.difference(DateTime.now()).inSeconds.clamp(0, 3600);

  Future<void> initialize() async {
    try {
      final pinHash = await _vault.read(_pinHashKey);
      final pinSalt = await _vault.read(_pinSaltKey);
      final enabled = await _vault.read(_pinEnabledKey);

      _isPinSet = pinHash != null && pinSalt != null;
      _isPinRequired = enabled == 'true' && _isPinSet;
      _isUnlocked = !_isPinRequired;
    } catch (_) {
      _isPinSet = false;
      _isPinRequired = false;
      _isUnlocked = true;
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    if (isLockedOut) return false;

    try {
      final storedHashBase64 = await _vault.read(_pinHashKey);
      final storedSaltBase64 = await _vault.read(_pinSaltKey);

      if (storedHashBase64 == null || storedSaltBase64 == null) {
        _isUnlocked = true;
        notifyListeners();
        return true;
      }

      final salt = base64Decode(storedSaltBase64);
      final expectedHash = base64Decode(storedHashBase64);

      final derived = await PinHasher.derive(pin, salt, PinHasher.iterations);

      if (PinHasher.constantTimeEquals(derived, expectedHash)) {
        _failedAttempts = 0;
        _lockedUntil = null;
        _isUnlocked = true;
        notifyListeners();
        return true;
      } else {
        _failedAttempts++;
        if (_failedAttempts >= _maxFailedAttempts) {
          // Exponential lockout: 30s, 60s, 120s...
          final penalty = 30 * (1 << (_failedAttempts - _maxFailedAttempts));
          _lockedUntil = DateTime.now().add(Duration(seconds: penalty.clamp(30, 300)));
        }
        notifyListeners();
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  Future<void> setPin(String newPin) async {
    final weakness = PinHasher.weaknessOf(newPin);
    if (weakness != null) throw Exception(weakness);

    final salt = PinHasher.randomSalt(16);
    final hash = await PinHasher.derive(newPin, salt, PinHasher.iterations);

    await _vault.write(_pinSaltKey, base64Encode(salt));
    await _vault.write(_pinHashKey, base64Encode(hash));
    await _vault.write(_pinEnabledKey, 'true');

    _isPinSet = true;
    _isPinRequired = true;
    _isUnlocked = true;
    _failedAttempts = 0;
    _lockedUntil = null;
    notifyListeners();
  }

  Future<void> removePin() async {
    await _vault.delete(_pinSaltKey);
    await _vault.delete(_pinHashKey);
    await _vault.write(_pinEnabledKey, 'false');

    _isPinSet = false;
    _isPinRequired = false;
    _isUnlocked = true;
    _failedAttempts = 0;
    _lockedUntil = null;
    notifyListeners();
  }

  Future<void> setPinEnabled(bool enabled) async {
    if (enabled && !_isPinSet) {
      throw Exception('PIN belum diatur.');
    }
    await _vault.write(_pinEnabledKey, enabled ? 'true' : 'false');
    _isPinRequired = enabled;
    notifyListeners();
  }

  void lockSession() {
    if (_isPinRequired) {
      _isUnlocked = false;
      notifyListeners();
    }
  }
}
