import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/app_colors.dart';
import '../services/storage_service.dart';
import '../services/automatic_notification_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // 15 engaging and creative subtitles
  final List<String> _subtitles = [
    'Every penny tells a story — make yours count',
    'Watch your wealth grow, one smart decision at a time',
    'Budget like a pro, live like a king',
    'Turning financial chaos into crystal clarity',
    'Plant money seeds today, harvest abundance tomorrow',
    'Your finances, supercharged and simplified',
    'Level up your money game',
    'See the future of your finances, today',
    'Because your dreams deserve a solid plan',
    'Where smart money meets simple living',
    'Making money management feel like magic',
    'Join thousands mastering their financial destiny',
    'Ride the wave of financial freedom',
    'Paint your financial masterpiece with Monivo',
    'Your wallet\'s new best friend',
  ];

  late String _currentSubtitle;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Select random subtitle on each app open
    _currentSubtitle = _subtitles[Random().nextInt(_subtitles.length)];

    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    final isFirstLaunch = await StorageService.isFirstLaunch();
    final isLoggedIn = await AuthService.isLoggedIn();
    final user = await StorageService.getUser();

    if (isFirstLaunch) {
      // First time user - go to onboarding
      Navigator.pushReplacementNamed(context, '/onboarding');
    } else if (isLoggedIn && user != null) {
      // User is logged in - go to dashboard
      _loadDataAndScheduleNotifications(user);
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      // User needs to login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _loadDataAndScheduleNotifications(UserProfile user) async {
    final transactions = await StorageService.getTransactions();
    final budgets = await StorageService.getBudgets();
    final goals = await StorageService.getSavingsGoals();

    await AutomaticNotificationService().scheduleAllNotifications(
      user: user,
      transactions: transactions,
      budgets: budgets,
      goals: goals,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryBlue,
              AppColors.accentTeal,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset(
                      'assets/icons/monivoappicon.png',
                      width: 128,
                      height: 128,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback icon if image fails to load
                        return const Icon(
                          Icons.account_balance_wallet,
                          size: 64,
                          color: AppColors.primaryBlue,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const Text(
                      'Monivo',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Main subtitle - engaging and creative, no italic
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Text(
                        _currentSubtitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tagline badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Text(
                        ' Smart Money Manager ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 64),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                        (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}