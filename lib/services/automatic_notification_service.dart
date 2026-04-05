import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../models/user_model.dart';
import 'notification_service.dart';
import 'personality_service.dart';
import 'dart:math';

class AutomaticNotificationService {
  static const int _baseId = 10000; // IDs for automatic notifications
  final Random _random = Random();

  // Flag to track if notifications have been scheduled in this session
  static bool _isScheduled = false;

  /// Cancel all previously scheduled automatic notifications and
  /// schedule new ones based on current data.
  Future<void> scheduleAllNotifications({
    required UserProfile user,
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required List<SavingsGoal> goals,
  }) async {
    // PREVENT DUPLICATE SCHEDULING
    if (_isScheduled) {
      debugPrint('📱 Notifications already scheduled in this session, skipping...');

      // Still check if daily reminders need rescheduling
      final firstName = user.name.split(' ').first;
      await NotificationService().checkAndRescheduleIfNeeded(firstName);
      return;
    }

    // If notifications are globally disabled, cancel everything and exit.
    if (!user.notificationsEnabled) {
      await NotificationService().cancelNotificationsInRange(_baseId, _baseId + 9999);
      return;
    }

    debugPrint('🔄 Starting fresh notification scheduling...');

    // Cancel ALL existing notifications first to prevent duplicates
    await NotificationService().cancelAllNotifications();

    // Small delay to ensure cancellation completes
    await Future.delayed(const Duration(milliseconds: 500));

    // Get first name only
    final firstName = user.name.split(' ').first;

    // Schedule daily reminders (2 times per day for 14 days)
    await NotificationService().scheduleExtendedDailyNotifications(firstName);

    // Calculate user metrics for personalized notifications
    final metrics = _calculateUserMetrics(transactions, budgets, goals);

    // Schedule budget reminders (for 30 days with variety)
    await _scheduleBudgetReminders(budgets, user.preferredCurrency, firstName, metrics, days: 30);

    // Schedule goal reminders (for 30 days with variety)
    await _scheduleGoalReminders(goals, user.preferredCurrency, firstName, metrics, days: 30);

    // Schedule insight reminders (for 30 days with variety)
    await _scheduleInsightReminders(transactions, budgets, goals, user, firstName, metrics, days: 30);

    // Schedule motivational reminders (for 30 days)
    await _scheduleMotivationalReminders(firstName, metrics, days: 30);

    // Mark as scheduled
    _isScheduled = true;

    // Print pending notifications for debugging
    await NotificationService().printPendingNotifications();

    debugPrint('✅ All notifications scheduled successfully for 30 days');
  }

  // Calculate user metrics for personalized notifications
  Map<String, dynamic> _calculateUserMetrics(
      List<Transaction> transactions,
      List<Budget> budgets,
      List<SavingsGoal> goals,
      ) {
    final now = DateTime.now();

    // Monthly income/expenses
    final monthlyIncome = transactions
        .where((t) => t.type == TransactionType.income && t.date.month == now.month && t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);

    final monthlyExpenses = transactions
        .where((t) => t.type == TransactionType.expense && t.date.month == now.month && t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);

    final savingsRate = monthlyIncome > 0 ? ((monthlyIncome - monthlyExpenses) / monthlyIncome * 100) : 0.0;

    // Top category
    final categoryTotals = <String, double>{};
    for (var t in transactions.where((t) => t.type == TransactionType.expense && t.date.month == now.month)) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }

    String topCategory = 'N/A';
    double topAmount = 0;
    if (categoryTotals.isNotEmpty) {
      final top = categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      topCategory = top.key;
      topAmount = top.value;
    }

    // Transaction count
    final transactionCount = transactions.length;

    // Budget status
    final exceededBudgets = budgets.where((b) => b.isExceeded).length;
    final warningBudgets = budgets.where((b) => b.isWarning).length;

    // Goal status
    final behindGoals = goals.where((g) => g.isBehind).length;
    final completedGoals = goals.where((g) => g.progress >= 100).length;
    final totalGoalProgress = goals.isNotEmpty
        ? goals.map((g) => g.progress).reduce((a, b) => a + b) / goals.length
        : 0.0;

