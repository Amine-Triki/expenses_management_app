import 'package:flutter/services.dart';

/// Live decimal-separator normalization: a typed comma becomes a dot in the
/// field immediately, so users never see a comma that "does nothing".
/// The parser also accepts commas defensively, but the field now always
/// displays the dot the calculation actually uses.
class DotDecimalFormatter extends TextInputFormatter {
  const DotDecimalFormatter();

  static final FilteringTextInputFormatter _allow =
      FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*\.?[0-9]*$'));

  /// [allow] + comma→dot normalization, composed for direct field use.
  static List<TextInputFormatter> get standard => [
        _allow,
        const DotDecimalFormatter(),
      ];

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(',', '.');
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: newValue.selection.baseOffset.clamp(0, text.length),
      ),
    );
  }
}
