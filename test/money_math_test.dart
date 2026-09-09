import 'package:flutter_test/flutter_test.dart';
import 'package:expenses_management_app/domain/money_math.dart';

void main() {
  group('parseMinorUnits', () {
    test('two-digit currency basics', () {
      expect(parseMinorUnits('12', 2), 1200);
      expect(parseMinorUnits('12.5', 2), 1250);
      expect(parseMinorUnits('12.50', 2), 1250);
      expect(parseMinorUnits('0.01', 2), 1);
      expect(parseMinorUnits('0.99', 2), 99);
      expect(parseMinorUnits('1,234.56', 2), isNull); // no thousands support
      expect(parseMinorUnits('12,5', 2), 1250); // comma as decimal separator
    });

    test('TND millimes (3 digits)', () {
      expect(parseMinorUnits('12.5', 3), 12500);
      expect(parseMinorUnits('12.500', 3), 12500);
      expect(parseMinorUnits('0.001', 3), 1);
    });

    test('zero-decimal currency (JPY)', () {
      expect(parseMinorUnits('1000', 0), 1000);
      expect(parseMinorUnits('1000.5', 0), 1001); // half-up rounds once
      expect(parseMinorUnits('1000.4', 0), 1000);
    });

    test('half-up rounding at save time', () {
      expect(parseMinorUnits('1.999', 2), 200); // 199.9 -> 200
      expect(parseMinorUnits('1.995', 2), 200);
      expect(parseMinorUnits('1.994', 2), 199);
      expect(parseMinorUnits('9.999', 2), 1000);
    });

    test('invalid inputs return null', () {
      expect(parseMinorUnits('', 2), isNull);
      expect(parseMinorUnits('   ', 2), isNull);
      expect(parseMinorUnits('abc', 2), isNull);
      expect(parseMinorUnits('1.2.3', 2), isNull);
      expect(parseMinorUnits('-5', 2), isNull);
      expect(parseMinorUnits('1e5', 2), isNull);
      expect(parseMinorUnits('.', 2), isNull);
    });

    test('round-trip with minorUnitsToString', () {
      for (final digits in [0, 2, 3]) {
        final v = parseMinorUnits('123.456', digits)!;
        expect(parseMinorUnits(minorUnitsToString(v, digits), digits), v);
      }
      expect(minorUnitsToString(1250, 2), '12.50');
      expect(minorUnitsToString(-1250, 2), '-12.50');
      expect(minorUnitsToString(12500, 3), '12.500');
      expect(minorUnitsToString(1000, 0), '1000');
    });
  });

  group('quantity (scaled ×1000)', () {
    test('parses fractions up to 3 decimals', () {
      expect(quantityToScaled('1'), 1000);
      expect(quantityToScaled('1.5'), 1500);
      expect(quantityToScaled('0.25'), 250);
      expect(quantityToScaled('2.125'), 2125);
      expect(quantityToScaled('2.1259'), 2126); // half-up at 3rd decimal
    });

    test('invalid quantity returns sentinel', () {
      expect(quantityToScaled(''), -1);
      expect(quantityToScaled('abc'), -1);
      expect(quantityToScaled('-1'), -1);
    });

    test('round-trips through string', () {
      expect(scaledQuantityToString(1500), '1.500');
      expect(scaledQuantityToString(1000), '1.000');
    });
  });
}
