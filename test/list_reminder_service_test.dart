import 'package:flutter_test/flutter_test.dart';

import 'package:expenses_management_app/application/list_reminder_service.dart';

void main() {
  test('floating reminder round-trips its local components', () {
    final value = DateTime(2026, 11, 11, 9, 30);

    final restored = fromFloating(toFloating(value));

    expect(restored.year, value.year);
    expect(restored.month, value.month);
    expect(restored.day, value.day);
    expect(restored.hour, value.hour);
    expect(restored.minute, value.minute);
    expect(restored.isUtc, isTrue);
  });
}
