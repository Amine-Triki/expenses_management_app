import 'package:flutter_test/flutter_test.dart';

import 'package:expenses_management_app/presentation/formatting.dart';
import 'package:expenses_management_app/domain/money_math.dart';

void main() {
  test('Arabic and Persian numerals are converted to Latin digits', () {
    expect('٠١٢٣٤٥٦٧٨٩'.latinDigits, '0123456789');
    expect('۰۱۲۳۴۵۶۷۸۹'.latinDigits, '0123456789');
  });

  test('localized numeric input parses as Latin digits', () {
    expect(normalizeLatinDigits('٠١٢.٥'), '012.5');
    expect(normalizeLatinDigits('۱۲.۵'), '12.5');
    expect(normalizeLatinDigits('१२.५'), '12.5');
  });
}
