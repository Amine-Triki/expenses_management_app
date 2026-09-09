/// Currency metadata per ISO 4217. Money is stored as integer minor units;
/// the number of minor-unit digits is a property of the currency, never a
/// global assumption (TND uses millimes = 3 digits, JPY uses 0).
class CurrencyInfo {
  const CurrencyInfo({required this.code, required this.digits, this.symbol});

  final String code;
  final int digits;
  final String? symbol;

  static const Map<String, int> _digitsByCode = {
    'USD': 2,
    'EUR': 2,
    'GBP': 2,
    'CHF': 2,
    'CAD': 2,
    'AUD': 2,
    'JPY': 0,
    'KRW': 0,
    'TND': 3,
    'KWD': 3,
    'BHD': 3,
    'JOD': 3,
    'LYD': 3,
    'IQD': 3,
    'OMR': 3,
    'DZD': 2,
    'MAD': 2,
    'EGP': 2,
    'SAR': 2,
    'AED': 2,
    'QAR': 2,
    'TRY': 2,
  };

  static CurrencyInfo resolve(String code) =>
      CurrencyInfo(code: code, digits: _digitsByCode[code] ?? 2);

  /// Currencies offered in the first-launch picker.
  static const List<String> pickerCodes = [
    'USD', 'EUR', 'GBP', 'TND', 'DZD', 'MAD', 'EGP', 'SAR', 'AED', 'QAR',
    'KWD', 'JOD', 'LYD', 'TRY', 'CHF', 'CAD', 'AUD', 'JPY',
  ];
}
