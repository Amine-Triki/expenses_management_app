import 'package:flutter/services.dart';

/// Decimal input: a typed comma becomes a dot IN THE SAME keystroke, and
/// invalid shapes (a second dot, leading separators) are rejected as a whole
/// — never partially, so digits can never "swallow" or concatenate.
///
/// Single formatter, not a composition: filtering must run on the
/// NORMALIZED text, otherwise a comma is dropped by the allow-filter before
/// the replacement ever sees it (which scrambled subsequent digits).
class DotDecimalFormatter extends TextInputFormatter {
  const DotDecimalFormatter();

  static final RegExp _pattern = RegExp(r'^[0-9]*\.?[0-9]*$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(',', '.');
    if (!_pattern.hasMatch(text)) {
      return oldValue; // reject the whole keystroke — no partial damage
    }
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: newValue.selection.baseOffset.clamp(0, text.length),
      ),
    );
  }
}
