import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class PinSecurityStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class InMemoryPinSecurityStorage implements PinSecurityStorage {
  final Map<String, String> values = {};
  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

class _FlutterPinSecurityStorage implements PinSecurityStorage {
  const _FlutterPinSecurityStorage();
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

class PinSecurity {
  PinSecurity._();

  static PinSecurityStorage _storage = const _FlutterPinSecurityStorage();
  static const _saltKey = 'app_lock_pin_salt_v1';
  static const _hashKey = 'app_lock_pin_hash_v1';
  static const _attemptsKey = 'app_lock_failed_attempts_v1';
  static const _lockedUntilKey = 'app_lock_locked_until_v1';
  static const _iterations = 100000;

  static void configureStorageForTest(PinSecurityStorage storage) {
    _storage = storage;
  }

  static void useFlutterSecureStorage() {
    _storage = const _FlutterPinSecurityStorage();
  }

  static Future<String> create(String pin) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final saltText = base64Url.encode(salt);
    final hash = await pbkdf2(pin, salt);
    await _storage.write(_saltKey, saltText);
    await _storage.write(_hashKey, hash);
    await resetFailures();
    return hash;
  }

  static Future<bool> verify(String pin) async {
    final saltText = await _storage.read(_saltKey);
    final expected = await _storage.read(_hashKey);
    if (saltText == null || expected == null) return false;
    final salt = base64Url.decode(saltText);
    final actual = await pbkdf2(pin, salt);
    return _constantTimeHex(actual.codeUnits, expected.codeUnits);
  }

  static Future<bool> verifyLegacy(String pin, String? legacyHash) async {
    if (legacyHash == null) return false;
    final actual = sha256.convert(utf8.encode(pin)).toString();
    if (!_constantTimeHex(actual.codeUnits, legacyHash.codeUnits)) return false;
    await create(pin);
    return true;
  }

  static Future<bool> hasSecureHash() async =>
      await _storage.read(_hashKey) != null;

  static Future<int> failures() async =>
      int.tryParse(await _storage.read(_attemptsKey) ?? '') ?? 0;

  static Future<int> lockedUntilMs() async =>
      int.tryParse(await _storage.read(_lockedUntilKey) ?? '') ?? 0;

  static Future<void> resetFailures() async {
    await _storage.write(_attemptsKey, '0');
    await _storage.write(_lockedUntilKey, '0');
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
    await _storage.write(_attemptsKey, '$attempts');
    await _storage.write(_lockedUntilKey, '$lockedUntil');
  }

  static Future<void> clear() async {
    await _storage.delete(_saltKey);
    await _storage.delete(_hashKey);
    await resetFailures();
  }

  static Future<String> pbkdf2(String pin, List<int> salt) =>
      Isolate.run(() => _pbkdf2Sync(pin, salt, _iterations));

  static bool _constantTimeHex(List<int> actual, List<int> expected) {
    if (actual.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual[i] ^ expected[i];
    }
    return diff == 0;
  }
}

String _pbkdf2Sync(String pin, List<int> salt, int iterations) {
  var output = <int>[];
  var block = 1;
  while (output.length < 32) {
    final hmac = Hmac(sha256, utf8.encode(pin));
    var u = hmac.convert([...salt, ..._int32be(block)]).bytes;
    var result = List<int>.from(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    output.addAll(result);
    block++;
  }
  return base64Url.encode(output.sublist(0, 32));
}

List<int> _int32be(int value) => [
  (value >> 24) & 0xff,
  (value >> 16) & 0xff,
  (value >> 8) & 0xff,
  value & 0xff,
];

Future<bool> reconcileAppLock({
  required bool lockEnabled,
  required String? legacyHash,
  required Future<void> Function() disable,
}) async {
  if (!lockEnabled) return false;
  if (await PinSecurity.hasSecureHash()) return false;
  final legacy = legacyHash?.toLowerCase();
  final isLegacySha256 =
      legacy != null && RegExp(r'^[0-9a-f]{64}$').hasMatch(legacy);
  if (isLegacySha256) return false;
  await disable();
  return true;
}
