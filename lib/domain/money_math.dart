/// The single source of all money arithmetic. Works exclusively on integer
/// minor units — floating point is never authoritative for money.
///
/// Parsing/rounding contract: rounding is allowed exactly once, at save time,
/// always half-up. Display formatting belongs to the presentation layer.
library;

/// Parses a user-entered decimal string (e.g. "12", "12.5", "12,50") into
/// minor units for a currency with [digits] decimal places.
/// Returns null when the input is not a valid non-negative amount.
int? parseMinorUnits(String input, int digits) {
  final text = input.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (text.isEmpty) return null;
  final parts = text.split('.');
  final hasSeparator = parts.length == 2;
  if (parts.length > 2) return null;
  final intPart = parts[0];
  final fracPart = hasSeparator ? parts[1] : '';
  if (intPart.isEmpty && fracPart.isEmpty) return null;
  if (intPart.isNotEmpty && intPart.length > 15) return null;
  for (final ch in text.codeUnits) {
    if (!(ch >= 0x30 && ch <= 0x39) && ch != 0x2E) return null;
  }

  final digitsAllowed = digits;
  // Round half-up when the user typed more decimals than the currency has.
  var normalizedFrac = fracPart;
  var roundUp = false;
  if (fracPart.length > digitsAllowed) {
    normalizedFrac = fracPart.substring(0, digitsAllowed);
    final firstDropped = fracPart.codeUnitAt(digitsAllowed);
    if (firstDropped >= 0x35) roundUp = true; // '5'..'9'
  } else {
    normalizedFrac = fracPart.padRight(digitsAllowed, '0');
  }

  final intUnits = intPart.isEmpty ? 0 : int.tryParse(intPart);
  final fracUnits = digitsAllowed == 0 ? 0 : int.tryParse(normalizedFrac);
  if (intUnits == null || fracUnits == null) return null;

  final factor = _pow10(digitsAllowed);
  var result = intUnits * factor + (digitsAllowed == 0 ? 0 : fracUnits);
  if (roundUp) result += 1;
  if (result < 0) return null;
  return result;
}

/// Formats minor units back to a decimal string with [digits] places
/// (presentation helper kept here so the representation has one definition).
String minorUnitsToString(int minor, int digits) {
  if (digits <= 0) return minor.toString();
  final factor = _pow10(digits);
  final sign = minor < 0 ? '-' : '';
  final abs = minor.abs();
  final unitPart = abs ~/ factor;
  final fracPart = (abs % factor).toString().padLeft(digits, '0');
  return '$sign$unitPart.$fracPart';
}

/// Quantity arithmetic on scaled integers (×1000, three fixed decimals).
/// Quantity precision is independent of currency precision.
int quantityToScaled(String input) {
  final parsed = parseMinorUnits(input, 3);
  return parsed ?? -1;
}

String scaledQuantityToString(int scaled) =>
    minorUnitsToString(scaled, 3);

/// Half-up rounding of a scaled ×1000 value to a target number of decimals.
int roundScaledToDigits(int scaled, int digits) =>
    roundToDigits(scaled, 3 - digits);

/// Rounds `value / 10^places` half-up back into an integer.
int roundToDigits(int value, int places) {
  if (places <= 0) return value;
  final factor = _pow10(places);
  final negative = value < 0;
  final abs = value.abs();
  var result = abs ~/ factor;
  if (abs % factor * 2 >= factor) result += 1;
  return negative ? -result : result;
}

/// Multiplies a ×1000-scaled quantity by a minor-unit price; result is minor
/// units rounded half-up exactly once. The single definition used by both
/// expense amounts and shopping-list estimates.
int scaledQuantityTimesPrice(int scaledQuantity, int priceMinor) {
  final product = scaledQuantity * priceMinor;
  var v = product ~/ 1000;
  if ((product % 1000).abs() * 2 >= 1000) v += product < 0 ? -1 : 1;
  return v;
}

int _pow10(int n) {
  var r = 1;
  for (var i = 0; i < n; i++) {
    r *= 10;
  }
  return r;
}
