import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/budgets_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/spending_insights_screen.dart';
import 'screens/privacy_security_screen.dart';
import 'services/notification_service.dart';
import 'services/automatic_notification_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'screens/help_support_screen.dart';

// Global navigator key for notification tap handling
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Flag to prevent duplicate scheduling
bool _notificationsScheduled = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // STEP 1: Clear ALL existing notifications first (clean slate)
  debugPrint('🧹 Cleaning up old notifications...');
  await NotificationService().cancelAllNotifications();
  debugPrint('✅ All old notifications cleared');

  // Initialize notifications
  await NotificationService().init();

  // Set the tap handler with all payload types
  NotificationService.onNotificationTap = (response) {
    final payload = response.payload;
    if (payload == null) return;

    debugPrint('🔔 Notification tapped with payload: $payload');

    // Add a small delay to ensure the app is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      if (payload.startsWith('goal_')) {
        navigatorKey.currentState?.pushNamed('/budgets');
      } else if (payload == 'budgets') {
        navigatorKey.currentState?.pushNamed('/budgets');
      } else if (payload == 'insights') {
        navigatorKey.currentState?.pushNamed('/spending-insights');
      } else if (payload == 'personality') {
        navigatorKey.currentState?.pushNamed('/spending-insights');
      } else if (payload == 'goals') {
        navigatorKey.currentState?.pushNamed('/budgets');
      } else if (payload == 'dashboard') {
        navigatorKey.currentState?.pushNamed('/dashboard');
      } else if (payload == 'transactions') {
        navigatorKey.currentState?.pushNamed('/transactions');
      }
    });
  };

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Check notification permissions after a short delay
  Future.delayed(const Duration(seconds: 2), () async {
    final hasPermission = await NotificationService().requestPermissions();
    debugPrint('📱 Notification permission: $hasPermission');

    final hasExactAlarm = await NotificationService().checkExactAlarmPermission();
    debugPrint('⏰ Exact alarm permission: $hasExactAlarm');
  });

  // Load theme before running app
  runApp(await initializeApp());
}

// Initialize app with theme loaded
Future<Widget> initializeApp() async {
  // Create the provider
  final themeProvider = ThemeProvider();

  // Load saved theme
  await themeProvider.loadTheme();

  // Schedule notifications on app start if user is logged in
  // Add a small delay to let UI load first
  Future.delayed(const Duration(milliseconds: 500), () {
    _scheduleNotificationsOnStart();
  });

  // Return the app with the provider
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
    ],
    child: const BlueWalletApp(),
  );
}

// Schedule notifications when app starts
Future<void> _scheduleNotificationsOnStart() async {
  // PREVENT DUPLICATE SCHEDULING
  if (_notificationsScheduled) {
    debugPrint('📱 Notifications already scheduled in this session, checking if reschedule needed...');

    // Still check if daily reminders need rescheduling
    try {
      final user = await StorageService.getUser();
      if (user != null && user.notificationsEnabled) {
        final firstName = user.name.split(' ').first;
        await NotificationService().checkAndRescheduleIfNeeded(firstName);
      }
    } catch (e) {
      debugPrint('❌ Error checking reschedule: $e');
    }
    return;
  }

  try {
    final isLoggedIn = await AuthService.isLoggedIn();
    if (!isLoggedIn) {
      debugPrint('📱 User not logged in, skipping notification scheduling');
      return;
    }

    final user = await StorageService.getUser();
    if (user == null) {
      debugPrint('📱 User data not found, skipping notification scheduling');
      return;
    }

    // Check if user has notifications enabled
    if (!user.notificationsEnabled) {
      debugPrint('📱 Notifications are disabled by user');
      return;
    }

    // Get first name for notifications
    final firstName = user.name.split(' ').first;

    debugPrint('🔄 Starting fresh notification scheduling for ${user.name}...');

    // Cancel all existing notifications to ensure clean slate
    await NotificationService().cancelAllNotifications();
    await Future.delayed(const Duration(milliseconds: 500));

    // Schedule fresh daily notifications (14 days only)
    await NotificationService().scheduleExtendedDailyNotifications(firstName);

    // Load all data for other notification types
    final transactions = await StorageService.getTransactions();
    final budgets = await StorageService.getBudgets();
    final goals = await StorageService.getSavingsGoals();

    debugPrint('📊 Loading data for notifications:');
    debugPrint('   - Transactions: ${transactions.length}');
    debugPrint('   - Budgets: ${budgets.length}');
    debugPrint('   - Goals: ${goals.length}');

    // Schedule all other notifications (budget, goal, insight, motivational)
    await AutomaticNotificationService().scheduleAllNotifications(
      user: user,
      transactions: transactions,
      budgets: budgets,
      goals: goals,
    );

    // Mark as scheduled
    _notificationsScheduled = true;

    // Final check of what's scheduled
    await NotificationService().printPendingNotifications();
    debugPrint('✅ All notifications scheduled successfully (30-day cycle)');

  } catch (e) {
    debugPrint('❌ Error scheduling notifications on start: $e');
  }
}

class BlueWalletApp extends StatelessWidget {
  const BlueWalletApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the current theme from provider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'BlueWallet NP',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primaryColor: themeProvider.primaryColor,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeProvider.primaryColor,
          primary: themeProvider.primaryColor,
          secondary: _getSecondaryColor(themeProvider.primaryColor),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: themeProvider.primaryColor,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: themeProvider.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/transactions': (context) => const TransactionsScreen(),
        '/add-transaction': (context) => const AddTransactionScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/budgets': (context) => const BudgetsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/spending-insights': (context) => const SpendingInsightsScreen(),
        '/privacy-security': (context) => const PrivacySecurityScreen(),
        '/help-support': (context) => const HelpSupportScreen(),
      },
    );
  }

  // Helper to get secondary color based on primary
  Color _getSecondaryColor(Color primary) {
    if (primary == const Color(0xFF007AFF)) return const Color(0xFF00C1D4);
    if (primary == const Color(0xFF34C759)) return const Color(0xFF74C69D);
    if (primary == const Color(0xFFAF52DE)) return const Color(0xFFD291FF);
    if (primary == const Color(0xFF1C1C1E)) return const Color(0xFF3A3A3C);
    return const Color(0xFF00C1D4);
  }
}