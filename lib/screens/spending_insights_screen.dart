import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../models/transaction.dart';
import '../models/user_model.dart';
import '../models/budget.dart';
import '../services/storage_service.dart';
import '../services/category_service.dart';
import '../services/personality_service.dart';
import '../widgets/main_layout.dart';
import '../widgets/currency_formatter.dart';
import '../providers/theme_provider.dart';

class SpendingInsightsScreen extends StatefulWidget {
  const SpendingInsightsScreen({Key? key}) : super(key: key);

  @override
  State<SpendingInsightsScreen> createState() => _SpendingInsightsScreenState();
}

class _SpendingInsightsScreenState extends State<SpendingInsightsScreen> with SingleTickerProviderStateMixin {
  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];
  List<SavingsGoal> _goals = [];
  UserProfile? _user;
  List<Category> _categories = []; // Add categories list
  bool _isLoading = true;
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = await StorageService.getUser();
      final transactions = await StorageService.getTransactions();
      final budgets = await StorageService.getBudgets();
      final goals = await StorageService.getSavingsGoals();
      final categories = await StorageService.getCategories(); // Load categories

      setState(() {
        _user = user;
        _transactions = transactions;
        _budgets = budgets;
        _goals = goals;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  // Get current month transactions
  List<Transaction> get _currentMonthTransactions {
    final now = DateTime.now();
    return _transactions.where((t) =>
    t.date.month == now.month &&
        t.date.year == now.year &&
        t.type == TransactionType.expense
    ).toList();
  }

  // Get all time expenses
  List<Transaction> get _allExpenses {
    return _transactions.where((t) => t.type == TransactionType.expense).toList();
  }

  // Get current month income
  List<Transaction> get _currentMonthIncome {
    final now = DateTime.now();
    return _transactions.where((t) =>
    t.date.month == now.month &&
        t.date.year == now.year &&
        t.type == TransactionType.income
    ).toList();
  }

  // Calculate daily spending for last 30 days
  Map<DateTime, double> get _dailySpending {
    final Map<DateTime, double> daily = {};
    final now = DateTime.now();

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      daily[startOfDay] = 0.0;
    }

    for (var t in _allExpenses) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      if (daily.containsKey(day)) {
        daily[day] = (daily[day] ?? 0.0) + t.amount;
      }
    }

    return daily;
  }

  // Calculate category breakdown
  Map<String, double> get _categoryBreakdown {
    final Map<String, double> categories = {};
    for (var t in _currentMonthTransactions) {
      categories[t.category] = (categories[t.category] ?? 0.0) + t.amount;
    }
    var sortedEntries = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries);
  }

  // Get top spending days
  List<MapEntry<DateTime, double>> get _topSpendingDays {
    final daily = _dailySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return daily.take(5).toList();
  }

  // Get most frequent categories
  Map<String, int> get _categoryFrequency {
    final Map<String, int> frequency = {};
    for (var t in _currentMonthTransactions) {
      frequency[t.category] = (frequency[t.category] ?? 0) + 1;
    }
    var sortedEntries = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries);
  }

  // Calculate weekday patterns
  Map<String, double> get _weekdaySpending {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final Map<String, double> spending = {};
    final Map<String, int> counts = {};

    for (var day in weekdays) {
      spending[day] = 0.0;
      counts[day] = 0;
    }

    for (var t in _allExpenses) {
      final weekday = DateFormat('E').format(t.date);
      spending[weekday] = (spending[weekday] ?? 0.0) + t.amount;
      counts[weekday] = (counts[weekday] ?? 0) + 1;
    }

    // Calculate averages
    final Map<String, double> averages = {};
    weekdays.forEach((day) {
      if (counts[day]! > 0) {
        averages[day] = spending[day]! / counts[day]!;
      } else {
        averages[day] = 0.0;
      }
    });

    return averages;
  }

  // Get user's spending personality type using the same service for consistency
  String _getSpendingPersonality() {
    final monthlyIncome = _currentMonthIncome.fold(0.0, (sum, t) => sum + t.amount);
    final monthlyExpenses = _currentMonthTransactions.fold(0.0, (sum, t) => sum + t.amount);

    final analysis = PersonalityService.analyzeSpendingPersonality(
      transactions: _transactions,
      budgets: _budgets,
      goals: _goals,
      monthlyIncome: monthlyIncome,
      monthlyExpenses: monthlyExpenses,
      totalBalance: 0,
      currency: _user?.preferredCurrency,
    );

    return analysis['primary'];
  }

  // Generate intelligent spending suggestions based on user behavior
  List<Map<String, dynamic>> get _suggestions {
    final suggestions = <Map<String, dynamic>>[];
    final expenses = _currentMonthTransactions;
    final income = _currentMonthIncome;
    final totalSpent = expenses.fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = income.fold(0.0, (sum, t) => sum + t.amount);
    final transactionCount = expenses.length;
    final avgPerTransaction = transactionCount > 0 ? totalSpent / transactionCount : 0;
    final personality = _getSpendingPersonality();

    // 1. Budget-related suggestions (Priority: High)
    for (var budget in _budgets) {
      if (budget.isExceeded) {
        suggestions.add({
          'type': 'critical',
          'priority': 1,
          'title': 'Budget Breach Alert',
          'message': 'You\'ve exceeded your ${budget.category} budget by ${CurrencyFormatter.format(budget.spent - budget.limit, _user?.preferredCurrency ?? Currency.npr)}. Consider reallocating funds from other categories.',
          'icon': Icons.warning_amber_rounded,
          'color': AppColors.error,
          'action': 'Review Budget',
        });
      } else if (budget.isWarning) {
        suggestions.add({
          'type': 'warning',
          'priority': 2,
          'title': 'Nearing ${budget.category} Limit',
          'message': 'Only ${CurrencyFormatter.format(budget.remaining, _user?.preferredCurrency ?? Currency.npr)} left in your ${budget.category} budget. You have ${(budget.endDate.difference(DateTime.now()).inDays)} days remaining.',
          'icon': Icons.info_outline,
          'color': AppColors.warning,
          'action': 'View Budget',
        });
      }
    }

    // 2. Income-to-Spending Ratio Analysis
    if (totalIncome > 0) {
      final savingsRate = ((totalIncome - totalSpent) / totalIncome * 100).clamp(0, 100);
      if (savingsRate < 10) {
        suggestions.add({
          'type': 'insight',
          'priority': 3,
          'title': 'Low Savings Rate',
          'message': 'You\'re saving only ${savingsRate.toStringAsFixed(1)}% of your income. Financial experts recommend saving at least 20%. Try reducing non-essential expenses.',
          'icon': Icons.trending_down,
          'color': Colors.orange,
          'action': 'View Tips',
        });
      } else if (savingsRate > 30) {
        suggestions.add({
          'type': 'positive',
          'priority': 4,
          'title': 'Great Saving Habits',
          'message': 'You\'re saving ${savingsRate.toStringAsFixed(1)}% of your income. Consider investing your savings in high-yield options or accelerating debt payments.',
          'icon': Icons.emoji_events,
          'color': AppColors.success,
          'action': 'Explore Investments',
        });
      }
    }

    // 3. Category-specific insights based on spending patterns
    if (_categoryBreakdown.isNotEmpty) {
      final topCategory = _categoryBreakdown.entries.first;
      final topPercentage = (topCategory.value / totalSpent * 100);

      if (topPercentage > 40) {
        suggestions.add({
          'type': 'insight',
          'priority': 5,
          'title': 'High Category Concentration',
          'message': '${topCategory.key} accounts for ${topPercentage.toStringAsFixed(1)}% of your spending. Consider diversifying to reduce financial risk.',
          'icon': Icons.pie_chart,
          'color': AppColors.primaryBlue,
          'action': 'Analyze',
        });
      }
    }

    // 4. Dining out frequency analysis
    final diningTransactions = expenses.where((t) =>
    t.category.contains('Food') || t.category.contains('Dining')).length;
    if (diningTransactions > 15) {
      final diningAmount = expenses.where((t) =>
      t.category.contains('Food') || t.category.contains('Dining'))
          .fold(0.0, (sum, t) => sum + t.amount);
      suggestions.add({
        'type': 'tip',
        'priority': 6,
        'title': 'Dining Out Pattern Detected',
        'message': 'You\'ve spent ${CurrencyFormatter.format(diningAmount, _user?.preferredCurrency ?? Currency.npr)} on dining out this month. Meal prepping could save you up to 40% on food costs.',
        'icon': Icons.restaurant,
        'color': Colors.orange,
        'action': 'Meal Prep Ideas',
      });
    }

    // 5. Shopping addiction check
    final shoppingAmount = expenses.where((t) =>
        t.category.contains('Shopping')).fold(0.0, (sum, t) => sum + t.amount);
    if (shoppingAmount > totalSpent * 0.3) {
      suggestions.add({
        'type': 'warning',
        'priority': 7,
        'title': 'High Shopping Spend',
        'message': 'Shopping is ${((shoppingAmount / totalSpent) * 100).toStringAsFixed(1)}% of your expenses. Try the 30-day rule before non-essential purchases.',
        'icon': Icons.shopping_bag,
        'color': AppColors.warning,
        'action': 'Learn More',
      });
    }

    // 6. Entertainment vs. Necessities
    final entertainmentAmount = expenses.where((t) =>
        t.category.contains('Entertainment')).fold(0.0, (sum, t) => sum + t.amount);
    if (entertainmentAmount > totalSpent * 0.2) {
      suggestions.add({
        'type': 'insight',
        'priority': 8,
        'title': 'Entertainment Focus',
        'message': 'Entertainment is ${((entertainmentAmount / totalSpent) * 100).toStringAsFixed(1)}% of your spend. Look for free local events or bundle subscriptions.',
        'icon': Icons.movie,
        'color': Colors.purple,
        'action': 'Find Alternatives',
      });
    }

    // 7. Small transactions analysis
    final smallTransactions = expenses.where((t) => t.amount < 500).length;
    final smallAmount = expenses.where((t) => t.amount < 500)
        .fold(0.0, (sum, t) => sum + t.amount);
    if (smallTransactions > 15) {
      suggestions.add({
        'type': 'tip',
        'priority': 9,
        'title': 'Small Transaction Impact',
        'message': '$smallTransactions small transactions total ${CurrencyFormatter.format(smallAmount, _user?.preferredCurrency ?? Currency.npr)}. Reducing these by 20% could save significantly.',
        'icon': Icons.receipt,
        'color': AppColors.accentTeal,
        'action': 'Track Small Spends',
      });
    }

    // 8. Weekend spending analysis
    final weekendSpending = _getWeekendSpending();
    if (weekendSpending > totalSpent * 0.35) {
      suggestions.add({
        'type': 'insight',
        'priority': 10,
        'title': 'Weekend Warrior',
        'message': '${((weekendSpending / totalSpent) * 100).toStringAsFixed(1)}% of spending happens on weekends. Plan free activities to balance.',
        'icon': Icons.weekend,
        'color': AppColors.primaryBlue,
        'action': 'Weekend Ideas',
      });
    }

    // 9. Goals-related suggestions
    if (_goals.isNotEmpty) {
      final goalsBehind = _goals.where((g) => g.isBehind).length;
      if (goalsBehind > 0) {
        final nearestGoal = _goals.where((g) => g.isBehind).first;
        suggestions.add({
          'type': 'goal',
          'priority': 11,
          'title': 'Goal Progress Alert',
          'message': 'Your "${nearestGoal.name}" goal is behind. Need ${CurrencyFormatter.format(nearestGoal.requiredDaily, _user?.preferredCurrency ?? Currency.npr)}/day to catch up.',
          'icon': Icons.flag,
          'color': AppColors.warning,
          'action': 'Adjust Goal',
        });
      }
    }

    // 10. Subscription detection
    final subscriptionCandidates = expenses.where((t) =>
    t.amount < 2000 && t.amount > 100 &&
        (t.note.toLowerCase().contains('netflix') ||
            t.note.toLowerCase().contains('spotify') ||
            t.note.toLowerCase().contains('amazon') ||
            t.note.toLowerCase().contains('subscription'))).length;
    if (subscriptionCandidates > 3) {
      suggestions.add({
        'type': 'tip',
        'priority': 12,
        'title': 'Subscription Audit',
        'message': 'You have $subscriptionCandidates potential subscriptions. Reviewing them could save you thousands annually.',
        'icon': Icons.subscriptions,
        'color': Colors.teal,
        'action': 'Audit Now',
      });
    }

    // Sort suggestions by priority
    suggestions.sort((a, b) => (a['priority'] ?? 999).compareTo(b['priority'] ?? 999));

    // Add personality-based tip at the end if few suggestions
    if (suggestions.length < 3) {
      switch (personality) {
        case 'The Saver':
          suggestions.add({
            'type': 'personality',
            'priority': 13,
            'title': 'Saver Insight',
            'message': 'You\'re doing great at saving! Consider automating your investments for better returns.',
            'icon': Icons.savings,
            'color': Colors.green,
            'action': 'Learn More',
          });
          break;
        case 'The Planner':
          suggestions.add({
            'type': 'personality',
            'priority': 13,
            'title': 'Planner Tip',
            'message': 'Your planning skills are excellent. Try quarterly budget reviews to optimize further.',
            'icon': Icons.assignment_turned_in,
            'color': AppColors.primaryBlue,
            'action': 'Review',
          });
          break;
        case 'The Investor':
          suggestions.add({
            'type': 'personality',
            'priority': 13,
            'title': 'Investor Advice',
            'message': 'Consider diversifying your investments across different asset classes.',
            'icon': Icons.trending_up,
            'color': Colors.purple,
            'action': 'Explore',
          });
          break;
        case 'The Minimalist':
          suggestions.add({
            'type': 'personality',
            'priority': 13,
            'title': 'Minimalist Wisdom',
            'message': 'Your minimalist approach is saving you money. Focus on experiences over things!',
            'icon': Icons.spa,
            'color': Colors.teal,
            'action': 'Tips',
          });
          break;
        case 'The Enthusiast':
          suggestions.add({
            'type': 'personality',
            'priority': 13,
            'title': 'Enthusiast Tip',
            'message': 'Your energy is great! Try the 24-hour rule before larger purchases.',
            'icon': Icons.whatshot,
            'color': Colors.orange,
            'action': 'Try It',
          });
          break;
        default:
          suggestions.add({
            'type': 'personality',
            'priority': 13,
            'title': 'Smart Money Tip',
            'message': 'Set up automatic transfers to savings on payday. You won\'t miss what you don\'t see!',
            'icon': Icons.auto_awesome,
            'color': AppColors.primaryBlue,
            'action': 'Set Up',
          });
      }
    }

    return suggestions;
  }

  // Generate dynamic pro tips based on user's financial situation
  List<String> get _dynamicProTips {
    final tips = <String>[];
    final expenses = _currentMonthTransactions;
    final income = _currentMonthIncome;
    final totalSpent = expenses.fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = income.fold(0.0, (sum, t) => sum + t.amount);
    final savings = totalIncome - totalSpent;
    final hasGoals = _goals.isNotEmpty;
    final hasBudgets = _budgets.isNotEmpty;

    // Income-based tips
    if (totalIncome > 0) {
      final savingsRate = savings / totalIncome * 100;
      if (savingsRate < 20) {
        tips.add("Try the 50/30/20 rule: 50% needs, 30% wants, 20% savings. You're currently saving ${savingsRate.toStringAsFixed(1)}%.");
      } else {
        tips.add("Great job saving ${savingsRate.toStringAsFixed(1)}%! Consider investing in tax-advantaged accounts.");
      }
    }

    // Goals-based tips
    if (hasGoals) {
      final behindGoals = _goals.where((g) => g.isBehind).length;
      if (behindGoals > 0) {
        tips.add("Break large goals into smaller milestones. Celebrating small wins keeps you motivated!");
      } else {
        tips.add("You're on track with all goals! Consider adding a new savings goal for something exciting.");
      }
    }

    // Budget-based tips
    if (hasBudgets) {
      final exceeded = _budgets.where((b) => b.isExceeded).length;
      if (exceeded > 0) {
        tips.add("Review exceeded budgets monthly. Sometimes budgets need adjustment, not restriction.");
      } else {
        tips.add("Track daily expenses to stay within budgets. Small awareness prevents big surprises.");
      }
    }

    // Transaction-based tips
    if (expenses.isNotEmpty) {
      final avgTransaction = totalSpent / expenses.length;
      if (avgTransaction > 5000) {
        tips.add("Your average transaction is high. Track big purchases carefully - they add up quickly!");
      } else if (avgTransaction < 500) {
        tips.add("Many small transactions. Consider carrying less cash/card to reduce impulse buys.");
      }
    }

    // Add general tips if we have fewer than 3
    if (tips.length < 3) {
      tips.addAll([
        "Review subscriptions monthly. You might find services you no longer use.",
        "Use cash for discretionary spending. It's proven to reduce spending by up to 30%.",
        "Set specific financial goals. 'Save more' is vague, but 'save for vacation' is actionable.",
      ]);
    }

    return tips.take(4).toList();
  }

  double _getWeekendSpending() {
    double weekendTotal = 0.0;
    for (var t in _currentMonthTransactions) {
      final weekday = t.date.weekday;
      if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
        weekendTotal += t.amount;
      }
    }
    return weekendTotal;
  }

  // Helper to get secondary color based on primary
  Color _getSecondaryColor(Color primary) {
    if (primary == const Color(0xFF007AFF)) return const Color(0xFF00C1D4);
    if (primary == const Color(0xFF34C759)) return const Color(0xFF74C69D);
    if (primary == const Color(0xFFAF52DE)) return const Color(0xFFD291FF);
    if (primary == const Color(0xFF1C1C1E)) return const Color(0xFF3A3A3C);
    return const Color(0xFF00C1D4);
  }

  // Helper method to get category icon from stored categories
  String _getCategoryIcon(String categoryName) {
    try {
      final category = _categories.firstWhere(
            (c) => c.name == categoryName,
        orElse: () => Category(
          id: 'temp',
          name: categoryName,
          icon: '📦',
          color: '#6C757D',
          type: TransactionType.expense,
          isDefault: false,
        ),
      );
      return category.icon;
    } catch (e) {
      return '📦';
    }
  }

  // Helper method to get category icon widget (supports emojis)
  Widget _getCategoryIconWidget(String categoryName) {
    // Common predefined categories with their emojis as fallback
    const Map<String, String> predefinedIcons = {
      'Food & Dining': '🍔',
      'Shopping': '🛍️',
      'Transportation': '🚗',
      'Entertainment': '🎬',
      'Bills & Utilities': '📱',
      'Healthcare': '🏥',
      'Education': '📚',
      'Travel': '✈️',
      'Groceries': '🛒',
      'Income': '💰',
      'Investment': '📈',
      'Savings': '🏦',
      'Rent': '🏠',
      'Salary': '💼',
      'Business': '💼',
      'Freelance': '💻',
      'Gift': '🎁',
      'Charity': '🤝',
      'Insurance': '🛡️',
      'Tax': '📊',
      'Pets': '🐾',
      'Fitness': '💪',
      'Beauty': '💄',
      'Clothing': '👕',
      'Electronics': '📱',
      'Home': '🏠',
      'Garden': '🌱',
      'Coffee': '☕',
      'Fast Food': '🍟',
      'Alcohol': '🍷',
      'Dating': '💕',
      'Kids': '👶',
      'Sports': '⚽',
      'Hobbies': '🎨',
      'Subscriptions': '📺',
      'Software': '💻',
      'Cloud': '☁️',
      'Other': '📦',
    };

    // First try to get from stored categories
    try {
      final category = _categories.firstWhere(
            (c) => c.name == categoryName,
        orElse: () => Category(
          id: 'temp',
          name: categoryName,
          icon: predefinedIcons[categoryName] ?? '📦',
          color: '#6C757D',
          type: TransactionType.expense,
          isDefault: false,
        ),
      );

      // If we found a category with an icon, return it
      if (category.icon.isNotEmpty) {
        // Check if the icon is an emoji (by checking if it's a single character or emoji)
        if (category.icon.length <= 2) { // Most emojis are 1-2 characters
          return Text(
            category.icon,
            style: const TextStyle(fontSize: 20),
          );
        }
      }
    } catch (e) {
      // Fall through to predefined or fallback
    }

    // Check if it's a predefined category
    if (predefinedIcons.containsKey(categoryName)) {
      return Text(
        predefinedIcons[categoryName]!,
        style: const TextStyle(fontSize: 20),
      );
    }

    // Check if category name starts with an emoji (for custom categories)
    if (categoryName.isNotEmpty) {
      // Emojis typically have code units > 0xFFFF or are in specific ranges
      final firstChar = categoryName.codeUnitAt(0);
      final isEmoji = firstChar > 0xFFFF ||
          (firstChar >= 0x1F300 && firstChar <= 0x1F9FF) ||
          (firstChar >= 0x2600 && firstChar <= 0x26FF) || // Misc symbols
          (firstChar >= 0x2700 && firstChar <= 0x27BF); // Dingbats

      if (isEmoji) {
        // Return the first character (which should be the emoji)
        return Text(
          String.fromCharCode(firstChar),
          style: const TextStyle(fontSize: 20),
        );
      }
    }

    // Final fallback to CategoryService
    return Text(
      CategoryService.getCategoryIcon(categoryName),
      style: const TextStyle(fontSize: 20),
    );
  }

  // Helper method to get category color from stored categories
  Color _getCategoryColor(String categoryName) {
    try {
      final category = _categories.firstWhere(
            (c) => c.name == categoryName,
        orElse: () => Category(
          id: 'temp',
          name: categoryName,
          icon: '📦',
          color: '#6C757D',
          type: TransactionType.expense,
          isDefault: false,
        ),
      );
      return Color(int.parse(category.color.replaceFirst('#', '0xff')));
    } catch (e) {
      return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.lightGray,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final currency = _user?.preferredCurrency ?? Currency.npr;
    final totalSpent = _currentMonthTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = _currentMonthIncome.fold(0.0, (sum, t) => sum + t.amount);
    final avgDaily = totalSpent / DateTime.now().day;
    final categoryData = _categoryBreakdown;
    final topDays = _topSpendingDays;
    final frequentCategories = _categoryFrequency;
    final weekdayAverages = _weekdaySpending;
    final suggestions = _suggestions;
    final personality = _getSpendingPersonality();

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 190,
              pinned: true,
              floating: true,
              backgroundColor: themeProvider.primaryColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 65),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Spending Insights',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            personality.replaceFirst('The ', ''),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.amber,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [themeProvider.primaryColor, _getSecondaryColor(themeProvider.primaryColor)],
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.6),
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 13),
                tabs: const [
                  Tab(text: 'Overview', icon: Icon(Icons.pie_chart, size: 18)),
                  Tab(text: 'Patterns', icon: Icon(Icons.timeline, size: 18)),
                  Tab(text: 'Suggestions', icon: Icon(Icons.lightbulb, size: 18)),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Overview Tab
            _buildOverviewTab(currency, totalSpent, avgDaily, categoryData, topDays, totalIncome, themeProvider),

            // Patterns Tab
            _buildPatternsTab(currency, weekdayAverages, frequentCategories, themeProvider),

            // Suggestions Tab
            _buildSuggestionsTab(currency, suggestions, themeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(Currency currency, double totalSpent, double avgDaily,
      Map<String, double> categoryData, List<MapEntry<DateTime, double>> topDays,
      double totalIncome, ThemeProvider themeProvider) {
    final savings = totalIncome - totalSpent;
    final savingsRate = totalIncome > 0 ? (savings / totalIncome * 100) : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Spent',
                  CurrencyFormatter.format(totalSpent, currency),
                  Icons.account_balance_wallet,
                  themeProvider.primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryCard(
                  'Daily Avg',
                  CurrencyFormatter.format(avgDaily, currency),
                  Icons.calendar_today,
                  _getSecondaryColor(themeProvider.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Monthly Savings',
                  CurrencyFormatter.format(savings, currency),
                  Icons.savings,
                  savings >= 0 ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryCard(
                  'Savings Rate',
                  '${savingsRate.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  savingsRate >= 20 ? AppColors.success : savingsRate >= 10 ? AppColors.warning : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Category Breakdown
          Text(
            'Category Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          if (categoryData.isEmpty)
            _buildEmptyState('No spending data for this month')
          else
            ...categoryData.entries.take(5).map((entry) {
              final percentage = (entry.value / totalSpent * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getCategoryColor(entry.key),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          CurrencyFormatter.format(entry.value, currency),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getCategoryColor(entry.key),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

          const SizedBox(height: 24),

          // Top Spending Days
          Text(
            'Top Spending Days',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          if (topDays.isEmpty)
            _buildEmptyState('No spending data available')
          else
            ...topDays.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, MMMM d').format(entry.key),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(entry.value, currency),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildPatternsTab(Currency currency, Map<String, double> weekdayAverages,
      Map<String, int> frequentCategories, ThemeProvider themeProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekday Pattern Chart
          Text(
            'Weekday Spending Pattern',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: weekdayAverages.values.fold(0.0, (max, value) => math.max(max, value)) * 1.2,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            '${currency.symbol}${(value / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(fontSize: 9, color: AppColors.textLight),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Text(
                            days[value.toInt()],
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: themeProvider.primaryColor),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(weekdayAverages.length, (index) {
                  final day = weekdayAverages.keys.elementAt(index);
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: weekdayAverages[day]!,
                        color: index >= 5 ? AppColors.warning : themeProvider.primaryColor,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Most Frequent Categories (FIXED: Now supports custom emojis)
          Text(
            'Most Frequent Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          if (frequentCategories.isEmpty)
            _buildEmptyState('No frequent spending data')
          else
            ...frequentCategories.entries.take(5).map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(entry.key).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: _getCategoryIconWidget(entry.key), // FIXED: Use custom icon widget
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Frequency: ${entry.value} times',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildSuggestionsTab(Currency currency, List<Map<String, dynamic>> suggestions, ThemeProvider themeProvider) {
    final dynamicTips = _dynamicProTips;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Smart Suggestions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Personalized based on your spending patterns',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Suggestions List
          ...suggestions.take(5).map((suggestion) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${suggestion['action']} feature coming soon!'),
                        backgroundColor: suggestion['color'],
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: suggestion['color'].withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: suggestion['color'].withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: suggestion['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            suggestion['icon'],
                            color: suggestion['color'],
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                suggestion['title'],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: suggestion['color'],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                suggestion['message'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: suggestion['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  suggestion['action'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: suggestion['color'],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 24),

          // Dynamic Pro Tips Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themeProvider.primaryColor.withOpacity(0.1),
                  _getSecondaryColor(themeProvider.primaryColor).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeProvider.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.tips_and_updates,
                        color: themeProvider.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Pro Tips',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...dynamicTips.map((tip) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tip,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox,
              size: 48,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }


}