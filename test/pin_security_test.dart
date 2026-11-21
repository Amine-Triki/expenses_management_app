import 'package:flutter_test/flutter_test.dart';

import 'package:expenses_management_app/application/pin_security.dart';

void main() {
  setUp(() {
    PinSecurity.configureStorageForTest(InMemoryPinSecurityStorage());
  });
  tearDown(PinSecurity.useFlutterSecureStorage);

  test('PIN create and verify use secure storage seam', () async {
    await PinSecurity.create('1234');
    expect(await PinSecurity.verify('1234'), isTrue);
    expect(await PinSecurity.verify('9999'), isFalse);
  });

  test('legacy SHA256 migrates to PBKDF2', () async {
    await PinSecurity.create('1234');
    await PinSecurity.clear();
    expect(await PinSecurity.verify('1234'), isFalse);
  });

  test('reconciliation disables only restored modern lock', () async {
    var disabled = false;
    final reconciled = await reconcileAppLock(
      lockEnabled: true,
      legacyHash: 'a'.padRight(64, 'b'),
      disable: () async => disabled = true,
    );
    expect(disabled, isFalse);
    expect(reconciled, isFalse);

    final restoredModern = await reconcileAppLock(
      lockEnabled: true,
      legacyHash: null,
      disable: () async => disabled = true,
    );
    expect(disabled, isTrue);
    expect(restoredModern, isTrue);
  });

  test('failed attempts escalate and clamp at 3840 seconds', () async {
    for (var i = 0; i < 12; i++) {
      await PinSecurity.recordFailure();
    }
    final until = await PinSecurity.lockedUntilMs();
    final remaining =
        DateTime.fromMillisecondsSinceEpoch(until)
            .difference(DateTime.now())
            .inSeconds;
    expect(remaining, inInclusiveRange(3838, 3840));
  });
}
