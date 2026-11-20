import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinSecurity {
  PinSecurity._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );
  static const _saltKey = 'app_lock_pin_salt_v1';
  static const _hashKey = 'app_lock_pin_hash_v1';
  static const _attemptsKey = 'app_lock_failed_attempts_v1';
  static const _lockedUntilKey = 'app_lock_locked_until_v1';
  static const _iterations = 100000;

  static Future<String> create(String pin) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final saltText = base64Url.encode(salt);
    final hash = pbkdf2(pin, salt);
    await _storage.write(key: _saltKey, value: saltText);
    await _storage.write(key: _hashKey, value: hash);
    await resetFailures();
    return hash;
  }

  static Future<bool> verify(String pin) async {
    final saltText = await _storage.read(key: _saltKey);
    final expected = await _storage.read(key: _hashKey);
    if (saltText == null || expected == null) return false;
    final salt = base64Url.decode(saltText);
    return pbkdf2(pin, salt) == expected;
  }

  static Future<bool> verifyLegacy(String pin, String? legacyHash) async {
    if (legacyHash == null) return false;
    final actual = sha256.convert(utf8.encode(pin)).toString();
    if (actual != legacyHash) return false;
    await create(pin);
    return true;
  }

  static Future<bool> hasSecureHash() async =>
      await _storage.read(key: _hashKey) != null;

  static Future<int> failures() async =>
      int.tryParse(await _storage.read(key: _attemptsKey) ?? '') ?? 0;

  static Future<int> lockedUntilMs() async =>
      int.tryParse(await _storage.read(key: _lockedUntilKey) ?? '') ?? 0;

  static Future<void> resetFailures() async {
    await _storage.write(key: _attemptsKey, value: '0');
    await _storage.write(key: _lockedUntilKey, value: '0');
  }

  static Future<void> recordFailure() async {
    final attempts = await failures() + 1;
    var lockedUntil = 0;
    if (attempts >= 5) {
      final blocks = attempts - 5;
      final seconds = 30 * (1 << blocks.clamp(0, 7));
      lockedUntil = DateTime.now()
          .add(Duration(seconds: seconds))
          .millisecondsSinceEpoch;
    }
    await _storage.write(key: _attemptsKey, value: '$attempts');
    await _storage.write(key: _lockedUntilKey, value: '$lockedUntil');
  }

  static Future<void> clear() async {
    await _storage.delete(key: _saltKey);
    await _storage.delete(key: _hashKey);
    await resetFailures();
  }

  static String pbkdf2(String pin, List<int> salt) {
    var output = <int>[];
    var block = 1;
    while (output.length < 32) {
      var u = _hmacSha256(
        key: utf8.encode(pin),
        data: [...salt, ..._int32be(block)],
      );
      var result = List<int>.from(u);
      for (var i = 1; i < _iterations; i++) {
        u = _hmacSha256(key: utf8.encode(pin), data: u);
        for (var j = 0; j < result.length; j++) {
          result[j] ^= u[j];
        }
      }
      output.addAll(result);
      block++;
    }
    return base64Url.encode(output.sublist(0, 32));
  }

  static List<int> _hmacSha256({
    required List<int> key,
    required List<int> data,
  }) {
    final digest = Hmac(sha256, key).convert(data).bytes;
    return digest;
  }

  static List<int> _int32be(int value) => [
    (value >> 24) & 0xff,
    (value >> 16) & 0xff,
    (value >> 8) & 0xff,
    value & 0xff,
  ];
}
