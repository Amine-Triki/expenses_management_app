import 'dart:ui' show Locale;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../domain/models.dart';
import '../l10n/app_localizations.dart';

int toFloating(DateTime value) => DateTime.utc(
  value.year,
  value.month,
  value.day,
  value.hour,
  value.minute,
).millisecondsSinceEpoch;

DateTime fromFloating(int value) {
  return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
}

class ListReminderService {
  ListReminderService._();

  static final instance = ListReminderService._();
  final _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool get isInitialized => _initialized;
  String? _timezoneIdentifier;

  Future<void> initialize({String languageCode = 'en'}) async {
    tz.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));
    _timezoneIdentifier = timezone.identifier;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _notifications.initialize(settings: settings);
    await _createChannel(languageCode);
    _initialized = true;
  }

  Future<void> updateLanguage(String languageCode) async {
    if (!_initialized) return;
    await _createChannel(languageCode);
  }

  Future<bool> refreshTimezone() async {
    final timezone = await FlutterTimezone.getLocalTimezone();
    if (timezone.identifier == _timezoneIdentifier) return false;
    tz.setLocalLocation(tz.getLocation(timezone.identifier));
    _timezoneIdentifier = timezone.identifier;
    return true;
  }

  Future<void> _createChannel(String languageCode) async {
    final strings = _strings(languageCode);
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            'shopping_list_reminders',
            strings.channelName,
            description: strings.channelDescription,
            importance: Importance.defaultImportance,
          ),
        );
  }

  Future<bool> requestPermission() async {
    final android = await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    return (android ?? true);
  }

  Future<void> schedule(ShoppingList list, {String languageCode = 'en'}) async {
    if (!_initialized) {
      throw StateError('ListReminderService.initialize() must complete first.');
    }
    final atMs = list.reminderLocalMs;
    final recurrence = list.reminderRecurrence;
    if (atMs == null || recurrence == null) {
      await cancel(list.id);
      return;
    }

    await _notifications.cancel(id: _notificationId(list.id));
    final floating = fromFloating(atMs);
    final now = DateTime.now();
    if (recurrence == ListReminderRecurrence.once &&
        floating.isBefore(
          DateTime(now.year, now.month, now.day, now.hour, now.minute),
        )) {
      return;
    }

    final day = recurrence == ListReminderRecurrence.monthly
        ? floating.day.clamp(1, 28)
        : floating.day;
    final date = tz.TZDateTime(
      tz.local,
      floating.year,
      floating.month,
      day,
      floating.hour,
      floating.minute,
    );
    final components = switch (recurrence) {
      ListReminderRecurrence.once => null,
      ListReminderRecurrence.weekly => DateTimeComponents.dayOfWeekAndTime,
      ListReminderRecurrence.monthly => DateTimeComponents.dayOfMonthAndTime,
    };
    final strings = _strings(languageCode);
    await _notifications.zonedSchedule(
      id: _notificationId(list.id),
      title: strings.title,
      body: strings.body,
      scheduledDate: tz.TZDateTime.from(date, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'shopping_list_reminders',
          strings.channelName,
          channelDescription: strings.channelDescription,
          importance: Importance.defaultImportance,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: components,
      payload: 'list:${list.id}',
    );
  }

  Future<void> rescheduleAll(
    List<ShoppingList> lists, {
    String languageCode = 'en',
  }) async {
    if (!_initialized) {
      throw StateError('ListReminderService.initialize() must complete first.');
    }
    final owned = (await _notifications.pendingNotificationRequests()).where(
      (request) => request.payload?.startsWith('list:') ?? false,
    );
    final validIds = lists
        .where((list) => list.reminderLocalMs != null)
        .map((list) => _notificationId(list.id))
        .toSet();
    for (final request in owned) {
      if (!validIds.contains(request.id)) {
        await _notifications.cancel(id: request.id);
      }
    }
    for (final list in lists) {
      await schedule(list, languageCode: languageCode);
    }
  }

  Future<void> cancel(String listId) =>
      _notifications.cancel(id: _notificationId(listId));

  int _notificationId(String listId) {
    var hash = 0;
    for (final codeUnit in listId.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash;
  }

  ({String title, String body, String channelName, String channelDescription})
  _strings(String languageCode) {
    final l10n = lookupAppLocalizations(Locale(languageCode));
    return (
      title: l10n.notificationTitle,
      body: l10n.notificationBody,
      channelName: l10n.notificationChannelName,
      channelDescription: l10n.notificationChannelDescription,
    );
  }
}
