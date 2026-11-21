import '../domain/currency.dart';
import '../domain/money_math.dart';

/// Presentation-only currency formatting. The selected currency changes
/// decimal-place formatting but never converts or changes the authoritative
/// integer minor-unit amount.
class MoneyFormatter {
  MoneyFormatter(this.currencyCode) : info = CurrencyInfo.resolve(currencyCode);

  final String currencyCode;
  final CurrencyInfo info;

  String format(int minorUnits, {bool withCode = true, bool forInput = false}) {
    final text = minorUnitsToString(minorUnits, info.digits);
    final parts = text.split('.');
    final sign = parts.first.startsWith('-') ? '-' : '';
    final integer = sign.isEmpty ? parts.first : parts.first.substring(1);
    final grouped = forInput ? integer : _groupInteger(integer);
    final display = '$sign$grouped${parts.length == 1 ? '' : '.${parts[1]}'}';
    return withCode ? '$display $currencyCode' : display;
  }

  /// Compact display for indicators (one decimal allowed by the contract).
  String formatDaily(double? dailyMinor) {
    if (dailyMinor == null) return '—';
    final value = dailyMinor / _pow10(info.digits);
    final raw = value.toStringAsFixed(1);
    final parts = raw.split('.');
    final integer = _groupInteger(parts.first);
    final decimal = parts.length == 1 || parts[1] == '0' ? '' : '.${parts[1]}';
    return '$integer$decimal $currencyCode';
  }

  /// Parses user input back into minor units (single half-up round at save).
  int? parse(String input) => parseMinorUnits(input, info.digits);
}

int _pow10(int n) {
  var result = 1;
  for (var i = 0; i < n; i++) {
    result *= 10;
  }
  return result;
}

String _groupInteger(String value) {
  final sign = value.startsWith('-') ? '-' : '';
  final digits = sign.isEmpty ? value : value.substring(1);
  final first = digits.length % 3 == 0 ? 3 : digits.length % 3;
  final buffer = StringBuffer(sign);
  if (digits.isNotEmpty) {
    buffer.write(digits.substring(0, first));
    for (var i = first; i < digits.length; i += 3) {
      buffer.write('\u00A0${digits.substring(i, i + 3)}');
    }
  }
  return buffer.toString();
}
