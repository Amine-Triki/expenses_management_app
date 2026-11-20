import 'package:intl/intl.dart';

import '../domain/currency.dart';
import '../domain/money_math.dart';

/// Presentation-only currency formatting. The selected currency changes
/// decimal-place formatting but never converts or changes the authoritative
/// integer minor-unit amount.
class MoneyFormatter {
  MoneyFormatter(this.currencyCode) : info = CurrencyInfo.resolve(currencyCode);

  final String currencyCode;
  final CurrencyInfo info;

  String format(int minorUnits, {bool withCode = true}) {
    final value = minorUnits / _pow10(info.digits);
    final nf = NumberFormat.currency(
      locale: 'en',
      symbol: '',
      decimalDigits: info.digits,
    );
    final text = nf.format(value).trim();
    return withCode ? '$text $currencyCode' : text;
  }

  /// Compact display for indicators (one decimal allowed by the contract).
  String formatDaily(double? dailyMinor) {
    if (dailyMinor == null) return '—';
    final nf = NumberFormat('#,##0.#', 'en');
    return '${nf.format(dailyMinor / _pow10(info.digits))} $currencyCode';
  }

  /// Parses user input back into minor units (single half-up round at save).
  int? parse(String input) => parseMinorUnits(input, info.digits);
}

int _pow10(int n) {
  var r = 1;
  for (var i = 0; i < n; i++) {
    r *= 10;
  }
  return r;
}
