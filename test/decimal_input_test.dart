import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expenses_management_app/presentation/decimal_input.dart';

TextEditingValue edit(String old, String newText) {
  const f = DotDecimalFormatter();
  return f.formatEditUpdate(
    const TextEditingValue(text: ''),
    TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    ),
  );
}

void main() {
  test('comma becomes a dot in the same keystroke', () {
    final r = edit('', '0,75');
    expect(r.text, '0.75');
    expect(r.selection.baseOffset, 4);
  });

  test('a leading comma is NOT swallowed (the digit-scramble bug)', () {
    // Sequence a user actually types: '0', ',', '7', '5'.
    var v = edit('', '0');
    v = edit(v.text, '0,');
    expect(v.text, '0.', reason: 'comma keystroke must survive as a dot');
    v = edit(v.text, '0.7');
    v = edit(v.text, '0.75');
    expect(v.text, '0.75');
  });

  test('a second dot rejects the keystroke instead of scrambling', () {
    final r = edit('', '1.2.3');
    expect(r.text, '');
    expect(r, const TextEditingValue(text: ''));
  });
}
