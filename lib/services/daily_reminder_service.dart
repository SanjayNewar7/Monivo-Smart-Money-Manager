import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class DailyReminderService {
  static final DailyReminderService _instance = DailyReminderService._internal();
  factory DailyReminderService() => _instance;
  DailyReminderService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int _middayNotificationId = 1001;
  static const int _eveningNotificationId = 1002;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Daily reminder clicked');
        },
      );
      _isInitialized = true;
      debugPrint('Daily reminder service initialized');
    } catch (e) {
      debugPrint('Failed to initialize daily reminders: $e');
    }
  }

  Future<void> scheduleDailyReminders() async {
    if (!_isInitialized) {
      debugPrint('Daily reminder service not initialized');
      return;
    }

    try {
      // Cancel existing daily reminders
      await _notificationsPlugin.cancel(_middayNotificationId);
      await _notificationsPlugin.cancel(_eveningNotificationId);

      final androidDetails = AndroidNotificationDetails(
        'daily_reminder_channel',
        'Daily Reminders',
        channelDescription: 'Friendly reminders to track your expenses',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        color: const Color(0xFF007AFF),
        styleInformation: const BigTextStyleInformation(''),
      );

      final iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      // Midday reminder (12:30 PM)
      final middayTime = tz.TZDateTime.from(
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 12, 30),
        tz.local,
      );

      // If time already passed today, schedule for tomorrow
      final scheduledMidday = middayTime.isBefore(tz.TZDateTime.now(tz.local))
          ? middayTime.add(const Duration(days: 1))
          : middayTime;

      await _notificationsPlugin.zonedSchedule(
        _middayNotificationId,
        '💰 Time to Track Your Expenses',
        _getRandomMiddayMessage(),
        scheduledMidday,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // Evening reminder (8:30 PM)
      final eveningTime = tz.TZDateTime.from(
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 20, 30),
        tz.local,
      );

      final scheduledEvening = eveningTime.isBefore(tz.TZDateTime.now(tz.local))
          ? eveningTime.add(const Duration(days: 1))
          : eveningTime;

      await _notificationsPlugin.zonedSchedule(
        _eveningNotificationId,
        '📊 Daily Check-in',
        _getRandomEveningMessage(),
        scheduledEvening,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('Daily reminders scheduled');
    } catch (e) {
      debugPrint('Error scheduling daily reminders: $e');
    }
  }

  String _getRandomMiddayMessage() {
    final messages = [
      'How\'s your spending today? Log your transactions now!',
      'Quick check-in: Have you recorded today\'s expenses?',
      'Don\'t let expenses pile up - add them now!',
      'Stay on top of your finances - log your transactions 📝',
      'Small expenses add up. Track them today!',
    ];
    return messages[DateTime.now().second % messages.length];
  }

  String _getRandomEveningMessage() {
    final messages = [
      'Great job today! Log any remaining expenses before you sleep 💤',
      'Evening check: Did you record all your spending today?',
      'Tomorrow\'s budget starts today. Update your expenses!',
      'Quick recap: Add any forgotten transactions now 📱',
      'Stay financially aware - review today\'s spending',
    ];
    return messages[DateTime.now().minute % messages.length];
  }

  Future<void> cancelDailyReminders() async {
    await _notificationsPlugin.cancel(_middayNotificationId);
    await _notificationsPlugin.cancel(_eveningNotificationId);
  }
}