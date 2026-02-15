import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _frequencyKey = 'notification_frequency';
  static const String _enabledKey = 'notifications_enabled';
  static const String _startHourKey = 'notification_start_hour';
  static const String _endHourKey = 'notification_end_hour';

  Future<void> initialize() async {
    if (kIsWeb) return; // Notifications not supported on web

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - could navigate to word detail
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;

    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleWordReminders(DatabaseService dbService) async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? true;
    if (!enabled) {
      await cancelAllNotifications();
      return;
    }

    final frequency = prefs.getInt(_frequencyKey) ?? 5;
    final startHour = prefs.getInt(_startHourKey) ?? 9;
    final endHour = prefs.getInt(_endHourKey) ?? 21;

    await cancelAllNotifications();

    final words = await dbService.getWords();
    if (words.isEmpty) return;

    final random = Random();
    final now = DateTime.now();

    for (int i = 0; i < frequency; i++) {
      final word = words[random.nextInt(words.length)];
      final hour = startHour + random.nextInt(endHour - startHour);
      final minute = random.nextInt(60);

      var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
      // If time has passed today, schedule for tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      await _showScheduledNotification(
        id: i,
        title: '📚 Kelime Hatırlatma',
        body: '${word.sourceWord} → ${word.translatedWord}',
        scheduledTime: scheduledTime,
      );
    }
  }

  Future<void> _showScheduledNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'word_reminder_channel',
      'Kelime Hatırlatmaları',
      channelDescription: 'Kaydedilen kelimeleri hatırlatır',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Use zonedSchedule for precise timing, but for simplicity we use
    // a delayed show approach. In production, use timezone package.
    final delay = scheduledTime.difference(DateTime.now());
    if (delay.isNegative) return;

    // For a simple implementation, we schedule using the delay
    Future.delayed(delay, () {
      _notifications.show(id, title, body, details);
    });
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    const androidDetails = AndroidNotificationDetails(
      'word_reminder_channel',
      'Kelime Hatırlatmaları',
      channelDescription: 'Kaydedilen kelimeleri hatırlatır',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(0, title, body, details);
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
  }

  // Settings helpers
  Future<int> getFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_frequencyKey) ?? 5;
  }

  Future<void> setFrequency(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_frequencyKey, value);
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  Future<int> getStartHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_startHourKey) ?? 9;
  }

  Future<void> setStartHour(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_startHourKey, value);
  }

  Future<int> getEndHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_endHourKey) ?? 21;
  }

  Future<void> setEndHour(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_endHourKey, value);
  }
}
