import 'package:flutter_test/flutter_test.dart';

import 'package:expenses_management_app/data/id_generator.dart';

void main() {
  test('ids are UUID v7: version nibble, embedded timestamp, uniqueness', () {
    final before = DateTime.now().millisecondsSinceEpoch;
    final ids = [for (var i = 0; i < 1000; i++) IdGenerator.nextId()];
    final after = DateTime.now().millisecondsSinceEpoch;

    expect(ids.toSet().length, 1000, reason: 'ids must be unique');

    for (final id in ids.take(20)) {
      expect(id.length, 36);
      expect(id[14], '7', reason: 'version nibble must be 7');
      // First 48 bits (12 hex chars across the first two groups) = unix ms.
      final hex =
          id.substring(0, 8) + id.substring(9, 13);
      final ms = int.parse(hex, radix: 16);
      expect(ms, greaterThanOrEqualTo(before - 1000));
      expect(ms, lessThanOrEqualTo(after + 1000));
    }
  });
}
