import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// PBKDF2-HMAC-SHA256 PIN hashing with a per-install random salt.
/// The PIN itself is never stored.
abstract final class PinHasher {
  static const iterations = 60000;
  static const keyLength = 32;

  static Uint8List randomSalt([int length = 16]) {
    final rnd = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => rnd.nextInt(256)));
  }

  /// Runs the KDF on a background isolate so the UI stays at 60/120 fps.
  static Future<Uint8List> derive(String pin, Uint8List salt, int iterations) =>
      compute(_deriveEntry, _KdfArgs(pin, salt, iterations));

  static Uint8List deriveSync(String pin, Uint8List salt, int iterations) =>
      _pbkdf2(utf8.encode(pin), salt, iterations, keyLength);

  /// Constant-time comparison to avoid timing side channels.
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// Rejects PINs that are trivially guessable.
  static String? weaknessOf(String pin) {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) return 'PIN harus 6 digit angka.';
    if (RegExp(r'^(\d)\1{5}$').hasMatch(pin)) {
      return 'PIN terlalu mudah ditebak (angka sama).';
    }
    const seqUp = '0123456789012';
    const seqDown = '9876543210987';
    if (seqUp.contains(pin) || seqDown.contains(pin)) {
      return 'PIN terlalu mudah ditebak (berurutan).';
    }
    const common = {'121212', '112233', '123123', '696969', '159753', '147258'};
    if (common.contains(pin)) return 'PIN terlalu umum, pilih kombinasi lain.';
    return null;
  }
}

class _KdfArgs {
  const _KdfArgs(this.pin, this.salt, this.iterations);
  final String pin;
  final Uint8List salt;
  final int iterations;
}

Uint8List _deriveEntry(_KdfArgs a) =>
    _pbkdf2(utf8.encode(a.pin), a.salt, a.iterations, PinHasher.keyLength);

Uint8List _pbkdf2(List<int> password, List<int> salt, int iterations, int dkLen) {
  final hmac = Hmac(sha256, password);
  const hLen = 32;
  final blocks = (dkLen / hLen).ceil();
  final out = BytesBuilder(copy: false);
  for (var block = 1; block <= blocks; block++) {
    final blockIndex = Uint8List(4)
      ..buffer.asByteData().setUint32(0, block, Endian.big);
    var u = hmac.convert([...salt, ...blockIndex]).bytes;
    final t = Uint8List.fromList(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    out.add(t);
  }
  return Uint8List.sublistView(out.toBytes(), 0, dkLen);
}
