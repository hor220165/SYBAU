import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationReminderTime {
  const NotificationReminderTime({required this.hour, required this.minute});

  final int hour;
  final int minute;
}

class NotificationService {
  NotificationService._();

  static const int _dailyReminderNotificationId = 9001;
  static const String _enabledKey = 'notifications.enabled';
  static const String _reminderHourKey = 'notifications.reminder.hour';
  static const String _reminderMinuteKey = 'notifications.reminder.minute';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static Future<void>? _initializeFuture;
  static bool _timeZonesInitialized = false;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    final pending = _initializeFuture;
    if (pending != null) return pending;

    _initializeFuture = _initialize();
    try {
      await _initializeFuture;
    } finally {
      if (!_initialized) _initializeFuture = null;
    }
  }

  static Future<void> _initialize() async {
    _ensureTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );

    _initialized = true;
    _initializeFuture = null;
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<bool> setEnabled(bool enabled) async {
    await initialize();
    final prefs = await SharedPreferences.getInstance();

    if (!enabled) {
      await prefs.setBool(_enabledKey, false);
      await _plugin.cancel(id: _dailyReminderNotificationId);
      return false;
    }

    final granted = await requestPermissions();
    if (!granted) {
      await prefs.setBool(_enabledKey, false);
      await _plugin.cancel(id: _dailyReminderNotificationId);
      return false;
    }

    await prefs.setBool(_enabledKey, enabled);
    await scheduleDailyReminder();
    return true;
  }

  static Future<NotificationReminderTime> reminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationReminderTime(
      hour: prefs.getInt(_reminderHourKey) ?? 20,
      minute: prefs.getInt(_reminderMinuteKey) ?? 0,
    );
  }

  static Future<void> setReminderTime(NotificationReminderTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderHourKey, time.hour);
    await prefs.setInt(_reminderMinuteKey, time.minute);

    if (await isEnabled()) {
      await scheduleDailyReminder(time: time);
    }
  }

  static Future<void> syncScheduledReminder() async {
    if (await isEnabled()) {
      await scheduleDailyReminder();
    }
  }

  static Future<bool> isDailyReminderScheduled() async {
    await initialize();
    if (kIsWeb) return false;

    final pending = await _plugin.pendingNotificationRequests();
    return pending.any((request) => request.id == _dailyReminderNotificationId);
  }

  static Future<bool> requestPermissions() async {
    await initialize();
    if (kIsWeb) return false;

    var granted = true;

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosPlugin != null) {
      granted =
          await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    final macPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (macPlugin != null) {
      granted =
          await macPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      granted = await androidPlugin.requestNotificationsPermission() ?? true;
    }

    return granted;
  }

  static Future<void> scheduleDailyReminder({
    NotificationReminderTime? time,
  }) async {
    await initialize();
    if (kIsWeb) return;

    final reminderTime = time ?? await NotificationService.reminderTime();
    final scheduledDate = _nextReminderDate(reminderTime);

    await _plugin.zonedSchedule(
      id: _dailyReminderNotificationId,
      title: 'SYBAU Reminder',
      body: 'Zeit für dein Workout.',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_workout_reminder',
          'Workout Reminder',
          channelDescription: 'Tägliche Erinnerung für dein Workout.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          presentBanner: true,
          presentList: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          presentBanner: true,
          presentList: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily-workout-reminder',
    );
  }

  static tz.TZDateTime _nextReminderDate(NotificationReminderTime time) {
    _ensureTimeZones();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  static void _ensureTimeZones() {
    if (_timeZonesInitialized) return;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(_bestLocalTimezoneName()));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Vienna'));
    }
    _timeZonesInitialized = true;
  }

  static String _bestLocalTimezoneName() {
    switch (DateTime.now().timeZoneName.toUpperCase()) {
      case 'CET':
      case 'CEST':
        return 'Europe/Vienna';
      case 'GMT':
      case 'UTC':
        return 'UTC';
      default:
        return 'Europe/Vienna';
    }
  }
}