    return {
      'monthlyIncome': monthlyIncome,
      'monthlyExpenses': monthlyExpenses,
      'savingsRate': savingsRate,
      'topCategory': topCategory,
      'topCategoryAmount': topAmount,
      'transactionCount': transactionCount,
      'exceededBudgets': exceededBudgets,
      'warningBudgets': warningBudgets,
      'behindGoals': behindGoals,
      'completedGoals': completedGoals,
      'totalGoalProgress': totalGoalProgress,
    };
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Goal reminders – with configurable days
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleGoalReminders(
      List<SavingsGoal> goals,
      Currency currency,
      String firstName,
      Map<String, dynamic> metrics, {
        required int days,
      }) async {
    if (goals.isEmpty) return;

    final now = DateTime.now();
    final activeGoals = goals.where((g) => g.progress < 100).toList();
    if (activeGoals.isEmpty) return;

    // Schedule for specified days
    for (int day = 1; day <= days; day++) {
      // Random time between 9 AM and 6 PM for variety
      final hour = 9 + _random.nextInt(9);
      final minute = _random.nextInt(60);
      final scheduleDate = DateTime(now.year, now.month, now.day, hour, minute).add(Duration(days: day));

      // Select random goal to feature
      final goal = activeGoals[_random.nextInt(activeGoals.length)];

      final id = 3000 + (goal.id.hashCode % 1000) + day;

      // Decide if this notification includes name (every 3rd notification)
      final includeName = day % 3 == 0;

      final (title, body) = _generateGoalMessage(goal, currency, firstName, includeName, day, metrics);

      await NotificationService().scheduleOneTimeNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduleDate,
        payload: 'budgets',
        channelId: 'goal_reminders',
      );
    }
  }

  (String, String) _generateGoalMessage(
      SavingsGoal goal,
      Currency currency,
      String firstName,
      bool includeName,
      int day,
      Map<String, dynamic> metrics,
      ) {
    final progress = goal.progress.toStringAsFixed(1);
    final remaining = goal.remaining;
    final daysLeft = goal.daysRemaining;
    final daily = goal.requiredDaily;

    // Different message templates based on goal status
    if (goal.isBehind) {
      final titles = [
        '⏰ Behind on "${goal.name}"',
        '⚠️ "${goal.name}" needs attention',
        '🎯 Catch up on "${goal.name}"',
        '💪 Don\'t give up on "${goal.name}"',
        '⚡ Quick boost needed for "${goal.name}"',
      ];

      final bodies = includeName
          ? [
        "$firstName, your \"${goal.name}\" goal is behind schedule. Need ${_formatCurrency(daily, currency)} per day to catch up!",
        "Hey $firstName, only $daysLeft days left for \"${goal.name}\". Let's push hard! 💪",
        "$firstName, you're $progress% toward \"${goal.name}\". Time to accelerate your savings!",
        "Don't lose momentum, $firstName! ${_formatCurrency(remaining, currency)} more to reach \"${goal.name}\".",
      ]
          : [
        "Goal \"${goal.name}\" is behind. Need ${_formatCurrency(daily, currency)} per day to catch up!",
        "Only $daysLeft days left for \"${goal.name}\". Let's push hard! 💪",
        "You're $progress% toward \"${goal.name}\". Time to accelerate savings!",
        "${_formatCurrency(remaining, currency)} more to reach \"${goal.name}\". Keep going!",
      ];

      return (
      titles[day % titles.length],
      bodies[day % bodies.length] + ' ${_getRandomEmoji()}',
      );
    }
    else if (goal.progress >= 90) {
      final titles = [
        '🎉 Almost there: "${goal.name}"',
        '🏆 "${goal.name}" - so close!',
        '✨ Final push for "${goal.name}"',
        '💰 "${goal.name}" nearly complete',
        '🌟 "${goal.name}" - finish strong!',
      ];

      final bodies = includeName
          ? [
        "$firstName, you're $progress% toward \"${goal.name}\"! Just ${_formatCurrency(remaining, currency)} to go!",
        "Amazing progress, $firstName! ${_formatCurrency(remaining, currency)} left for \"${goal.name}\".",
        "You're almost there, $firstName! Finish strong on \"${goal.name}\"! 🎯",
      ]
          : [
        "You're $progress% toward \"${goal.name}\"! Just ${_formatCurrency(remaining, currency)} to go!",
        "Amazing progress! ${_formatCurrency(remaining, currency)} left for \"${goal.name}\".",
        "Almost there! Finish strong on \"${goal.name}\"! 🎯",
      ];

      return (
      titles[day % titles.length],
      bodies[day % bodies.length] + ' ${_getRandomEmoji()}',
      );
    }
    else {
      final titles = [
        '🎯 Goal update: "${goal.name}"',
        '💰 "${goal.name}" progress check',
        '📈 How is "${goal.name}" going?',
        '💭 Remember your "${goal.name}" goal',
        '✨ "${goal.name}" milestone update',
      ];

      final bodies = includeName
          ? [
        "$firstName, you're $progress% toward \"${goal.name}\"! ${_formatCurrency(remaining, currency)} left.",
        "Hey $firstName, don't forget your \"${goal.name}\" goal. Keep saving! 💪",
        "$firstName, $daysLeft days left for \"${goal.name}\". Stay focused!",
        "Great work on \"${goal.name}\", $firstName! You're making progress every day.",
      ]
          : [
        "You're $progress% toward \"${goal.name}\"! ${_formatCurrency(remaining, currency)} left.",
        "Don't forget your \"${goal.name}\" goal. Keep saving! 💪",
        "$daysLeft days left for \"${goal.name}\". Stay focused!",
        "Great work on \"${goal.name}\"! You're making progress every day.",
      ];

      return (
      titles[day % titles.length],
      bodies[day % bodies.length] + ' ${_getRandomEmoji()}',
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Budget reminders – with configurable days
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleBudgetReminders(
      List<Budget> budgets,
      Currency currency,
      String firstName,
      Map<String, dynamic> metrics, {
        required int days,
      }) async {
    if (budgets.isEmpty) return;

    final now = DateTime.now();

    // Schedule for specified days
    for (int day = 1; day <= days; day++) {
      // Random time between 10 AM and 7 PM
      final hour = 10 + _random.nextInt(9);
      final minute = _random.nextInt(60);
      final scheduleDate = DateTime(now.year, now.month, now.day, hour, minute).add(Duration(days: day));

      final id = 2000 + day;

      // Include name occasionally
      final includeName = day % 4 == 0;

      final (title, body) = _generateBudgetMessage(budgets, currency, firstName, includeName, day, metrics);

      await NotificationService().scheduleOneTimeNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduleDate,
        payload: 'budgets',
        channelId: 'budget_alerts',
      );
    }
  }

  (String, String) _generateBudgetMessage(
      List<Budget> budgets,
      Currency currency,
      String firstName,
      bool includeName,
      int day,
      Map<String, dynamic> metrics,
      ) {
    if (budgets.isEmpty) {
      return (
      includeName ? "Hey $firstName! Ready to budget?" : "Ready to create your first budget?",
      includeName
          ? "$firstName, creating a budget is the first step to financial freedom! Start today! 🎯"
          : "Creating a budget is the first step to financial freedom! Start today! 🎯",
      );
    }

    // Check for exceeded budgets first (highest priority)
    final exceeded = budgets.where((b) => b.isExceeded).toList();
    if (exceeded.isNotEmpty) {
      final budget = exceeded[day % exceeded.length];
      final overBy = budget.spent - budget.limit;

      final titles = [
        '⚠️ Budget Breach: ${budget.category}',
        '🚨 ${budget.category} over limit!',
        '📊 ${budget.category} budget exceeded',
        '⚡ Alert: ${budget.category} over budget',
      ];

      final bodies = includeName
          ? [
        "$firstName, you've exceeded your ${budget.category} budget by ${_formatCurrency(overBy, currency)}! Time to adjust.",
        "Heads up $firstName! ${budget.category} is over budget by ${_formatCurrency(overBy, currency)}.",
        "$firstName, your ${budget.category} spending is above limit. Review your expenses!",
      ]
          : [
        "Budget exceeded in ${budget.category} by ${_formatCurrency(overBy, currency)}! Time to adjust.",
        "${budget.category} is over budget by ${_formatCurrency(overBy, currency)}. Review expenses!",
        "Your ${budget.category} spending is above limit. Check your budget!",
      ];

      return (
      titles[day % titles.length],
      bodies[day % bodies.length] + ' ${_getRandomEmoji()}',
      );
    }

    // Check for warning budgets
    final warning = budgets.where((b) => b.isWarning).toList();
    if (warning.isNotEmpty) {
      final budget = warning[day % warning.length];

      final titles = [
        '🔔 ${budget.category} nearing limit',
        '📈 Watch your ${budget.category} spending',
        '🎯 ${budget.category} budget warning',
        '💭 ${budget.category} almost maxed',
      ];

      final bodies = includeName
          ? [
        "$firstName, you're nearing your ${budget.category} limit. Only ${_formatCurrency(budget.remaining, currency)} left!",
        "Careful $firstName! ${budget.category} has just ${_formatCurrency(budget.remaining, currency)} remaining.",
        "$firstName, your ${budget.category} budget is ${budget.progress.toStringAsFixed(0)}% used. Spend wisely!",
      ]
          : [
        "Nearing ${budget.category} limit. Only ${_formatCurrency(budget.remaining, currency)} left!",
        "Careful! ${budget.category} has just ${_formatCurrency(budget.remaining, currency)} remaining.",
        "Your ${budget.category} budget is ${budget.progress.toStringAsFixed(0)}% used. Spend wisely!",
      ];

      return (
      titles[day % titles.length],
      bodies[day % bodies.length] + ' ${_getRandomEmoji()}',
      );
    }

    // Healthy budgets - show general update
    final healthy = budgets.where((b) => b.isOnTrack).toList();
    if (healthy.isNotEmpty) {
      final budget = healthy[day % healthy.length];

      final titles = [
        '📊 Budget Update',
        '💰 How are your budgets?',
        '📈 Spending overview',
        '💳 Budget check-in',
        '🎯 On track with budgets',
      ];

      final bodies = includeName
          ? [
        "$firstName, you're doing great! ${budget.category} is at ${budget.progress.toStringAsFixed(0)}% of budget.",
        "Good job $firstName! You have ${_formatCurrency(budget.remaining, currency)} left in ${budget.category}.",
        "$firstName, stay on track! Your budgets are looking healthy this month.",
      ]
          : [
        "You're doing great! ${budget.category} is at ${budget.progress.toStringAsFixed(0)}% of budget.",
        "Good job! You have ${_formatCurrency(budget.remaining, currency)} left in ${budget.category}.",
        "Stay on track! Your budgets are looking healthy this month.",
      ];

      return (
      titles[day % titles.length],
      bodies[day % bodies.length] + ' ${_getRandomEmoji()}',
      );
    }

    // Fallback
    return (
    '📊 Budget Check',
    includeName ? "Hey $firstName, check your budgets in Monivo!" : "Check your budgets in Monivo!",
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Insight reminders – with configurable days
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleInsightReminders(
      List<Transaction> transactions,
      List<Budget> budgets,
      List<SavingsGoal> goals,
      UserProfile user,
      String firstName,
      Map<String, dynamic> metrics, {
        required int days,
      }) async {
    final now = DateTime.now();

    // Generate insights based on user data
    final insights = _generatePersonalizedInsights(transactions, budgets, goals, user, metrics);

    // Schedule for specified days
    for (int day = 1; day <= days; day++) {
      if (insights.isEmpty) break;

      final hour = 11 + _random.nextInt(6);
      final minute = _random.nextInt(60);
      final scheduleDate = DateTime(now.year, now.month, now.day, hour, minute).add(Duration(days: day));

      final id = 4000 + day;

      // Select insight based on day
      final insight = insights[day % insights.length];

      // Include name occasionally
      final includeName = day % 3 == 0;

      String body = insight['body'];
      if (includeName) {
        body = body.replaceAll('{{name}}', firstName);
      } else {
        body = body.replaceAll('{{name}}', '').trim();
      }

      await NotificationService().scheduleOneTimeNotification(
        id: id,
        title: insight['title'],
        body: body + ' ${_getRandomEmoji()}',
        scheduledDate: scheduleDate,
        payload: insight['payload'],
        channelId: 'automatic_channel',
      );
    }
  }

  List<Map<String, dynamic>> _generatePersonalizedInsights(
      List<Transaction> transactions,
      List<Budget> budgets,
      List<SavingsGoal> goals,
      UserProfile user,
      Map<String, dynamic> metrics,
      ) {
    final insights = <Map<String, dynamic>>[];
    final currency = user.preferredCurrency;
    final now = DateTime.now();

    // Savings rate insight
    if (metrics['savingsRate'] > 20) {
      insights.add({
        'title': '💰 Super Saver Alert!',
        'body': "{{name}} you're saving ${metrics['savingsRate'].toStringAsFixed(0)}% of your income - that's amazing! Consider investing your surplus.",
        'payload': 'insights',
      });
    } else if (metrics['savingsRate'] > 10) {
      insights.add({
        'title': '📈 Good Savings Momentum',
        'body': "{{name}} you're saving ${metrics['savingsRate'].toStringAsFixed(0)}% of your income. Just a little more to reach the 20% goal!",
        'payload': 'insights',
      });
    } else if (metrics['savingsRate'] > 0) {
      insights.add({
        'title': '💭 Savings Opportunity',
        'body': "{{name}} you're saving ${metrics['savingsRate'].toStringAsFixed(0)}% of your income. Try to increase it by 1% this month!",
        'payload': 'insights',
      });
    }

    // Top category insight
    if (metrics['topCategory'] != 'N/A') {
      insights.add({
        'title': '📊 Your Top Spend',
        'body': "{{name}} you spent ${_formatCurrency(metrics['topCategoryAmount'], currency)} on ${metrics['topCategory']} this month. ${_getCategoryTip(metrics['topCategory'])}",
        'payload': 'insights',
      });
    }

    // Transaction count milestone
    if (metrics['transactionCount'] > 0) {
      final count = metrics['transactionCount'];
      String milestoneMsg;
      if (count >= 500) milestoneMsg = "Legendary tracker! 🏆";
      else if (count >= 100) milestoneMsg = "You're a tracking pro! ⭐";
      else if (count >= 50) milestoneMsg = "Building strong habits! 💪";
      else if (count >= 25) milestoneMsg = "Great consistency! 📈";
      else if (count >= 10) milestoneMsg = "Getting the hang of it! 👍";
      else milestoneMsg = "Every transaction counts! 📝";

      insights.add({
        'title': '📝 Tracking Milestone',
        'body': "{{name}} you've tracked $count transactions so far! $milestoneMsg",
        'payload': 'insights',
      });
    }

    // Budget insight
    if (budgets.isNotEmpty) {
      if (metrics['exceededBudgets'] > 0) {
        insights.add({
          'title': '⚠️ Budget Alert',
          'body': "{{name}} you've exceeded ${metrics['exceededBudgets']} budget${metrics['exceededBudgets'] > 1 ? 's' : ''}. Time to review your spending!",
          'payload': 'budgets',
        });
      } else if (metrics['warningBudgets'] > 0) {
        insights.add({
          'title': '🔔 Budget Watch',
          'body': "{{name}} ${metrics['warningBudgets']} budget${metrics['warningBudgets'] > 1 ? 's are' : ' is'} nearing their limit. Stay vigilant!",
          'payload': 'budgets',
        });
      } else {
        insights.add({
          'title': '🎯 Budget Master',
          'body': "{{name}} you're staying within all your budgets this month! Excellent discipline!",
          'payload': 'budgets',
        });
      }
    }

    // Goal insight
    if (goals.isNotEmpty) {
      if (metrics['completedGoals'] > 0) {
        insights.add({
          'title': '🏆 Goal Crusher!',
          'body': "{{name}} Congratulations! You've completed ${metrics['completedGoals']} goal${metrics['completedGoals'] > 1 ? 's' : ''}! 🎉",
          'payload': 'budgets',
        });
      } else if (metrics['behindGoals'] > 0) {
        insights.add({
          'title': '⏰ Goal Check',
          'body': "{{name}} ${metrics['behindGoals']} goal${metrics['behindGoals'] > 1 ? 's are' : ' is'} behind schedule. Time to catch up!",
          'payload': 'budgets',
        });
      } else {
        insights.add({
          'title': '🎯 On Track with Goals',
          'body': "{{name}} you're ${metrics['totalGoalProgress'].toStringAsFixed(0)}% toward your savings goals overall! Keep it up!",
          'payload': 'budgets',
        });
      }
    }

    // Weekend spending insight
    final weekendSpending = _calculateWeekendSpending(transactions);
    if (weekendSpending > metrics['monthlyExpenses'] * 0.3 && metrics['monthlyExpenses'] > 0) {
      insights.add({
        'title': '🎉 Weekend Warrior',
        'body': "{{name}} ${(weekendSpending / metrics['monthlyExpenses'] * 100).toStringAsFixed(0)}% of your spending happens on weekends. Plan free activities!",
        'payload': 'insights',
      });
    }

    return insights;
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Motivational reminders – with configurable days
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleMotivationalReminders(
      String firstName,
      Map<String, dynamic> metrics, {
        required int days,
      }) async {
    final now = DateTime.now();

    final List<Map<String, String>> motivationalMessages = [
      {'title': '💪 You\'ve got this!', 'body': '{{name}} financial freedom is a journey, not a destination. Keep going!'},
      {'title': '🌟 Financial Star', 'body': '{{name}} you\'re doing amazing! Every tracked expense brings you closer to your goals.'},
      {'title': '🎯 Stay focused', 'body': '{{name}} small daily improvements are the key to staggering long-term results.'},
      {'title': '💰 Wealth Builder', 'body': '{{name}} rich people have small TVs and big libraries. Invest in knowledge!'},
      {'title': '📈 Progress > Perfection', 'body': '{{name}} don\'t let perfect be the enemy of good. Your tracking efforts are paying off!'},
      {'title': '⭐ You\'re ahead!', 'body': '{{name}} most people don\'t track expenses at all. You\'re already winning!'},
      {'title': '🌈 Bright Financial Future', 'body': '{{name}} the best time to start was yesterday. The next best time is now. Keep going!'},
      {'title': '🏆 Champion Mindset', 'body': '{{name}} champions keep playing until they get it right. You\'re a financial champion!'},
      {'title': '💡 Money Wisdom', 'body': '{{name}} it\'s not about how much you make, but how much you keep. Track everything!'},
      {'title': '🚀 Skyrocket Your Savings', 'body': '{{name}} small leaks sink big ships. Plug those small expense leaks today!'},
    ];

    for (int day = 1; day <= days; day++) {
      final message = motivationalMessages[day % motivationalMessages.length];
      final hour = 14 + _random.nextInt(4);
      final minute = _random.nextInt(60);
      final scheduleDate = DateTime(now.year, now.month, now.day, hour, minute).add(Duration(days: day));

      final id = 5000 + day;

      String body = message['body']!.replaceAll('{{name}}', firstName);

      await NotificationService().scheduleOneTimeNotification(
        id: id,
        title: message['title']!,
        body: body + ' ${_getRandomEmoji()}',
        scheduledDate: scheduleDate,
        payload: 'dashboard',
        channelId: 'automatic_channel',
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Helper methods
  // ───────────────────────────────────────────────────────────────────────────
  double _calculateWeekendSpending(List<Transaction> transactions) {
    final now = DateTime.now();
    double total = 0;
    for (var t in transactions.where((t) => t.type == TransactionType.expense && t.date.month == now.month)) {
      if (t.date.weekday == DateTime.saturday || t.date.weekday == DateTime.sunday) {
        total += t.amount;
      }
    }
    return total;
  }

  String _getCategoryTip(String category) {
    final tips = {
      'Food & Dining': 'Try meal prepping to save 40% on food costs!',
      'Transportation': 'Carpool or use public transport to save fuel.',
      'Shopping': 'Apply the 24-hour rule before non-essential purchases.',
      'Entertainment': 'Look for free local events and community activities.',
      'Bills & Utilities': 'Turn off lights and unplug devices when not in use.',
      'Healthcare': 'Prevention is cheaper than cure - stay healthy!',
      'Education': 'Invest in skills - they pay the best interest.',
      'Groceries': 'Shop with a list and never go grocery shopping hungry!',
      'Subscriptions': 'Review and cancel unused subscriptions monthly.',
    };
    return tips[category] ?? 'Track this category closely to optimize spending.';
  }

  String _getRandomEmoji() {
    final emojis = ['💪', '✨', '🌟', '⭐', '🎯', '💰', '💎', '🚀', '💡', '🌈', '🔥', '⚡', '🎉', '🏆', '💫'];
    return emojis[_random.nextInt(emojis.length)];
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Helper: find next occurrence of a given weekday
  // ───────────────────────────────────────────────────────────────────────────
  DateTime _nextWeekday(DateTime from, int targetWeekday) {
    int daysToAdd = (targetWeekday - from.weekday) % 7;
    if (daysToAdd <= 0) daysToAdd += 7;
    return DateTime(from.year, from.month, from.day, 10, 0).add(Duration(days: daysToAdd));
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  Helper: format currency
  // ───────────────────────────────────────────────────────────────────────────
  String _formatCurrency(double amount, Currency currency) {
    final symbol = currency.symbol;

    if (amount >= 10000000) {
      return '$symbol${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '$symbol${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '$symbol${amount.toStringAsFixed(0)}';
  }
}