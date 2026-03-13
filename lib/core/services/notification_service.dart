// lib/core/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/reminder_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ─── 安排提醒 ─────────────────────────────────────────────────

  Future<void> scheduleReminder(ReminderModel reminder) async {
    final channelId = _channelId(reminder.type);
    final channelName = _channelName(reminder.type);

    await _plugin.zonedSchedule(
      reminder.id.hashCode,
      reminder.title,
      reminder.message,
      _nextOccurrence(reminder.hour, reminder.minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder(String reminderId) async {
    await _plugin.cancel(reminderId.hashCode);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ─── 立即显示通知（虚拟人主动打招呼）────────────────────────
  Future<void> showAvatarMessage({
    required String avatarName,
    required String message,
  }) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '$avatarName 想和你说话 💬',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'avatar_msg',
          '虚拟人消息',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  tz.TZDateTime _nextOccurrence(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  String _channelId(ReminderType type) {
    switch (type) {
      case ReminderType.medication:    return 'medication_reminder';
      case ReminderType.dailyGreeting: return 'daily_greeting';
      case ReminderType.exercise:      return 'exercise_reminder';
      case ReminderType.checkIn:       return 'checkin_reminder';
      case ReminderType.custom:        return 'custom_reminder';
    }
  }

  String _channelName(ReminderType type) {
    switch (type) {
      case ReminderType.medication:    return '服药提醒';
      case ReminderType.dailyGreeting: return '每日问候';
      case ReminderType.exercise:      return '运动提醒';
      case ReminderType.checkIn:       return '虚拟人打招呼';
      case ReminderType.custom:        return '自定义提醒';
    }
  }
}
