import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/budget.dart';
import '../utils/app_colors.dart';
import 'dart:math';

/// REQUIRED: Top-level background handler
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  debugPrint('Background notification clicked: ${response.payload}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _hasExactAlarmPermission = false;
  final Random _random = Random();

  bool get isInitialized => _isInitialized;
  bool get hasExactAlarmPermission => _hasExactAlarmPermission;

  // Static callback for handling taps (to be set from main)
  static Function(NotificationResponse)? onNotificationTap;

  // ==============================
  // INITIALIZATION
  // ==============================
  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    // Use border icon for the notification icon (left side)
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@drawable/monivoappnotificationborder');

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Create main notification channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'automatic_channel',
          'Monivo Notifications',
          description: 'Reminders and insights for your finances',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );

      // Create daily reminders channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'daily_reminders',
          'Daily Reminders',
          description: 'Friendly reminders to track your expenses',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );

      // Create budget alerts channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'budget_alerts',
          'Budget Alerts',
          description: 'Alerts about your budget status',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );

      // Create goal reminders channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'goal_reminders',
          'Goal Reminders',
          description: 'Reminders about your savings goals',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );

      await androidImplementation.requestExactAlarmsPermission();
    }

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
          debugPrint('Notification clicked: ${response.payload}');
          if (onNotificationTap != null) {
            onNotificationTap!(response);
          }
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      _isInitialized = true;
      debugPrint('Notification service initialized successfully with border icon');
      await checkExactAlarmPermission();
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  // ==============================
  // EXACT ALARM PERMISSION HANDLING
  // ==============================
  Future<bool> checkExactAlarmPermission() async {
    if (kIsWeb) return false;

    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? canSchedule =
        await androidImplementation.canScheduleExactNotifications();
        _hasExactAlarmPermission = canSchedule ?? false;
        debugPrint('Exact alarm permission: $_hasExactAlarmPermission');
        return _hasExactAlarmPermission;
      }
    } catch (e) {
      debugPrint('Error checking exact alarm permission: $e');
    }
    return false;
  }

  Future<void> requestExactAlarmPermission(BuildContext context) async {
    if (kIsWeb) return;

    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? granted =
        await androidImplementation.requestExactAlarmsPermission();

        if (granted == true) {
          _hasExactAlarmPermission = true;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                Text('Permission granted! You can now receive reminders.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          final String manufacturer = await _getDeviceManufacturer();
          _showManufacturerPermissionDialog(context, manufacturer);
        }
      }
    } catch (e) {
      debugPrint('Error requesting exact alarm permission: $e');
    }
  }

  Future<String> _getDeviceManufacturer() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (!kIsWeb) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.manufacturer;
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }
    return 'unknown';
  }

  void _showManufacturerPermissionDialog(
      BuildContext context, String manufacturer) {
    final String instructions = _getManufacturerInstructions(manufacturer);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'To receive timely reminders for your savings goals, please manually enable the "Alarms & reminders" permission.',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📍 Instructions:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(instructions),
                      const SizedBox(height: 12),
                      const Text(
                        '🔍 Look for:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      const Text('• "Alarms & reminders"'),
                      const Text('• "Schedule exact alarms"'),
                      const Text('• "Additional permissions"'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  String _getManufacturerInstructions(String manufacturer) {
    final lowerManufacturer = manufacturer.toLowerCase();

    if (lowerManufacturer.contains('xiaomi') || lowerManufacturer.contains('mi')) {
      return '📱 Xiaomi/MiUI:\nSettings → Permissions → Other permissions → Alarms & reminders';
    } else if (lowerManufacturer.contains('samsung')) {
      return '📱 Samsung:\nSettings → Apps → Monivo → Permissions → Alarms & reminders';
    } else if (lowerManufacturer.contains('huawei')) {
      return '📱 Huawei:\nSettings → Apps → Apps → Monivo → Permissions → Set alarms';
    } else if (lowerManufacturer.contains('oppo')) {
      return '📱 OPPO:\nSettings → Permissions → Monivo → Alarms & reminders';
    } else if (lowerManufacturer.contains('vivo')) {
      return '📱 Vivo:\nSettings → Apps → Monivo → Permissions → Alarms & reminders';
    } else if (lowerManufacturer.contains('oneplus')) {
      return '📱 OnePlus:\nSettings → Apps → Monivo → Additional permissions → Alarms & reminders';
    } else if (lowerManufacturer.contains('google') || lowerManufacturer.contains('pixel')) {
      return '📱 Google Pixel:\nSettings → Apps → Monivo → Permissions → Alarms & reminders';
    } else {
      return '📱 Settings → Apps → Monivo → Permissions → Alarms & reminders';
    }
  }

  Future<void> _openAppSettings() async {
    try {
      const intent = AndroidIntent(
        action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
        data: 'package:com.sanjaya.monivo',
      );
      await intent.launch();
    } catch (e) {
      debugPrint('Error opening settings: $e');
    }
  }

  // ==============================
  // PERMISSIONS
  // ==============================
  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;

    try {
      final AndroidFlutterLocalNotificationsPlugin? android =
      _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      final IOSFlutterLocalNotificationsPlugin? iOS =
      _notificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      final bool? androidResult =
      await android?.requestNotificationsPermission();

      final bool? iOSResult = await iOS?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      return androidResult == true || iOSResult == true;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  // ==============================
  // SCHEDULE ONE-TIME NOTIFICATION
  // ==============================
  Future<void> scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    String? channelId,
  }) async {
    if (!_isInitialized) {
      debugPrint('Notification service not initialized');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId ?? 'automatic_channel',
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@drawable/monivoappnotificationborder',
      // REMOVED largeIcon to prevent resource not found error
      styleInformation: const BigTextStyleInformation(''),
    );

    const iOSDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iOSDetails);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    debugPrint('✅ Scheduled notification ID: $id, Title: $title, Date: $scheduledDate');
  }

  String _getChannelName(String? channelId) {
    switch (channelId) {
      case 'daily_reminders': return 'Daily Reminders';
      case 'budget_alerts': return 'Budget Alerts';
      case 'goal_reminders': return 'Goal Reminders';
      case 'automatic_channel': return 'Smart Insights';
      default: return 'Monivo Notifications';
    }
  }

  String _getChannelDescription(String? channelId) {
    switch (channelId) {
      case 'daily_reminders': return 'Friendly daily reminders to track your expenses';
      case 'budget_alerts': return 'Alerts and updates about your budgets';
      case 'goal_reminders': return 'Reminders about your savings goals';
      case 'automatic_channel': return 'Personalized financial insights and tips';
      default: return 'Notifications from Monivo';
    }
  }

  // ==============================
  // SCHEDULE EXTENDED NOTIFICATIONS (14 DAYS WITH AUTO-RESCHEDULE)
  // ==============================
  Future<void> scheduleExtendedDailyNotifications(String firstName) async {
    if (!_isInitialized) return;

    final now = DateTime.now();

    // Cancel existing daily notifications
    await cancelNotificationsInRange(1001, 2000);

    // Schedule for next 14 days
    int scheduledCount = 0;
    for (int day = 0; day < 14; day++) {
      // Morning notifications (8:30 AM) - With name
      final morningTime = DateTime(now.year, now.month, now.day, 8, 30).add(Duration(days: day));
      if (morningTime.isAfter(now)) {
        await scheduleOneTimeNotification(
          id: 1001 + day,
          title: _getRandomMorningTitle(),
          body: _getRandomMorningMessage(firstName),
          scheduledDate: morningTime,
          payload: 'dashboard',
          channelId: 'daily_reminders',
        );
        scheduledCount++;
      }

      // Evening notifications (8:30 PM) - Without name
      final eveningTime = DateTime(now.year, now.month, now.day, 20, 30).add(Duration(days: day));
      if (eveningTime.isAfter(now)) {
        await scheduleOneTimeNotification(
          id: 1501 + day,
          title: _getRandomEveningTitle(),
          body: _getRandomEveningMessage(),
          scheduledDate: eveningTime,
          payload: 'transactions',
          channelId: 'daily_reminders',
        );
        scheduledCount++;
      }
    }

    debugPrint('✅ Scheduled $scheduledCount notifications for next 14 days');
  }

  // ==============================
  // AUTO-RESCHEDULE CHECK (Called on app start and when notifications are low)
  // ==============================
  Future<bool> checkAndRescheduleIfNeeded(String firstName) async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();

    // Filter to only daily notifications (IDs between 1001-1999)
    final dailyNotifications = pending.where((n) => n.id >= 1001 && n.id <= 1999).length;

    debugPrint('📊 Daily notifications remaining: $dailyNotifications');

    // If less than 7 days of notifications left (14 notifications), reschedule
    if (dailyNotifications < 14) {
      debugPrint('⚠️ Only $dailyNotifications daily notifications left, rescheduling for next 14 days...');
      await scheduleExtendedDailyNotifications(firstName);
      return true;
    } else {
      debugPrint('✅ $dailyNotifications daily notifications still scheduled');
      return false;
    }
  }

  // ==============================
  // AUTO-RESCHEDULE LOOP (Call this once on app start to enable continuous scheduling)
  // ==============================
  Future<void> enableContinuousNotifications(String firstName) async {
    // Check immediately
    await checkAndRescheduleIfNeeded(firstName);

    // Then check every 12 hours
    Future.delayed(const Duration(hours: 12), () {
      enableContinuousNotifications(firstName);
    });
  }

  String _getRandomMorningTitle() {
    final titles = [
      '☀️ Rise and shine, money master!',
      '🌅 Ready to conquer your finances?',
      '💰 Your daily financial check-in',
      '📊 Let\'s make today profitable!',
      '💪 Start your day financially strong',
      '🎯 Track your way to success today',
      '✨ Small expenses, big dreams - track them!',
      '🚀 Another day to grow your wealth',
      '💎 Every rupee counts - start tracking',
      '🌟 Today\'s financial wins await!',
      '🌞 Good morning, finance friend!',
      '📈 Ready to level up your money game?',
      '💭 Dreaming of financial freedom?',
      '⚡ Energize your finances this morning',
      '🌈 Your financial rainbow awaits',
    ];
    return titles[_random.nextInt(titles.length)];
  }

  String _getRandomMorningMessage(String firstName) {
    final messages = [
      "Hey $firstName! How's your spending today? Log your transactions now! 📝",
      "$firstName, quick check-in: Have you recorded today's expenses yet? 💭",
      "Don't let expenses pile up! Add them now and stay on top! 🚀",
      "Stay financially aware! Log your transactions in Monivo 📱",
      "Small expenses add up! Track them today to save more! 💪",
      "$firstName, take a moment to log your morning expenses ☀️",
      "Time for a quick expense check, $firstName! 📊",
      "Morning check-in: Log your planned expenses for today and stay ahead!",
      "Quick morning question: What's one financial goal you can work on today?",
      "Rise and thrive! Take 2 minutes to review yesterday's spending.",
      "Your future self will thank you for tracking today's expenses.",
      "Financial freedom is built one day at a time. Start today strong!",
      "Before the day gets busy, log your expected transactions.",
      "Mindful morning: Set your spending intentions for today.",
      "Your wallet called - it wants you to check in!",
      "Morning ritual: Check balances, plan spending, succeed financially.",
      "Today's financial forecast: Sunny with a chance of savings!",
    ];
    return messages[_random.nextInt(messages.length)];
  }

  String _getRandomEveningTitle() {
    final titles = [
      '🌙 Evening financial recap',
      '📝 How did your money behave today?',
      '💭 Reflect on today\'s spending',
      '⭐ Time for your daily finance review',
      '🎯 Did you hit your money goals today?',
      '🏁 One day closer to financial freedom',
      '🔍 Let\'s review today\'s money moves',
      '💫 Wind down with a spending check',
      '📊 Your daily financial snapshot',
      '🎪 Another day, another step forward',
      '🌛 Night owl money check',
      '🎯 End-of-day money minute',
      '✨ You\'re financially awesome!',
      '🌟 Shine bright with good money habits',
      '📖 Chapter complete - today\'s finances',
      '🎬 That\'s a wrap on today\'s spending',
      '💪 Strong finish to your financial day',
      '🏅 Another day of financial discipline',
    ];
    return titles[_random.nextInt(titles.length)];
  }

  String _getRandomEveningMessage() {
    final messages = [
      "Great job today! Log any remaining expenses before you sleep 💤",
      "Evening check: Did you record all your spending today? 🌙",
      "Tomorrow's budget starts today! Update your expenses now ✨",
      "Quick recap: Add any forgotten transactions from today 📱",
      "Review today's spending before bed for better awareness 🛌",
      "Almost done! Just a few more expenses to log? 📝",
      "End your day financially aware - check your spending! 🌟",
      "Take 30 seconds to log any forgotten expenses. Your future self cheers!",
      "You're making great progress with every tracked transaction!",
      "Financial peace of mind comes from knowing where your money went.",
      "Today's tracking = tomorrow's insights. Keep up the great work!",
      "Your financial story is being written. Make today's chapter a good one!",
      "Every tracked expense is a step toward financial mastery. Well done!",
      "Sleep well knowing you're in control of your finances.",
      "You're part of the financially aware elite. Keep tracking, keep winning!",
      "Today's money moves are logged. Time to rest and recharge!",
      "Your dedication to tracking is inspiring. Future you is celebrating!",
    ];
    return messages[_random.nextInt(messages.length)];
  }

  // ==============================
  // SCHEDULE DAILY NOTIFICATIONS (Legacy)
  // ==============================
  Future<void> scheduleDailyNotifications(String firstName) async {
    // Redirect to extended version
    await scheduleExtendedDailyNotifications(firstName);
  }

  // ==============================
  // CANCEL NOTIFICATIONS IN RANGE
  // ==============================
  Future<void> cancelNotificationsInRange(int startId, int endId) async {
    for (int id = startId; id <= endId; id++) {
      await _notificationsPlugin.cancel(id);
    }
    debugPrint('✅ Cancelled notifications from $startId to $endId');
  }

  // ==============================
  // CANCEL ALL
  // ==============================
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('✅ All notifications cancelled');
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  // ==============================
  // GET PENDING NOTIFICATIONS COUNT BY TYPE
  // ==============================
  Future<Map<String, int>> getPendingNotificationsCount() async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();

    int daily = pending.where((n) => n.id >= 1001 && n.id <= 1999).length;
    int budget = pending.where((n) => n.id >= 2000 && n.id <= 2999).length;
    int goal = pending.where((n) => n.id >= 3000 && n.id <= 3999).length;
    int insight = pending.where((n) => n.id >= 4000 && n.id <= 4999).length;
    int motivational = pending.where((n) => n.id >= 5000 && n.id <= 5999).length;

    return {
      'daily': daily,
      'budget': budget,
      'goal': goal,
      'insight': insight,
      'motivational': motivational,
      'total': pending.length,
    };
  }

  // ==============================
  // TEST NOTIFICATION (Fixed - removed largeIcon)
  // ==============================
  Future<void> showTestNotification() async {
    if (!_isInitialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Test notifications',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@drawable/monivoappnotificationborder',
        // REMOVED largeIcon to prevent resource not found error
      );

      const iOSDetails = DarwinNotificationDetails();

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _notificationsPlugin.show(
        9999,
        '🧪 Test Notification',
        'If you see this, notifications are working!',
        notificationDetails,
      );

      debugPrint('✅ Test notification shown');
    } catch (e) {
      debugPrint('Error showing test notification: $e');
    }
  }

  // ==============================
  // CHECK SCHEDULED NOTIFICATIONS
  // ==============================
  Future<void> printPendingNotifications() async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    final counts = await getPendingNotificationsCount();

    debugPrint('📋 Pending notifications: ${pending.length}');
    debugPrint('   - Daily: ${counts['daily']}');
    debugPrint('   - Budget: ${counts['budget']}');
    debugPrint('   - Goal: ${counts['goal']}');
    debugPrint('   - Insight: ${counts['insight']}');
    debugPrint('   - Motivational: ${counts['motivational']}');

    // Print first 5 for debugging
    for (var req in pending.take(5)) {
      debugPrint('  - ID: ${req.id}, Title: ${req.title}, Payload: ${req.payload}');
    }
  }
}