import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../../domain/cycle_resolver.dart';
import '../../domain/money_math.dart';

/// Shared small helpers for screens.

class AppFormat {
  static String date(BuildContext context, DateTime value) =>
      normalizeToAsciiDigits(
        DateFormat(
          'd MMM',
          AppLocalizations.of(context)!.localeName,
        ).format(value),
      );

  static String dateTime(BuildContext context, DateTime value) =>
      normalizeToAsciiDigits(
        DateFormat(
          'd MMM yyyy, HH:mm',
          AppLocalizations.of(context)!.localeName,
        ).format(value),
      );

  static String time(BuildContext context, TimeOfDay value) =>
      normalizeToAsciiDigits(
        MaterialLocalizations.of(context).formatTimeOfDay(value),
      );
}

String formatDateIso(BuildContext context, CalendarDate date) =>
    AppFormat.date(context, date.toLocalDateTime());

String formatDateFull(BuildContext context, int epochMs) =>
    AppFormat.dateTime(context, DateTime.fromMillisecondsSinceEpoch(epochMs));

extension AsciiDigitsFormatting on String {
  String get asciiDigits => normalizeToAsciiDigits(this);
}

/// Local calendar day key for grouping.
String dayKeyOf(int epochMs) {
  final local = DateTime.fromMillisecondsSinceEpoch(epochMs);
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

/// Local midnight epoch ms for a DateTime's day.
int localDayStartMs(DateTime local) =>
    DateTime(local.year, local.month, local.day).millisecondsSinceEpoch;

int localDayEndMs(DateTime local) => DateTime(
  local.year,
  local.month,
  local.day,
  23,
  59,
  59,
  999,
).millisecondsSinceEpoch;

/// Monday-based week start.
DateTime weekStartOf(DateTime now) {
  final daysFromMonday = (now.weekday - 1) % 7;
  return DateTime(now.year, now.month, now.day - daysFromMonday);
}
