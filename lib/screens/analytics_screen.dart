import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../services/storage_service.dart';
import '../models/transaction.dart' show Category;
import '../services/category_service.dart';
import '../widgets/main_layout.dart';
import '../models/transaction.dart';
import '../models/user_model.dart';
import '../models/budget.dart';
import '../providers/theme_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  List<Transaction> _transactions = [];
  List<SavingsGoal> _savingsGoals = [];
  List<Budget> _budgets = [];
  List<Category> _categories = [];
  UserProfile? _user;
  bool _isLoading = true;

  final List<Color> _fallbackColors = [
    const Color(0xFF4361EE),
    const Color(0xFF06D6A0),
    const Color(0xFFEF476F),
    const Color(0xFFFFB703),
    const Color(0xFF8338EC),
    const Color(0xFFFB5607),
    const Color(0xFF3A86FF),
    const Color(0xFF52B788),
    const Color(0xFFE63946),
    const Color(0xFFA2D2FF),
    const Color(0xFFB5838D),
    const Color(0xFFFF99C8),
    const Color(0xFFAACC00),
    const Color(0xFF9C89B8),
    const Color(0xFFF48C06),
    const Color(0xFF2D6A4F),
    const Color(0xFFD62828),
    const Color(0xFF1E6091),
    const Color(0xFFD4A373),
    const Color(0xFFB56576),
  ];

  // Add these color palettes after your existing _fallbackColors
  final List<Color> _expenseColors = [
    const Color(0xFFFF6B6B), // Coral Red
    const Color(0xFFEF476F), // Pink
    const Color(0xFFE63946), // Bright Red
    const Color(0xFFD62828), // Crimson
    const Color(0xFFB23B3B), // Brick Red
    const Color(0xFFFFB703), // Amber
    const Color(0xFFFB5607), // Orange
    const Color(0xFFF48C06), // Golden Orange
    const Color(0xFFFFA07A), // Light Salmon
    const Color(0xFFFF99C8), // Pink
    const Color(0xFFB5838D), // Mauve
    const Color(0xFFB56576), // Dusty Rose
    const Color(0xFF6D6875), // Purple Gray
    const Color(0xFF9C89B8), // Lavender
    const Color(0xFF8338EC), // Purple
    const Color(0xFF3A86FF), // Blue
    const Color(0xFF4361EE), // Royal Blue
    const Color(0xFF4ECDC4), // Teal
    const Color(0xFF06D6A0), // Mint
    const Color(0xFF52B788), // Green
  ];

  final List<Color> _incomeColors = [
    const Color(0xFF52B788), // Sage Green
    const Color(0xFF74C69D), // Light Green
    const Color(0xFF95D5B2), // Mint Green
    const Color(0xFFB7E4C7), // Pale Green
    const Color(0xFFA7C957), // Lime Green
    const Color(0xFF40916C), // Forest Green
    const Color(0xFF2D6A4F), // Deep Green
    const Color(0xFF1E6091), // Navy Blue
    const Color(0xFF3A86FF), // Blue
    const Color(0xFF4361EE), // Royal Blue
    const Color(0xFF06D6A0), // Teal
    const Color(0xFF4ECDC4), // Light Teal
    const Color(0xFF9C89B8), // Lavender
    const Color(0xFFB5838D), // Mauve
    const Color(0xFFFF99C8), // Pink
    const Color(0xFFFB5607), // Orange
    const Color(0xFFFFB703), // Amber
    const Color(0xFFF48C06), // Golden
    const Color(0xFFA2D2FF), // Light Blue
    const Color(0xFFB56576), // Dusty Rose
  ];


  late TabController _tabController;

  // Filter states
  String _overviewFilter = 'all';
  String _cashFlowFilter = 'week';
  String _periodFilter = 'week';
  String _distributionFilter = 'all';
  String _savingsFilter = 'week';
  String _budgetFilter = 'month';
  String _goalsFilter = 'month';

  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Pie chart touch state
  int? _touchedExpensePieIndex;
  int? _touchedIncomePieIndex;

  // Selected pie chart section data
  Map<String, dynamic>? _selectedExpenseSection;
  Map<String, dynamic>? _selectedIncomeSection;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);

    // Check if there are arguments passed to select a specific tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments != null && arguments is Map && arguments.containsKey('tab')) {
        final tabName = arguments['tab'] as String;
        _selectTabByName(tabName);
      }
    });

    _loadData();
  }

  // Helper method to select tab by name
  void _selectTabByName(String tabName) {
    switch (tabName) {
      case 'savings':
        _tabController.animateTo(4); // Savings tab is index 4
        break;
      case 'budget':
        _tabController.animateTo(5); // Budget tab is index 5
        break;
      case 'goals':
        _tabController.animateTo(6); // Goals tab is index 6
        break;
      case 'overview':
        _tabController.animateTo(0);
        break;
      case 'cashflow':
        _tabController.animateTo(1);
        break;
      case 'period':
        _tabController.animateTo(2);
        break;
      case 'distribution':
        _tabController.animateTo(3);
        break;
      default:
        break;
    }
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
      final savingsGoals = await StorageService.getSavingsGoals();
      final budgets = await StorageService.getBudgets();
      final categories = await StorageService.getCategories();

      setState(() {
        _user = user;
        _transactions = transactions;
        _savingsGoals = savingsGoals;
        _budgets = budgets;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  // Helper method to get category emoji from stored categories
  String _getCategoryEmoji(String categoryName) {
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
      // Fallback to hash-based color
      int hash = categoryName.hashCode.abs();
      return _fallbackColors[hash % _fallbackColors.length];
    }
  }

  // Helper to get secondary color
  Color _getSecondaryColor(Color primary) {
    if (primary == const Color(0xFF007AFF)) return const Color(0xFF00C1D4);
    if (primary == const Color(0xFF34C759)) return const Color(0xFF74C69D);
    if (primary == const Color(0xFFAF52DE)) return const Color(0xFFD291FF);
    if (primary == const Color(0xFF1C1C1E)) return const Color(0xFF3A3A3C);
    return const Color(0xFF00C1D4);
  }

  // ==================== FILTERING METHODS ====================

  List<Transaction> _filterTransactions(String filter, {DateTime? start, DateTime? end}) {
    final now = DateTime.now();

    if (start != null && end != null) {
      return _transactions.where((t) =>
      t.date.isAfter(start) && t.date.isBefore(end.add(const Duration(days: 1)))
      ).toList();
    }

    switch (filter) {
      case 'week':
        return _transactions.where((t) => t.date.isAfter(now.subtract(const Duration(days: 7)))).toList();
      case 'month':
        return _transactions.where((t) => t.date.month == now.month && t.date.year == now.year).toList();
      case '3months':
        return _transactions.where((t) => t.date.isAfter(now.subtract(const Duration(days: 90)))).toList();
      case '6months':
        return _transactions.where((t) => t.date.isAfter(now.subtract(const Duration(days: 180)))).toList();
      case 'year':
        return _transactions.where((t) => t.date.isAfter(now.subtract(const Duration(days: 365)))).toList();
      case 'all':
      default:
        return _transactions;
    }
  }

  // ==================== DATA AGGREGATION ====================

  Map<String, double> _getCategoryBreakdown(List<Transaction> transactions) {
    final Map<String, double> categories = {};
    for (var t in transactions.where((t) => t.type == TransactionType.expense)) {
      categories[t.category] = (categories[t.category] ?? 0) + t.amount;
    }
    final sorted = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  Map<String, double> _getIncomeBreakdown(List<Transaction> transactions) {
    final Map<String, double> categories = {};
    for (var t in transactions.where((t) => t.type == TransactionType.income)) {
      categories[t.category] = (categories[t.category] ?? 0) + t.amount;
    }
    final sorted = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  // Enhanced daily data with proper interval handling for labels
  Map<DateTime, double> _getDailyIncome(List<Transaction> transactions, String filter) {
    final Map<DateTime, double> daily = {};
    final now = DateTime.now();

    int days = _getDaysFromFilter(filter);

    // Create all days in range
    for (int i = 0; i <= days; i++) {
      final date = now.subtract(Duration(days: days - i));
      final day = DateTime(date.year, date.month, date.day);
      daily[day] = 0.0;
    }

    // Aggregate actual data
    for (var t in transactions.where((t) => t.type == TransactionType.income)) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      if (t.date.isAfter(now.subtract(Duration(days: days)))) {
        daily[day] = (daily[day] ?? 0) + t.amount;
      }
    }
    return daily;
  }

  Map<DateTime, double> _getDailyExpense(List<Transaction> transactions, String filter) {
    final Map<DateTime, double> daily = {};
    final now = DateTime.now();

    int days = _getDaysFromFilter(filter);

    for (int i = 0; i <= days; i++) {
      final date = now.subtract(Duration(days: days - i));
      final day = DateTime(date.year, date.month, date.day);
      daily[day] = 0.0;
    }

    for (var t in transactions.where((t) => t.type == TransactionType.expense)) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      if (t.date.isAfter(now.subtract(Duration(days: days)))) {
        daily[day] = (daily[day] ?? 0) + t.amount;
      }
    }
    return daily;
  }

  int _getDaysFromFilter(String filter) {
    switch (filter) {
      case 'week':
        return 7;
      case 'month':
        return 30;
      case '3months':
        return 90;
      case '6months':
        return 180;
      case 'year':
        return 365;
      default:
        return 7;
    }
  }

  // Calculate label interval for showing only 7 labels
  int _getLabelInterval(int totalDays) {
    if (totalDays <= 7) return 1;
    return (totalDays / 7).ceil();
  }

  Map<String, Map<String, double>> _getMonthlyData(List<Transaction> transactions, int months) {
    final Map<String, Map<String, double>> result = {};
    final now = DateTime.now();

    for (int i = months - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('MMM yyyy').format(date);
      result[key] = {'income': 0.0, 'expense': 0.0};
    }

    for (var t in transactions) {
      final key = DateFormat('MMM yyyy').format(t.date);
      if (result.containsKey(key)) {
        if (t.type == TransactionType.income) {
          result[key]!['income'] = (result[key]!['income'] ?? 0) + t.amount;
        } else {
          result[key]!['expense'] = (result[key]!['expense'] ?? 0) + t.amount;
        }
      }
    }
    return result;
  }

  // Get weekly data for month view
  List<Map<String, dynamic>> _getWeeklyData(List<Transaction> transactions) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);

    final List<Map<String, dynamic>> weeklyData = [];

    for (int week = 0; week < 4; week++) {
      final weekStart = firstDay.add(Duration(days: week * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));

      if (weekStart.isAfter(lastDay)) break;

      final weekTransactions = transactions.where((t) =>
      t.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          t.date.isBefore(weekEnd.add(const Duration(days: 1)))
      ).toList();

      final income = weekTransactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (s, t) => s + t.amount);

      final expense = weekTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (s, t) => s + t.amount);

      weeklyData.add({
        'month': 'Week ${week + 1}',
        'income': income,
        'expense': expense,
        'savings': income - expense,
        'savingsRate': income > 0 ? ((income - expense) / income * 100) : 0,
      });
    }

    return weeklyData;
  }

  List<Map<String, dynamic>> _getSavingsTrend(List<Transaction> transactions, int months) {
    final List<Map<String, dynamic>> trend = [];
    final now = DateTime.now();

    if (months == 1) {
      // Return weekly data for month view
      return _getWeeklyData(transactions);
    }

    for (int i = months - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthTx = transactions.where((t) =>
      t.date.month == month.month && t.date.year == month.year
      ).toList();

      final income = monthTx.where((t) => t.type == TransactionType.income)
          .fold(0.0, (s, t) => s + t.amount);
      final expense = monthTx.where((t) => t.type == TransactionType.expense)
          .fold(0.0, (s, t) => s + t.amount);

      trend.add({
        'month': DateFormat('MMM').format(month),
        'income': income,
        'expense': expense,
        'savings': income - expense,
        'savingsRate': income > 0 ? ((income - expense) / income * 100) : 0,
      });
    }
    return trend;
  }

  // ==================== ADVANCED AI INSIGHTS ====================

  List<Map<String, dynamic>> _generateSpendingInsights(List<Transaction> transactions) {
    final insights = <Map<String, dynamic>>[];
    final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
    final incomes = transactions.where((t) => t.type == TransactionType.income).toList();

    if (expenses.isEmpty) return insights;

    final totalSpent = expenses.fold(0.0, (s, t) => s + t.amount);
    final totalIncome = incomes.fold(0.0, (s, t) => s + t.amount);
    final categoryTotals = _getCategoryBreakdown(transactions);

    // 1. Top Category Analysis
    if (categoryTotals.isNotEmpty) {
      final top = categoryTotals.entries.first;
      final second = categoryTotals.length > 1 ? categoryTotals.entries.elementAt(1) : null;
      final topPercentage = (top.value / totalSpent * 100).toDouble(); // Ensure double

      if (topPercentage > 40) {
        insights.add({
          'type': 'critical',
          'icon': Icons.warning_amber_rounded,
          'color': Colors.red,
          'title': 'Critical: High Category Concentration',
          'message': '${top.key} dominates ${topPercentage.toStringAsFixed(1)}% of your spending. This is 2.5x higher than recommended. Consider diversifying your expenses.',
          'action': 'Review Category',
        });
      } else if (topPercentage > 25) {
        insights.add({
          'type': 'warning',
          'icon': Icons.warning,
          'color': Colors.orange,
          'title': 'Category Imbalance',
          'message': '${top.key} accounts for ${topPercentage.toStringAsFixed(1)}% of spending. Try to keep any single category under 25% for better financial health.',
          'action': 'Set Budget',
        });
      }

      if (second != null && top.value > second.value * 3) {
        insights.add({
          'type': 'insight',
          'icon': Icons.trending_up,
          'color': Colors.purple,
          'title': 'Spending Pattern',
          'message': 'Your spending on ${top.key} is 3x higher than ${second.key}. This might indicate an area to optimize.',
          'action': 'Analyze',
        });
      }
    }

    // 2. Dining Out Analysis
    final diningTotal = expenses.where((t) =>
    t.category.contains('Food') || t.category.contains('Dining') || t.category.contains('Restaurant'))
        .fold(0.0, (s, t) => s + t.amount);
    final diningCount = expenses.where((t) =>
    t.category.contains('Food') || t.category.contains('Dining') || t.category.contains('Restaurant')).length;

    if (diningCount > 0) {
      final avgPerMeal = diningTotal / diningCount.toDouble(); // Convert count to double
      final potentialSavings = diningTotal * 0.4;

      if (diningTotal > totalSpent * 0.15) {
        insights.add({
          'type': 'tip',
          'icon': Icons.restaurant,
          'color': Colors.teal,
          'title': 'Dining Out Optimization',
          'message': 'You spent ${_formatNumber(diningTotal)} on dining out (${((diningTotal / totalSpent) * 100).toStringAsFixed(1)}% of expenses). Meal prepping could save you ~${_formatNumber(potentialSavings)} monthly.',
          'action': 'Meal Prep Guide',
          'savings': potentialSavings.toDouble(), // Ensure double
        });
      }

      if (avgPerMeal > 1000) {
        insights.add({
          'type': 'tip',
          'icon': Icons.attach_money,
          'color': Colors.amber,
          'title': 'High-Value Dining',
          'message': 'Your average meal cost is ${_formatNumber(avgPerMeal)}. Consider mixing in more budget-friendly options to save significantly.',
          'action': 'View Alternatives',
        });
      }
    }

    // 3. Subscription Analysis
    final subscriptionKeywords = ['netflix', 'spotify', 'amazon', 'prime', 'disney', 'hulu', 'apple', 'google', 'subscription', 'membership', 'patreon', 'youtube'];
    int subscriptionCount = 0;
    double subscriptionTotal = 0;

    for (var t in expenses) {
      for (var keyword in subscriptionKeywords) {
        if (t.note.toLowerCase().contains(keyword) || t.category.toLowerCase().contains('subscription')) {
          subscriptionCount++;
          subscriptionTotal += t.amount;
          break;
        }
      }
    }

    if (subscriptionCount >= 3) {
      final avgSubscriptionCost = subscriptionTotal / subscriptionCount.toDouble(); // Convert count to double
      insights.add({
        'type': 'audit',
        'icon': Icons.subscriptions,
        'color': Colors.indigo,
        'title': 'Subscription Audit Required',
        'message': 'You have $subscriptionCount subscriptions totaling ${_formatNumber(subscriptionTotal)} (avg ${_formatNumber(avgSubscriptionCost)} each). Reviewing unused services could save you ${_formatNumber(subscriptionTotal * 0.3)} annually.',
        'action': 'Audit Now',
      });
    }

    // 4. Weekend vs Weekday Analysis
    double weekendTotal = 0, weekdayTotal = 0;
    int weekendCount = 0, weekdayCount = 0;

    for (var t in expenses) {
      if (t.date.weekday == DateTime.saturday || t.date.weekday == DateTime.sunday) {
        weekendTotal += t.amount;
        weekendCount++;
      } else {
        weekdayTotal += t.amount;
        weekdayCount++;
      }
    }

    if (weekendCount > 0 && weekdayCount > 0) {
      final weekendAvg = weekendTotal / weekendCount.toDouble(); // Convert to double
      final weekdayAvg = weekdayTotal / weekdayCount.toDouble(); // Convert to double

      if (weekendAvg > weekdayAvg * 1.5) {
        final extraSpend = (weekendAvg - weekdayAvg) * weekendCount.toDouble(); // Convert to double
        insights.add({
          'type': 'pattern',
          'icon': Icons.weekend,
          'color': Colors.orange,
          'title': 'Weekend Spending Pattern',
          'message': 'You spend ${((weekendAvg / weekdayAvg) * 100).toStringAsFixed(0)}% more on weekends (avg ${_formatNumber(weekendAvg)} vs ${_formatNumber(weekdayAvg)}). That\'s ${_formatNumber(extraSpend)} extra per month.',
          'action': 'Weekend Tips',
        });
      }
    }

    // 5. Small Transactions Impact
    int smallTxCount = 0;
    double smallTxTotal = 0;
    for (var t in expenses) {
      if (t.amount < 500) {
        smallTxCount++;
        smallTxTotal += t.amount;
      }
    }

    if (smallTxCount > 20) {
      insights.add({
        'type': 'tip',
        'icon': Icons.receipt,
        'color': Colors.green,
        'title': 'Small Transaction Accumulation',
        'message': '$smallTxCount small transactions (<500) total ${_formatNumber(smallTxTotal)}. Reducing by just 20% could save ${_formatNumber(smallTxTotal * 0.2)}.',
        'action': 'Track Small Spends',
      });
    }

    // 6. Income vs Expense Ratio
    if (totalIncome > 0) {
      final savingsRate = ((totalIncome - totalSpent) / totalIncome * 100).clamp(-100, 100).toDouble();

      if (savingsRate < 0) {
        insights.add({
          'type': 'critical',
          'icon': Icons.warning,
          'color': Colors.red,
          'title': 'Negative Savings Rate',
          'message': 'You\'re spending ${(-savingsRate).toStringAsFixed(1)}% more than you earn. This is unsustainable. Review your essential vs discretionary spending.',
          'action': 'Create Budget',
        });
      } else if (savingsRate < 10) {
        insights.add({
          'type': 'warning',
          'icon': Icons.trending_down,
          'color': Colors.orange,
          'title': 'Low Savings Rate',
          'message': 'You\'re saving only ${savingsRate.toStringAsFixed(1)}% of income. Financial experts recommend 20%. Try reducing non-essentials by 10%.',
          'action': 'Savings Tips',
        });
      } else if (savingsRate > 30) {
        insights.add({
          'type': 'positive',
          'icon': Icons.trending_up,
          'color': Colors.green,
          'title': 'Excellent Saver!',
          'message': 'You\'re saving ${savingsRate.toStringAsFixed(1)}% of income! Consider investing your surplus in tax-advantaged accounts.',
          'action': 'Investment Guide',
        });
      }
    }

    return insights;
  }

  Map<String, dynamic> _generatePrediction(List<Transaction> transactions) {
    final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
    final incomes = transactions.where((t) => t.type == TransactionType.income).toList();

    if (expenses.length < 5) {
      return {
        'nextMonth': 0.0, // Use double
        'nextMonthIncome': 0.0, // Use double
        'trend': 'neutral',
        'message': 'Add more transactions for accurate predictions',
        'confidence': 'low',
        'seasonality': 'unknown',
      };
    }

    final now = DateTime.now();

    // Calculate monthly averages
    final Map<String, double> monthlyExpenses = {};
    final Map<String, double> monthlyIncomes = {};

    for (var t in expenses) {
      final key = '${t.date.year}-${t.date.month}';
      monthlyExpenses[key] = (monthlyExpenses[key] ?? 0) + t.amount;
    }

    for (var t in incomes) {
      final key = '${t.date.year}-${t.date.month}';
      monthlyIncomes[key] = (monthlyIncomes[key] ?? 0) + t.amount;
    }

    // Calculate moving averages (last 3 months)
    final recentMonths = [];
    for (int i = 0; i < 3; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = '${month.year}-${month.month}';
      recentMonths.add({
        'expense': monthlyExpenses[key] ?? 0.0,
        'income': monthlyIncomes[key] ?? 0.0,
      });
    }

    final avgExpense = recentMonths.map((m) => (m['expense'] as num).toDouble()).reduce((a, b) => a + b) / recentMonths.length.toDouble();
    final avgIncome = recentMonths.map((m) => (m['income'] as num).toDouble()).reduce((a, b) => a + b) / recentMonths.length.toDouble();

    // Calculate trend
    double expenseTrend = 0.0;
    if (recentMonths.length >= 2) {
      final first = (recentMonths.last['expense'] as num).toDouble();
      final last = (recentMonths.first['expense'] as num).toDouble();
      expenseTrend = first > 0 ? ((last - first) / first * 100) : 0.0;
    }

    // Check seasonality
    double seasonalFactor = 1.0;
    final lastYear = DateTime(now.year - 1, now.month, 1);
    final lastYearKey = '${lastYear.year}-${lastYear.month}';
    if (monthlyExpenses.containsKey(lastYearKey)) {
      final lastYearAmount = monthlyExpenses[lastYearKey]!;
      final thisYearAvg = avgExpense;
      if (lastYearAmount > 0 && thisYearAvg > 0) {
        seasonalFactor = lastYearAmount / thisYearAvg;
      }
    }

    // Predict next month
    double predictedNextMonth = avgExpense * (1 + (expenseTrend / 100)) * seasonalFactor;
    double predictedIncome = avgIncome * 1.02;

    // Confidence calculation
    String confidence = 'medium';
    if (expenses.length > 30 && monthlyExpenses.length >= 6) confidence = 'high';
    else if (expenses.length < 10) confidence = 'low';

    // Generate insight message
    String message;
    if (predictedNextMonth > avgExpense * 1.2) {
      message = 'Spending likely to increase next month';
    } else if (predictedNextMonth < avgExpense * 0.8) {
      message = 'Spending expected to decrease';
    } else {
      message = 'Spending likely to remain stable';
    }

    if (seasonalFactor > 1.2) {
      message += ' due to seasonal factors';
    }

    return {
      'nextMonth': predictedNextMonth.toDouble(),
      'nextMonthIncome': predictedIncome.toDouble(),
      'projectedSavings': (predictedIncome - predictedNextMonth).toDouble(),
      'trend': expenseTrend.toDouble(),
      'message': message,
      'confidence': confidence,
      'avgExpense': avgExpense.toDouble(),
      'avgIncome': avgIncome.toDouble(),
      'seasonalFactor': seasonalFactor.toDouble(),
    };
  }

  // ==================== CASH FLOW INSIGHTS ====================

  List<Map<String, dynamic>> _generateCashFlowInsights(Map<DateTime, double> income, Map<DateTime, double> expense) {
    final insights = <Map<String, dynamic>>[];

    if (income.isEmpty || expense.isEmpty) return insights;

    final totalIncome = income.values.fold(0.0, (a, b) => a + b);
    final totalExpense = expense.values.fold(0.0, (a, b) => a + b);

    // 1. Cash Flow Status
    final netFlow = totalIncome - totalExpense;
    if (netFlow < 0) {
      insights.add({
        'type': 'critical',
        'icon': Icons.warning,
        'color': Colors.red,
        'title': 'Negative Cash Flow',
        'message': 'Your expenses exceed income by ${_formatNumber(-netFlow)}. Consider reducing discretionary spending.',
      });
    } else if (netFlow < totalIncome * 0.1) {
      insights.add({
        'type': 'warning',
        'icon': Icons.info,
        'color': Colors.orange,
        'title': 'Low Cash Reserve',
        'message': 'Your net cash flow is only ${((netFlow / totalIncome) * 100).toStringAsFixed(1)}% of income. Aim for at least 20%.',
      });
    }

    // 2. Volatility Analysis
    final expenseValues = expense.values.toList();
    if (expenseValues.length > 3) {
      final mean = expenseValues.reduce((a, b) => a + b) / expenseValues.length;
      final variance = expenseValues.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / expenseValues.length;
      final stdDev = sqrt(variance);
      final volatility = (stdDev / mean) * 100;

      if (volatility > 50) {
        insights.add({
          'type': 'insight',
          'icon': Icons.trending_up,
          'color': Colors.purple,
          'title': 'High Spending Volatility',
          'message': 'Your daily spending fluctuates significantly (${volatility.toStringAsFixed(1)}% variation). Consider creating a more consistent spending pattern.',
        });
      }
    }

    // 3. Weekend vs Weekday Pattern
    double weekendTotal = 0, weekdayTotal = 0;
    int weekendDays = 0, weekdayDays = 0;

    expense.forEach((date, amount) {
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
        weekendTotal += amount;
        weekendDays++;
      } else {
        weekdayTotal += amount;
        weekdayDays++;
      }
    });

    if (weekendDays > 0 && weekdayDays > 0) {
      final weekendAvg = weekendTotal / weekendDays.toDouble();
      final weekdayAvg = weekdayTotal / weekdayDays.toDouble();
      final ratio = weekendAvg / weekdayAvg;

      if (ratio > 1.5) {
        insights.add({
          'type': 'pattern',
          'icon': Icons.calendar_today,
          'color': Colors.blue,
          'title': 'Weekend Spending Pattern',
          'message': 'Weekend spending is ${(ratio * 100).toStringAsFixed(0)}% higher than weekdays. This could be an opportunity for savings.',
        });
      }
    }

    // 4. Peak Spending Days
    if (expense.isNotEmpty) {
      final maxEntry = expense.entries.reduce((a, b) => a.value > b.value ? a : b);
      final maxPercentage = (maxEntry.value / totalExpense) * 100;

      if (maxPercentage > 20) {
        insights.add({
          'type': 'insight',
          'icon': Icons.flag,
          'color': Colors.teal,
          'title': 'Peak Spending Day',
          'message': '${DateFormat('EEEE, MMM d').format(maxEntry.key)} had unusually high spending (${maxPercentage.toStringAsFixed(1)}% of total).',
        });
      }
    }

    return insights;
  }

  // ==================== PERIOD INSIGHTS ====================

  List<Map<String, dynamic>> _generatePeriodInsights(Map<String, Map<String, double>> monthlyData) {
    final insights = <Map<String, dynamic>>[];

    if (monthlyData.length < 2) return insights;

    final months = monthlyData.keys.toList();
    final firstMonth = monthlyData[months.first]!;
    final lastMonth = monthlyData[months.last]!;

    // 1. Expense Growth Rate
    final expenseGrowth = firstMonth['expense']! > 0
        ? ((lastMonth['expense']! - firstMonth['expense']!) / firstMonth['expense']! * 100)
        : 0;

    if (expenseGrowth > 20) {
      insights.add({
        'type': 'warning',
        'icon': Icons.trending_up,
        'color': Colors.red,
        'title': 'Rapid Expense Growth',
        'message': 'Your expenses have grown ${expenseGrowth.toStringAsFixed(1)}% over this period. Review your spending categories.',
      });
    } else if (expenseGrowth < -10) {
      insights.add({
        'type': 'positive',
        'icon': Icons.trending_down,
        'color': Colors.green,
        'title': 'Expense Reduction',
        'message': 'You\'ve successfully reduced expenses by ${(-expenseGrowth).toStringAsFixed(1)}%. Great job!',
      });
    }

    // 2. Income Growth
    final incomeGrowth = firstMonth['income']! > 0
        ? ((lastMonth['income']! - firstMonth['income']!) / firstMonth['income']! * 100)
        : 0;

    if (incomeGrowth > 15) {
      insights.add({
        'type': 'positive',
        'icon': Icons.trending_up,
        'color': Colors.green,
        'title': 'Income Growth',
        'message': 'Your income has increased by ${incomeGrowth.toStringAsFixed(1)}%. Consider increasing your savings rate.',
      });
    }

    // 3. Savings Rate Trend
    double totalSavingsRate = 0;
    int monthsWithSavings = 0;

    monthlyData.forEach((month, data) {
      final income = data['income']!;
      final expense = data['expense']!;
      if (income > 0) {
        final savingsRate = ((income - expense) / income) * 100;
        totalSavingsRate += savingsRate;
        monthsWithSavings++;
      }
    });

    if (monthsWithSavings > 0) {
      final avgSavingsRate = totalSavingsRate / monthsWithSavings;

      if (avgSavingsRate > 25) {
        insights.add({
          'type': 'positive',
          'icon': Icons.savings,
          'color': Colors.green,
          'title': 'Strong Savings Habit',
          'message': 'Average savings rate of ${avgSavingsRate.toStringAsFixed(1)}% over this period. Excellent financial discipline.',
        });
      } else if (avgSavingsRate < 10) {
        insights.add({
          'type': 'warning',
          'icon': Icons.warning,
          'color': Colors.orange,
          'title': 'Low Savings Rate',
          'message': 'Average savings rate of ${avgSavingsRate.toStringAsFixed(1)}%. Aim for at least 20% for long-term financial security.',
        });
      }
    }

    return insights;
  }

  // ==================== SAVINGS INSIGHTS (Fixed Null Safety) ====================

  List<Map<String, dynamic>> _generateSavingsInsights(List<Map<String, dynamic>> trend) {
    final insights = <Map<String, dynamic>>[];

    if (trend.length < 2) return insights;

    // Safely extract values with null checks
    final savings = <double>[];
    final rates = <double>[];

    for (var item in trend) {
      final savingsValue = item['savings'];
      final rateValue = item['savingsRate'];

      if (savingsValue != null) {
        savings.add((savingsValue as num).toDouble());
      }

      if (rateValue != null && (rateValue as num) > 0) {
        rates.add(rateValue.toDouble());
      }
    }

    if (savings.isEmpty || rates.isEmpty) return insights;

    // 1. 50/30/20 Rule Analysis
    final avgSavingsRate = rates.reduce((a, b) => a + b) / rates.length.toDouble();

    if (avgSavingsRate >= 20) {
      insights.add({
        'type': 'positive',
        'icon': Icons.check_circle,
        'color': Colors.green,
        'title': '50/30/20 Rule Compliance',
        'message': 'Your ${avgSavingsRate.toStringAsFixed(1)}% savings rate meets the recommended 20% target. Consider investing the surplus.',
      });
    } else {
      final shortfall = 20 - avgSavingsRate;
      insights.add({
        'type': 'action',
        'icon': Icons.trending_up,
        'color': Colors.blue,
        'title': 'Savings Gap Analysis',
        'message': 'To reach the 20% savings target, you need to save an additional ${shortfall.toStringAsFixed(1)}% of your income.',
      });
    }

    // 2. Consistency Score
    if (savings.length > 1) {
      final savingsMean = savings.reduce((a, b) => a + b) / savings.length;
      final savingsVariance = savings.map((v) => pow(v - savingsMean, 2)).reduce((a, b) => a + b) / savings.length;
      final savingsStdDev = sqrt(savingsVariance);
      final consistencyScore = savingsMean != 0
          ? 100 - ((savingsStdDev / savingsMean.abs()) * 100).clamp(0, 100).toDouble()
          : 0.0;

      if (consistencyScore > 80) {
        insights.add({
          'type': 'positive',
          'icon': Icons.star,
          'color': Colors.amber,
          'title': 'Excellent Consistency',
          'message': 'Your savings pattern shows high consistency (${consistencyScore.toStringAsFixed(0)}/100). This is key to building wealth.',
        });
      } else if (consistencyScore < 50 && consistencyScore > 0) {
        insights.add({
          'type': 'warning',
          'icon': Icons.show_chart,
          'color': Colors.orange,
          'title': 'Inconsistent Savings',
          'message': 'Your savings vary significantly month to month. Consider automating your savings.',
        });
      }
    }

    // 3. Emergency Fund Analysis
    final expenses = <double>[];
    for (var item in trend) {
      final expenseValue = item['expense'];
      if (expenseValue != null) {
        expenses.add((expenseValue as num).toDouble());
      }
    }

    if (expenses.isNotEmpty && savings.isNotEmpty) {
      final avgExpense = expenses.reduce((a, b) => a + b) / expenses.length;
      final totalSavings = savings.where((s) => s > 0).reduce((a, b) => a + b);
      final monthsOfExpenses = totalSavings / avgExpense;

      if (monthsOfExpenses < 3) {
        insights.add({
          'type': 'critical',
          'icon': Icons.security,
          'color': Colors.red,
          'title': 'Emergency Fund Needed',
          'message': 'You have only ${monthsOfExpenses.toStringAsFixed(1)} months of expenses saved. Aim for 3-6 months for financial security.',
        });
      } else if (monthsOfExpenses > 6) {
        insights.add({
          'type': 'positive',
          'icon': Icons.savings,
          'color': Colors.green,
          'title': 'Strong Emergency Fund',
          'message': 'You have ${monthsOfExpenses.toStringAsFixed(1)} months of expenses saved. Consider investing excess funds.',
        });
      }
    }

    // 4. Compound Interest Potential
    final positiveSavings = savings.where((s) => s > 0).toList();
    if (positiveSavings.isNotEmpty) {
      final avgMonthlySavings = positiveSavings.reduce((a, b) => a + b) / positiveSavings.length;
      final annualSavings = avgMonthlySavings * 12;

      // Project 10 years at 7% average return
      final futureValue = annualSavings * ((pow(1.07, 10) - 1) / 0.07);

      insights.add({
        'type': 'insight',
        'icon': Icons.trending_up,
        'color': Colors.purple,
        'title': 'Long-term Growth Potential',
        'message': 'At your current savings rate, you could accumulate ${_formatNumber(futureValue)} in 10 years (assuming 7% annual return).',
      });
    }

    return insights;
  }

  // ==================== BUDGET ANALYSIS ====================

  Widget _buildBudgetCircularGauge(double progress, double total, double spent, Currency currency, ThemeProvider theme) {
    return SizedBox(
      height: 130,
      width: 130,
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 120,
              height: 120,
              child: CustomPaint(
                painter: _ModernGaugePainter(
                  progress: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200]!,
                  progressColor: progress > 1 ? AppColors.error :
                  progress > 0.8 ? AppColors.warning :
                  theme.primaryColor,
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'of budget used',
                  style: TextStyle(fontSize: 10, color: AppColors.textLight),
                ),
                const SizedBox(height: 4),
                Text(
                  '${currency.symbol}${_formatNumber(spent)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.primaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _analyzeBudgets(List<Transaction> transactions) {
    if (_budgets.isEmpty) {
      return {
        'totalBudget': 0,
        'totalSpent': 0,
        'onTrack': 0,
        'warning': 0,
        'exceeded': 0,
        'budgets': [],
        'projected': 0,
        'healthScore': 0,
      };
    }

    final now = DateTime.now();
    final monthTx = transactions.where((t) =>
    t.type == TransactionType.expense &&
        t.date.month == now.month && t.date.year == now.year
    ).toList();

    double totalBudget = 0;
    double totalSpent = 0;
    int onTrack = 0, warning = 0, exceeded = 0;
    double totalProjected = 0;
    final List<Map<String, dynamic>> budgetStatus = [];

    for (var budget in _budgets) {
      totalBudget += budget.limit;
      final spent = monthTx.where((t) => t.category == budget.category)
          .fold(0.0, (s, t) => s + t.amount);
      totalSpent += spent;

      final daysPassed = now.day;
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final projectedSpending = (spent / daysPassed) * daysInMonth;
      totalProjected += projectedSpending;

      final progress = spent / budget.limit;
      String status;
      Color color;

      if (progress > 1) {
        status = 'Exceeded';
        color = AppColors.error;
        exceeded++;
      } else if (progress > 0.8) {
        status = 'Warning';
        color = AppColors.warning;
        warning++;
      } else {
        status = 'On Track';
        color = AppColors.success;
        onTrack++;
      }

      budgetStatus.add({
        'category': budget.category,
        'limit': budget.limit,
        'spent': spent,
        'progress': progress * 100,
        'projected': projectedSpending,
        'remaining': budget.limit - spent,
        'dailyAvg': spent / daysPassed,
        'status': status,
        'color': color,
        'rawProgress': progress,
      });
    }

    final healthScore = ((onTrack * 100) + (warning * 60) + (exceeded * 20)) / _budgets.length;

    return {
      'totalBudget': totalBudget,
      'totalSpent': totalSpent,
      'remaining': totalBudget - totalSpent,
      'projected': totalProjected,
      'healthScore': healthScore,
      'onTrack': onTrack,
      'warning': warning,
      'exceeded': exceeded,
      'budgets': budgetStatus,
    };
  }

  // ==================== BUDGET INSIGHTS ====================

  List<Map<String, dynamic>> _generateBudgetInsights(Map<String, dynamic> analysis, List<Transaction> transactions) {
    final insights = <Map<String, dynamic>>[];

    if (analysis['totalBudget'] == 0) return insights;

    if (analysis['exceeded'] > 0) {
      final exceededCategories = (analysis['budgets'] as List)
          .where((b) => b['status'] == 'Exceeded')
          .map((b) => b['category'])
          .join(', ');

      insights.add({
        'type': 'critical',
        'icon': Icons.warning,
        'color': AppColors.error,
        'title': 'Budget Overruns Detected',
        'message': 'You have exceeded budgets in: $exceededCategories. Review these categories immediately.',
      });
    }

    if (analysis['projected'] > analysis['totalBudget']) {
      final overage = analysis['projected'] - analysis['totalBudget'];
      final daysLeft = DateTime.now().daysInMonth - DateTime.now().day;
      final dailyReduce = overage / daysLeft;

      insights.add({
        'type': 'warning',
        'icon': Icons.trending_up,
        'color': AppColors.warning,
        'title': 'Overspending Risk',
        'message': 'Projected to exceed total budget by ${_formatNumber(overage)}. Reduce daily spending by ${_formatNumber(dailyReduce)} to stay on track.',
      });
    }

    if (analysis['remaining'] > 0 && analysis['remaining'] < analysis['totalBudget'] * 0.1) {
      final daysLeft = DateTime.now().daysInMonth - DateTime.now().day;
      final dailyRemaining = analysis['remaining'] / daysLeft;

      insights.add({
        'type': 'warning',
        'icon': Icons.info,
        'color': AppColors.warning,
        'title': 'Tight Budget',
        'message': 'Only ${_formatNumber(dailyRemaining)} per day remaining for the rest of the month. Spend carefully.',
      });
    }

    // Find categories with highest projected overrun
    final budgets = analysis['budgets'] as List;
    final highRiskCategories = budgets.where((b) =>
    b['projected'] > b['limit'] * 1.2
    ).toList();

    if (highRiskCategories.isNotEmpty) {
      final categories = highRiskCategories.map((b) => b['category']).take(2).join(', ');
      insights.add({
        'type': 'insight',
        'icon': Icons.priority_high,
        'color': Colors.orange,
        'title': 'High Risk Categories',
        'message': '$categories ${highRiskCategories.length > 2 ? 'and others' : ''} are at high risk of exceeding budget significantly.',
      });
    }

    // Savings opportunity from under-budget categories
    final underBudget = budgets.where((b) =>
    b['projected'] < b['limit'] * 0.8 && b['spent'] > 0
    ).toList();

    if (underBudget.isNotEmpty) {
      final totalUnder = underBudget.fold(0.0, (sum, b) => sum + (b['limit'] - b['projected']));
      insights.add({
        'type': 'positive',
        'icon': Icons.savings,
        'color': AppColors.success,
        'title': 'Savings Opportunity',
        'message': 'You\'re under budget in ${underBudget.length} categories. Consider reallocating ${_formatNumber(totalUnder)} to savings or debt.',
      });
    }

    return insights;
  }

  // ==================== GOALS ANALYSIS ====================

  Widget _buildGoalsCircularGauge(double progress, double target, double current, Currency currency, ThemeProvider theme) {
    return SizedBox(
      height: 130,
      width: 130,
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 120,
              height: 120,
              child: CustomPaint(
                painter: _ModernGaugePainter(
                  progress: (progress / 100).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200]!,
                  progressColor: progress >= 100 ? AppColors.success : theme.primaryColor,
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${progress.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'of goal',
                  style: TextStyle(fontSize: 10, color: AppColors.textLight),
                ),
                const SizedBox(height: 4),
                Text(
                  '${currency.symbol}${_formatNumber(current)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.primaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _analyzeGoals() {
    if (_savingsGoals.isEmpty) {
      return {
        'totalTarget': 0,
        'totalCurrent': 0,
        'completed': 0,
        'onTrack': 0,
        'behind': 0,
        'goals': [],
        'projectedCompletion': '',
      };
    }

    double totalTarget = 0;
    double totalCurrent = 0;
    int completed = 0, onTrack = 0, behind = 0;
    double earliestCompletion = double.infinity;
    final List<Map<String, dynamic>> goalStatus = [];

    for (var goal in _savingsGoals) {
      totalTarget += goal.target;
      totalCurrent += goal.current;

      if (goal.progress >= 100) {
        completed++;
      } else if (goal.isBehind) {
        behind++;
      } else {
        onTrack++;
      }

      final dailyRate = goal.current / (DateTime.now().difference(goal.deadline).inDays + 1);
      final daysToComplete = dailyRate > 0 ? (goal.remaining / dailyRate) : double.infinity;

      goalStatus.add({
        'name': goal.name,
        'target': goal.target,
        'current': goal.current,
        'progress': goal.progress,
        'remaining': goal.remaining,
        'daysLeft': goal.daysRemaining,
        'requiredDaily': goal.requiredDaily,
        'isBehind': goal.isBehind,
        'color': _parseColor(goal.color),
        'projectedDays': daysToComplete,
        'onTrack': !goal.isBehind && goal.progress < 100,
      });

      if (!goal.isBehind && goal.progress < 100) {
        earliestCompletion = math.min(earliestCompletion, daysToComplete);
      }
    }

    String projectedMsg = 'In progress';
    if (earliestCompletion < double.infinity) {
      projectedMsg = 'Earliest goal in ${earliestCompletion.toStringAsFixed(0)} days';
    }

    return {
      'totalTarget': totalTarget,
      'totalCurrent': totalCurrent,
      'overallProgress': totalTarget > 0 ? (totalCurrent / totalTarget * 100) : 0,
      'completed': completed,
      'onTrack': onTrack,
      'behind': behind,
      'goals': goalStatus,
      'projectedCompletion': projectedMsg,
      'totalRemaining': totalTarget - totalCurrent,
    };
  }

  // ==================== GOAL INSIGHTS ====================

  List<Map<String, dynamic>> _generateGoalInsights(Map<String, dynamic> analysis) {
    final insights = <Map<String, dynamic>>[];

    if (analysis['totalTarget'] == 0) return insights;

    if (analysis['behind'] > 0) {
      final behindGoals = (analysis['goals'] as List)
          .where((g) => g['isBehind'])
          .map((g) => g['name'])
          .take(2)
          .join(', ');

      insights.add({
        'type': 'warning',
        'icon': Icons.access_time,
        'color': AppColors.warning,
        'title': 'Goals Behind Schedule',
        'message': '$behindGoals ${analysis['behind'] > 2 ? 'and others' : ''} are behind schedule. Consider increasing contributions.',
      });
    }

    if (analysis['completed'] > 0) {
      insights.add({
        'type': 'positive',
        'icon': Icons.emoji_events,
        'color': AppColors.success,
        'title': 'Goals Achieved',
        'message': 'Congratulations! You\'ve completed ${analysis['completed']} goal${analysis['completed'] > 1 ? 's' : ''}.',
      });
    }

    // Calculate required monthly savings to complete all goals
    if (analysis['totalRemaining'] > 0) {
      final avgDeadline = (analysis['goals'] as List)
          .map((g) => g['daysLeft'] as int)
          .reduce((a, b) => a + b) / analysis['goals'].length;

      final monthsNeeded = avgDeadline / 30;
      final monthlyNeeded = analysis['totalRemaining'] / monthsNeeded;

      insights.add({
        'type': 'insight',
        'icon': Icons.trending_up,
        'color': Colors.blue,
        'title': 'Acceleration Strategy',
        'message': 'To complete all goals on average timeline, save ${_formatNumber(monthlyNeeded)} per month.',
      });

      // Compare with current savings rate
      final avgRequiredDaily = (analysis['goals'] as List)
          .map((g) => (g['requiredDaily'] as num?)?.toDouble() ?? 0)
          .reduce((a, b) => a + b) / analysis['goals'].length;

      if (avgRequiredDaily > 0) {
        insights.add({
          'type': 'insight',
          'icon': Icons.calendar_today,
          'color': Colors.purple,
          'title': 'Daily Saving Target',
          'message': 'Average daily saving needed: ${_formatNumber(avgRequiredDaily)} to stay on track with all goals.',
        });
      }
    }

    return insights;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MainLayout(
        currentIndex: 2,
        child: const Scaffold(
          backgroundColor: AppColors.lightGray,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final theme = Provider.of<ThemeProvider>(context);
    final currency = _user?.preferredCurrency ?? Currency.npr;

    return MainLayout(
      currentIndex: 2,
      child: Scaffold(
        backgroundColor: AppColors.lightGray,
        appBar: AppBar(
          backgroundColor: theme.primaryColor,
          elevation: 0,
          leadingWidth: 0,
          leading: const SizedBox(),
          toolbarHeight: 100,
          title: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Your Financial Report',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          centerTitle: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: theme.primaryColor,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.7),
                  padding: const EdgeInsets.only(left: 16),
                  indicatorPadding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                  tabAlignment: TabAlignment.start,
                  tabs: const [
                    Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
                    Tab(text: 'Cash Flow', icon: Icon(Icons.trending_up)),
                    Tab(text: 'Period', icon: Icon(Icons.calendar_month)),
                    Tab(text: 'Distribution', icon: Icon(Icons.pie_chart)),
                    Tab(text: 'Savings', icon: Icon(Icons.savings)),
                    Tab(text: 'Budget', icon: Icon(Icons.account_balance_wallet)),
                    Tab(text: 'Goals', icon: Icon(Icons.flag)),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(currency, theme),
            _buildCashFlowTab(currency, theme),
            _buildPeriodTab(currency, theme),
            _buildDistributionTab(currency, theme),
            _buildSavingsTab(currency, theme),
            _buildBudgetTab(currency, theme),
            _buildGoalsTab(currency, theme),
          ],
        ),
      ),
    );
  }

  // ==================== OVERVIEW TAB ====================

  final List<Color> _premiumColors = [
    const Color(0xFF4361EE),
    const Color(0xFF06D6A0),
    const Color(0xFFEF476F),
    const Color(0xFFFFB703),
    const Color(0xFF8338EC),
    const Color(0xFFFB5607),
    const Color(0xFF3A86FF),
    const Color(0xFF52B788),
    const Color(0xFFE63946),
    const Color(0xFFA2D2FF),
    const Color(0xFFB5838D),
    const Color(0xFFFF99C8),
    const Color(0xFFAACC00),
    const Color(0xFF9C89B8),
    const Color(0xFFF48C06),
    const Color(0xFF2D6A4F),
    const Color(0xFFD62828),
    const Color(0xFF1E6091),
    const Color(0xFFD4A373),
    const Color(0xFFB56576),
  ];

  String _getOverviewAveragePeriodLabel() {
    switch (_overviewFilter) {
      case 'week':
        return 'Day';
      case 'month':
        return 'Day';
      case '3months':
        return 'Day';
      case '6months':
        return 'Day';
      case 'year':
        return 'Day';
      default:
        return 'Month';
    }
  }

  String _getOverviewPeriodLabel() {
    switch (_overviewFilter) {
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case '3months':
        return 'Last 3 Months';
      case '6months':
        return 'Last 6 Months';
      case 'year':
        return 'This Year';
      default:
        return 'All Time';
    }
  }

  String _getOverviewPeriodDateRange() {
    final now = DateTime.now();
    final formatter = DateFormat('MMM d');

    switch (_overviewFilter) {
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return '${formatter.format(weekAgo)} - ${formatter.format(now)}';
      case 'month':
        final monthStart = DateTime(now.year, now.month, 1);
        return '${formatter.format(monthStart)} - ${formatter.format(now)}';
      case '3months':
        final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
        return '${formatter.format(threeMonthsAgo)} - ${formatter.format(now)}';
      case '6months':
        final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);
        return '${formatter.format(sixMonthsAgo)} - ${formatter.format(now)}';
      case 'year':
        final yearStart = DateTime(now.year, 1, 1);
        return '${formatter.format(yearStart)} - ${formatter.format(now)}';
      default:
        return 'All historical data';
    }
  }

  void _showAllCategoriesSheet(
      Map<String, double> categoryData,
      double total,
      Currency currency,
      ThemeProvider theme,
      bool isExpense,
      ) {
    final sortedEntries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isExpense ? AppColors.error : AppColors.success,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Row(
                children: [
                  Text(
                    'All ${isExpense ? 'Expense' : 'Income'} Categories',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sortedEntries.length,
                itemBuilder: (context, index) {
                  final entry = sortedEntries[index];
                  final percentage = (entry.value / total * 100);
                  final color = _getCategoryColor(entry.key);
                  final emoji = _getCategoryEmoji(entry.key);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${percentage.toStringAsFixed(1)}%',
                                      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'of total',
                                    style: TextStyle(fontSize: 11, color: AppColors.textLight),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${currency.symbol} ${_formatNumber(entry.value)}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(Currency currency, ThemeProvider theme) {
    final transactions = _filterTransactions(_overviewFilter);
    final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
    final totalSpent = expenses.fold(0.0, (s, t) => s + t.amount);
    final categoryData = _getCategoryBreakdown(transactions);
    final insights = _generateSpendingInsights(transactions);
    final prediction = _generatePrediction(transactions);

    double getAverageSpending() {
      switch (_overviewFilter) {
        case 'week':
          return totalSpent / 7;
        case 'month':
          return totalSpent / 30;
        case '3months':
          return totalSpent / 90;
        case '6months':
          return totalSpent / 180;
        case 'year':
          return totalSpent / 365;
        default:
          return totalSpent / 30;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Time', 'all', 'overview', theme.primaryColor),
                _buildFilterChip('This Week', 'week', 'overview', theme.primaryColor),
                _buildFilterChip('This Month', 'month', 'overview', theme.primaryColor),
                _buildFilterChip('3 Months', '3months', 'overview', theme.primaryColor),
                _buildFilterChip('6 Months', '6months', 'overview', theme.primaryColor),
                _buildFilterChip('This Year', 'year', 'overview', theme.primaryColor),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: _modernCardDecoration(theme),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactMetricCard(
                        'Total Spent',
                        _formatNumber(totalSpent),
                        Icons.account_balance_wallet,
                        AppColors.error,
                        currency,
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactMetricCard(
                        'Categories',
                        '${categoryData.length}',
                        Icons.category,
                        theme.primaryColor,
                        currency,
                        isNumber: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactMetricCard(
                        'Transactions',
                        '${expenses.length}',
                        Icons.receipt,
                        Colors.green,
                        currency,
                        isNumber: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactMetricCard(
                        'Avg/${_getOverviewAveragePeriodLabel()}',
                        _formatNumber(getAverageSpending()),
                        Icons.calendar_today,
                        Colors.purple,
                        currency,
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, size: 10, color: theme.primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              _getOverviewPeriodDateRange(),
                              style: TextStyle(fontSize: 10, color: theme.primaryColor, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (categoryData.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _modernCardDecoration(theme),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.pie_chart, color: theme.primaryColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text('Spending Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getOverviewPeriodLabel(),
                          style: TextStyle(fontSize: 11, color: theme.primaryColor, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: SizedBox(
                      height: 216,
                      width: 216,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 54,
                          sections: List.generate(min(categoryData.length, 7), (i) {
                            final entry = categoryData.entries.elementAt(i);
                            final percentage = entry.value / totalSpent * 100;
                            return PieChartSectionData(
                              value: entry.value,
                              title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                              radius: 80,
                              color: _getCategoryColor(entry.key),
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  ...categoryData.entries.take(5).map((e) {
                    final color = _getCategoryColor(e.key);
                    final percentage = (e.value / totalSpent * 100);
                    final emoji = _getCategoryEmoji(e.key);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.key,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${percentage.toStringAsFixed(1)}% of total',
                                  style: TextStyle(fontSize: 11, color: AppColors.textLight),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${currency.symbol}${_formatNumber(e.value)}',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  if (categoryData.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: GestureDetector(
                        onTap: () => _showAllCategoriesSheet(
                          categoryData,
                          totalSpent,
                          currency,
                          theme,
                          true,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: theme.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Show all ${categoryData.length} categories',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primaryColor.withOpacity(0.1), _getSecondaryColor(theme.primaryColor).withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.online_prediction, color: theme.primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('AI Financial Forecast', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'last 3 months',
                        style: TextStyle(fontSize: 10, color: theme.primaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildForecastCard(
                        'Next Month',
                        '${currency.symbol} ${_formatNumber(prediction['nextMonth'])}',
                        Icons.trending_up,
                        theme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildForecastCard(
                        'Projected Income',
                        '${currency.symbol} ${_formatNumber(prediction['nextMonthIncome'])}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // FIXED SECTION - Safely handle trend value
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Safely determine trend icon and colors
                      Builder(
                        builder: (context) {
                          // Check if trend is a number
                          bool isTrendValid = prediction['trend'] is num;
                          double trendValue = isTrendValid ? (prediction['trend'] as num).toDouble() : 0;

                          Color iconBgColor;
                          IconData iconData;
                          Color iconColor;

                          if (!isTrendValid) {
                            iconBgColor = Colors.grey.withOpacity(0.1);
                            iconData = Icons.trending_flat;
                            iconColor = Colors.grey;
                          } else if (trendValue > 5) {
                            iconBgColor = AppColors.error.withOpacity(0.1);
                            iconData = Icons.trending_up;
                            iconColor = AppColors.error;
                          } else if (trendValue < -5) {
                            iconBgColor = AppColors.success.withOpacity(0.1);
                            iconData = Icons.trending_down;
                            iconColor = AppColors.success;
                          } else {
                            iconBgColor = Colors.grey.withOpacity(0.1);
                            iconData = Icons.trending_flat;
                            iconColor = Colors.grey;
                          }

                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              iconData,
                              color: iconColor,
                              size: 20,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          prediction['message'],
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: prediction['confidence'] == 'high' ? AppColors.success.withOpacity(0.1) :
                          prediction['confidence'] == 'medium' ? AppColors.warning.withOpacity(0.1) :
                          Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          prediction['confidence'].toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: prediction['confidence'] == 'high' ? AppColors.success :
                            prediction['confidence'] == 'medium' ? AppColors.warning : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (insights.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _modernCardDecoration(theme),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.psychology, color: theme.primaryColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text('AI Smart Insights (${insights.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...insights.take(3).map((i) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: i['color'].withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: i['color'].withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: i['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(i['icon'], color: i['color'], size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                i['title'],
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: i['color']),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                i['message'],
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                              if (i.containsKey('savings'))
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: i['color'].withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Potential savings: ${currency.symbol} ${_formatNumber(i['savings'])}',
                                      style: TextStyle(fontSize: 12, color: i['color'], fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  if (insights.length > 3)
                    Center(
                      child: TextButton(
                        onPressed: () => _showAllInsights(insights, currency, theme),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Text('+ ${insights.length - 3} more insights'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getAveragePeriodLabel() {
    switch (_overviewFilter) {
      case 'week':
        return 'Day';
      case 'month':
        return 'Day';
      case '3months':
        return 'Day';
      case '6months':
        return 'Day';
      case 'year':
        return 'Day';
      default:
        return 'Month';
    }
  }

  String _getPeriodLabel() {
    switch (_overviewFilter) {
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case '3months':
        return 'Last 3 Months';
      case '6months':
        return 'Last 6 Months';
      case 'year':
        return 'This Year';
      default:
        return 'All Time';
    }
  }

  String _getPeriodDateRange() {
    final now = DateTime.now();
    final formatter = DateFormat('MMM d');

    switch (_overviewFilter) {
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return '${formatter.format(weekAgo)} - ${formatter.format(now)}';
      case 'month':
        final monthStart = DateTime(now.year, now.month, 1);
        return '${formatter.format(monthStart)} - ${formatter.format(now)}';
      case '3months':
        final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
        return '${formatter.format(threeMonthsAgo)} - ${formatter.format(now)}';
      case '6months':
        final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);
        return '${formatter.format(sixMonthsAgo)} - ${formatter.format(now)}';
      case 'year':
        final yearStart = DateTime(now.year, 1, 1);
        return '${formatter.format(yearStart)} - ${formatter.format(now)}';
      default:
        return 'All historical data';
    }
  }

  Widget _buildCompactMetricCard(String label, String value, IconData icon, Color color, Currency currency, {bool isNumber = true}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 12),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w500
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isNumber ? '${currency.symbol} $value' : value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color
            ),
          ),
        ],
      ),
    );
  }

  void _showAllInsights(List<Map<String, dynamic>> insights, Currency currency, ThemeProvider theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Row(
                children: [
                  const Text('All Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: insights.length,
                itemBuilder: (context, index) {
                  final i = insights[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: i['color'].withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: i['color'].withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: i['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(i['icon'], color: i['color'], size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                i['title'],
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: i['color']),
                              ),
                              const SizedBox(height: 4),
                              Text(i['message'], style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== CASH FLOW TAB ====================

  Widget _buildCashFlowTab(Currency currency, ThemeProvider theme) {
    final transactions = _filterTransactions(_cashFlowFilter);
    final dailyIncome = _getDailyIncome(transactions, _cashFlowFilter);
    final dailyExpense = _getDailyExpense(transactions, _cashFlowFilter);
    final insights = _generateCashFlowInsights(dailyIncome, dailyExpense);

    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    int index = 0;

    final sortedDates = dailyExpense.keys.toList()..sort();
    final totalDays = sortedDates.length;
    final labelInterval = _getLabelInterval(totalDays);

    for (var date in sortedDates) {
      incomeSpots.add(FlSpot(index.toDouble(), dailyIncome[date] ?? 0));
      expenseSpots.add(FlSpot(index.toDouble(), dailyExpense[date] ?? 0));
      index++;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Week', 'week', 'cashflow', theme.primaryColor),
                _buildFilterChip('Month', 'month', 'cashflow', theme.primaryColor),
                _buildFilterChip('3 Months', '3months', 'cashflow', theme.primaryColor),
                _buildFilterChip('6 Months', '6months', 'cashflow', theme.primaryColor),
                _buildFilterChip('1 Year', 'year', 'cashflow', theme.primaryColor),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _modernCardDecoration(theme),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.trending_up, color: theme.primaryColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text('AI Cash Flow Analysis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildModernTradingChart(incomeSpots, expenseSpots, currency, theme, sortedDates, labelInterval),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem('Income', AppColors.success),
                          const SizedBox(width: 24),
                          _buildLegendItem('Expenses', AppColors.error),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _modernCardDecoration(theme),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildCashFlowStat(
                          'Net Flow',
                          _calculateNetFlow(dailyIncome, dailyExpense),
                          currency,
                          theme,
                          isMonetary: true,
                        ),
                      ),
                      Container(width: 1, height: 50, color: Colors.grey[300]),
                      Expanded(
                        child: _buildCashFlowStat(
                          'Volatility',
                          _calculateVolatility(dailyExpense),
                          currency,
                          theme,
                          isPercent: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _modernCardDecoration(theme),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.insert_chart_outlined, color: theme.primaryColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text('Cash Flow Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...insights.map((i) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: i['color'].withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: i['color'].withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: i['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(i['icon'], color: i['color'], size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(i['title'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: i['color'])),
                                  const SizedBox(height: 4),
                                  Text(i['message'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                      if (insights.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('No significant patterns detected', style: TextStyle(color: AppColors.textLight)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernTradingChart(List<FlSpot> incomeSpots, List<FlSpot> expenseSpots,
      Currency currency, ThemeProvider theme, List<DateTime> dates, int labelInterval) {
    if (incomeSpots.isEmpty && expenseSpots.isEmpty) {
      return _buildEmptyState('No data for this period', Icons.show_chart, theme);
    }

    final allValues = [...incomeSpots.map((e) => e.y), ...expenseSpots.map((e) => e.y)];
    final maxY = allValues.isEmpty ? 1000.0 : allValues.reduce(math.max);
    final roundedMax = _roundUpToNiceNumber(maxY * 1.2);

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: roundedMax / 5,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          minY: 0,
          maxY: roundedMax,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '${currency.symbol}${_formatCompactNumber(value)}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: labelInterval.toDouble(),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < dates.length && idx % labelInterval == 0) {
                    if (_cashFlowFilter == 'week') {
                      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          weekdays[dates[idx].weekday - 1],
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('d MMM').format(dates[idx]),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    }
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: incomeSpots,
              isCurved: true,
              color: AppColors.success,
              barWidth: 2.5,
              dashArray: [5, 5],
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots: expenseSpots,
              isCurved: true,
              color: AppColors.error,
              barWidth: 2.5,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [AppColors.error.withOpacity(0.2), AppColors.error.withOpacity(0)],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final isIncome = spot.barIndex == 0;
                  return LineTooltipItem(
                    '${isIncome ? 'Income' : 'Expense'}: ${currency.symbol} ${_formatNumber(spot.y)}',
                    TextStyle(color: isIncome ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  double _calculateNetFlow(Map<DateTime, double> income, Map<DateTime, double> expense) {
    double total = 0;
    expense.forEach((date, amount) {
      total += (income[date] ?? 0) - amount;
    });
    return total;
  }

  double _calculateVolatility(Map<DateTime, double> data) {
    if (data.isEmpty) return 0;
    final values = data.values.toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    if (mean == 0) return 0;
    final variance = values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    return math.sqrt(variance) / mean * 100;
  }

  Widget _buildCashFlowStat(String label, double value, Currency currency, ThemeProvider theme,
      {bool isMonetary = false, bool isPercent = false}) {
    String displayValue;
    Color color;

    if (isPercent) {
      displayValue = '${value.toStringAsFixed(1)}%';
      color = value > 30 ? AppColors.warning : value > 15 ? Colors.orange : theme.primaryColor;
    } else {
      displayValue = '${currency.symbol} ${_formatNumber(value)}';
      color = value >= 0 ? AppColors.success : AppColors.error;
    }

    return Column(
      children: [
        Text(
          displayValue,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
      ],
    );
  }

  // ==================== PERIOD TAB ====================

  Widget _buildPeriodTab(Currency currency, ThemeProvider theme) {
    if (_periodFilter != 'week' &&
        _periodFilter != 'month' &&
        _periodFilter != '3months' &&
        _periodFilter != '6months' &&
        _periodFilter != 'year') {
      _periodFilter = 'week';
    }

    int months = _getPeriodMonthCount(_periodFilter);
    final transactions = _filterTransactions(_periodFilter);
    final periodData = _getPeriodData(transactions, months, filter: _periodFilter);
    final insights = _generatePeriodAnalysis(periodData);

    final totalItems = periodData.length;

    int getLabelInterval() {
      switch (_periodFilter) {
        case 'week':
          return 1;
        case 'month':
          return (totalItems > 7) ? 2 : 1;
        case '3months':
          return 1;
        case '6months':
          return (totalItems > 6) ? 2 : 1;
        case 'year':
          return (totalItems > 8) ? 2 : 1;
        default:
          return 1;
      }
    }

    final labelInterval = getLabelInterval();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('This Week', 'week', 'period', theme.primaryColor),
                _buildFilterChip('This Month', 'month', 'period', theme.primaryColor),
                _buildFilterChip('3 Months', '3months', 'period', theme.primaryColor),
                _buildFilterChip('6 Months', '6months', 'period', theme.primaryColor),
                _buildFilterChip('1 Year', 'year', 'period', theme.primaryColor),
              ],
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _modernCardDecoration(theme),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.bar_chart, color: theme.primaryColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text('Period Analysis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getPeriodDisplayLabel(),
                              style: TextStyle(fontSize: 11, color: theme.primaryColor, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildEnhancedPeriodChart(periodData, currency, theme, labelInterval, _periodFilter),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _modernCardDecoration(theme),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildPeriodStatCard(
                          'Avg Income',
                          _calculatePeriodAvg(periodData, 'income'),
                          currency,
                          AppColors.success,
                        ),
                      ),
                      Container(width: 1, height: 50, color: Colors.grey[300]),
                      Expanded(
                        child: _buildPeriodStatCard(
                          'Avg Expense',
                          _calculatePeriodAvg(periodData, 'expense'),
                          currency,
                          AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _modernCardDecoration(theme),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.analytics, color: theme.primaryColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text('AI Period Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      ...insights.take(2).map((i) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: i['color'].withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: i['color'].withOpacity(0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: i['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(i['icon'], color: i['color'], size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(i['title'],
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: i['color'])),
                                  const SizedBox(height: 4),
                                  Text(i['message'],
                                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )).toList(),

                      if (insights.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('No significant patterns detected',
                                style: TextStyle(color: AppColors.textLight)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedPeriodChart(
      Map<String, Map<String, double>> data,
      Currency currency,
      ThemeProvider theme,
      int labelInterval,
      String filter,
      ) {
    if (data.isEmpty) {
      return _buildEmptyState('No data for this period', Icons.bar_chart, theme);
    }

    double maxValue = 0;
    data.forEach((_, v) {
      maxValue = math.max(maxValue, v['income']!);
      maxValue = math.max(maxValue, v['expense']!);
    });

    final roundedMax = _roundUpToNiceNumber(maxValue * 1.2);
    final interval = roundedMax / 5;

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: roundedMax,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final period = data.keys.elementAt(group.x.toInt());
                final value = rod.toY;
                final type = rodIndex == 0 ? 'Income' : 'Expense';
                final color = rodIndex == 0 ? AppColors.success : AppColors.error;
                return BarTooltipItem(
                  '$period\n',
                  const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: '$type: ${currency.symbol} ${_formatNumber(value)}',
                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '${currency.symbol}${_formatCompactNumber(value)}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                interval: labelInterval.toDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.keys.length && (index % labelInterval == 0 || index == data.keys.length - 1)) {
                    String label = data.keys.elementAt(index);

                    if (filter == 'week') {
                    } else if (filter == 'month') {
                    } else {
                      label = label.split(' ')[0];
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        label,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            horizontalInterval: interval,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(data.length, (index) {
            final values = data.values.elementAt(index);
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: values['income']!,
                  color: AppColors.success,
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                BarChartRodData(
                  toY: values['expense']!,
                  color: AppColors.error,
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _generatePeriodAnalysis(Map<String, Map<String, double>> periodData) {
    final insights = <Map<String, dynamic>>[];

    if (periodData.length < 2) return insights;

    final periods = periodData.keys.toList();
    final firstPeriod = periodData[periods.first]!;
    final lastPeriod = periodData[periods.last]!;

    final expenseGrowth = firstPeriod['expense']! > 0
        ? ((lastPeriod['expense']! - firstPeriod['expense']!) / firstPeriod['expense']! * 100)
        : 0;

    if (expenseGrowth.abs() > 10) {
      if (expenseGrowth > 0) {
        insights.add({
          'type': 'warning',
          'icon': Icons.trending_up,
          'color': Colors.orange,
          'title': 'Spending Trend Alert',
          'message': 'Your expenses have increased by ${expenseGrowth.toStringAsFixed(1)}% over this period. Consider reviewing your spending habits.',
        });
      } else {
        insights.add({
          'type': 'positive',
          'icon': Icons.trending_down,
          'color': Colors.green,
          'title': 'Spending Reduction',
          'message': 'Great job! Your expenses have decreased by ${(-expenseGrowth).toStringAsFixed(1)}%. You saved approximately ${_formatNumber(firstPeriod['expense']! - lastPeriod['expense']!)}.',
        });
      }
    } else {
      insights.add({
        'type': 'info',
        'icon': Icons.trending_flat,
        'color': Colors.blue,
        'title': 'Stable Spending Pattern',
        'message': 'Your spending has remained relatively stable with only ${expenseGrowth.toStringAsFixed(1)}% variation. This consistency is good for budgeting.',
      });
    }

    if (periodData.length >= 2) {
      double totalIncome = 0;
      double totalExpense = 0;
      int positiveMonths = 0;

      periodData.forEach((period, data) {
        totalIncome += data['income']!;
        totalExpense += data['expense']!;
        if (data['income']! > data['expense']!) {
          positiveMonths++;
        }
      });

      final avgIncome = totalIncome / periodData.length;
      final avgExpense = totalExpense / periodData.length;
      final netSavings = totalIncome - totalExpense;
      final savingsRate = totalIncome > 0 ? (netSavings / totalIncome * 100) : 0;

      String message;
      Color color;
      IconData icon;

      if (savingsRate >= 20) {
        message = 'Excellent! You\'re saving ${savingsRate.toStringAsFixed(1)}% of your income, which exceeds the recommended 20% target. Total savings of ${_formatNumber(netSavings)} over this period.';
        color = Colors.green;
        icon = Icons.emoji_events;
      } else if (savingsRate >= 10) {
        message = 'Good progress! You\'re saving ${savingsRate.toStringAsFixed(1)}% of your income. To reach the 20% target, try reducing expenses by ${_formatNumber(avgExpense * 0.1)} per period.';
        color = Colors.blue;
        icon = Icons.trending_up;
      } else if (savingsRate > 0) {
        message = 'Your savings rate is ${savingsRate.toStringAsFixed(1)}%. Consider reviewing your expenses to increase this. You had ${positiveMonths} out of ${periodData.length} periods with positive cash flow.';
        color = Colors.orange;
        icon = Icons.warning;
      } else {
        message = 'You\'re spending more than you earn by ${_formatNumber(-netSavings)}. This is unsustainable. Focus on reducing non-essential expenses.';
        color = Colors.red;
        icon = Icons.error;
      }

      insights.add({
        'type': 'financial',
        'icon': icon,
        'color': color,
        'title': 'Financial Health Check',
        'message': message,
      });
    }

    return insights;
  }

  double _calculatePeriodAvg(Map<String, Map<String, double>> data, String type) {
    if (data.isEmpty) return 0;
    return data.values.map((v) => v[type]!).reduce((a, b) => a + b) / data.length;
  }

  int _getPeriodMonthCount(String filter) {
    switch (filter) {
      case 'week':
        return 1;
      case 'month':
        return 1;
      case '3months':
        return 3;
      case '6months':
        return 6;
      case 'year':
        return 12;
      default:
        return 6;
    }
  }

  Map<String, Map<String, double>> _getPeriodData(List<Transaction> transactions, int months, {String filter = '6months'}) {
    final Map<String, Map<String, double>> result = {};
    final now = DateTime.now();

    if (filter == 'week') {
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final key = DateFormat('E').format(date);
        final dayTransactions = transactions.where((t) =>
        t.date.year == date.year &&
            t.date.month == date.month &&
            t.date.day == date.day
        ).toList();

        final income = dayTransactions
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (s, t) => s + t.amount);
        final expense = dayTransactions
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (s, t) => s + t.amount);

        result[key] = {'income': income, 'expense': expense};
      }
    } else if (filter == 'month') {
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0);

      for (int week = 0; week < 4; week++) {
        final weekStart = firstDay.add(Duration(days: week * 7));
        final weekEnd = weekStart.add(const Duration(days: 6));

        if (weekStart.isAfter(lastDay)) break;

        final weekTransactions = transactions.where((t) =>
        t.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            t.date.isBefore(weekEnd.add(const Duration(days: 1)))
        ).toList();

        final income = weekTransactions
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (s, t) => s + t.amount);
        final expense = weekTransactions
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (s, t) => s + t.amount);

        result['Week ${week + 1}'] = {'income': income, 'expense': expense};
      }
    } else {
      for (int i = months - 1; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final key = DateFormat('MMM yyyy').format(date);
        final monthTransactions = transactions.where((t) =>
        t.date.month == date.month && t.date.year == date.year
        ).toList();

        final income = monthTransactions
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (s, t) => s + t.amount);
        final expense = monthTransactions
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (s, t) => s + t.amount);

        result[key] = {'income': income, 'expense': expense};
      }
    }

    return result;
  }

  String _getPeriodDisplayLabel() {
    switch (_periodFilter) {
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case '3months':
        return 'Last 3 Months';
      case '6months':
        return 'Last 6 Months';
      case 'year':
        return 'Last 12 Months';
      default:
        return 'Selected Period';
    }
  }

  Widget _buildPeriodStatCard(String label, double value, Currency currency, Color color) {
    return Column(
      children: [
        Text(
          '${currency.symbol} ${_formatNumber(value)}',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
      ],
    );
  }

  // ==================== SAVINGS TAB ====================

  Widget _buildSavingsTab(Currency currency, ThemeProvider theme) {
    if (_savingsFilter != 'week' &&
        _savingsFilter != 'month' &&
        _savingsFilter != '3months' &&
        _savingsFilter != '6months' &&
        _savingsFilter != 'year') {
      _savingsFilter = 'week';
    }

    int getPeriodCount() {
      switch (_savingsFilter) {
        case 'week':
          return 1;
        case 'month':
          return 1;
        case '3months':
          return 3;
        case '6months':
          return 6;
        case 'year':
          return 12;
        default:
          return 1;
      }
    }

    getPeriodCount();
    final transactions = _filterTransactions(_savingsFilter);
    final trend = _getEnhancedSavingsTrend(transactions, _savingsFilter);
    final insights = _generateSavingsInsights(trend);

    final spots = <FlSpot>[];
    for (int i = 0; i < trend.length; i++) {
      final savings = trend[i]['savings'];
      spots.add(FlSpot(i.toDouble(), (savings ?? 0).toDouble()));
    }

    final totalItems = trend.length;

    int getLabelInterval() {
      switch (_savingsFilter) {
        case 'week':
          return 1;
        case 'month':
          return (totalItems > 7) ? 2 : 1;
        case '3months':
          return 1;
        case '6months':
          return (totalItems > 6) ? 2 : 1;
        case 'year':
          return (totalItems > 8) ? 2 : 1;
        default:
          return 1;
      }
    }

    final labelInterval = getLabelInterval();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('This Week', 'week', 'savings', theme.primaryColor),
                _buildFilterChip('This Month', 'month', 'savings', theme.primaryColor),
                _buildFilterChip('3 Months', '3months', 'savings', theme.primaryColor),
                _buildFilterChip('6 Months', '6months', 'savings', theme.primaryColor),
                _buildFilterChip('1 Year', 'year', 'savings', theme.primaryColor),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _modernCardDecoration(theme),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.savings, color: theme.primaryColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text('Savings Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getSavingsPeriodLabel(),
                              style: TextStyle(fontSize: 11, color: theme.primaryColor, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildModernSavingsChart(spots, currency, theme, trend, labelInterval),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _modernCardDecoration(theme),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSavingsStatCard(
                          'Total Savings',
                          _calculateTotalSavings(trend),
                          currency,
                          theme.primaryColor,
                        ),
                      ),
                      Container(width: 1, height: 50, color: Colors.grey[300]),
                      Expanded(
                        child: _buildSavingsStatCard(
                          'Avg ${_getSavingsAverageLabel()}',
                          _calculateAvgSavings(trend),
                          currency,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _modernCardDecoration(theme),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.energy_savings_leaf_outlined, color: theme.primaryColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text('AI Savings Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...insights.map((i) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: i['color'].withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: i['color'].withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: i['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(i['icon'], color: i['color'], size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(i['title'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: i['color'])),
                                  const SizedBox(height: 4),
                                  Text(i['message'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getEnhancedSavingsTrend(List<Transaction> transactions, String filter) {
    final List<Map<String, dynamic>> trend = [];
    final now = DateTime.now();

    if (filter == 'week') {
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayTransactions = transactions.where((t) =>
        t.date.year == date.year &&
            t.date.month == date.month &&
            t.date.day == date.day
        ).toList();

        final income = dayTransactions
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (s, t) => s + t.amount);
        final expense = dayTransactions
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (s, t) => s + t.amount);

        trend.add({
          'month': DateFormat('E').format(date),
          'income': income,
          'expense': expense,
          'savings': income - expense,
          'savingsRate': income > 0 ? ((income - expense) / income * 100) : 0,
        });
      }
    } else if (filter == 'month') {
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0);

      for (int week = 0; week < 4; week++) {
        final weekStart = firstDay.add(Duration(days: week * 7));
        final weekEnd = weekStart.add(const Duration(days: 6));

        if (weekStart.isAfter(lastDay)) break;

        final weekTransactions = transactions.where((t) =>
        t.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            t.date.isBefore(weekEnd.add(const Duration(days: 1)))
        ).toList();

        final income = weekTransactions
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (s, t) => s + t.amount);
        final expense = weekTransactions
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (s, t) => s + t.amount);

        trend.add({
          'month': 'Week ${week + 1}',
          'income': income,
          'expense': expense,
          'savings': income - expense,
          'savingsRate': income > 0 ? ((income - expense) / income * 100) : 0,
        });
      }
    } else {
      int months = filter == '3months' ? 3 : (filter == '6months' ? 6 : 12);

      for (int i = months - 1; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthTx = transactions.where((t) =>
        t.date.month == month.month && t.date.year == month.year
        ).toList();

        final income = monthTx
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (s, t) => s + t.amount);
        final expense = monthTx
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (s, t) => s + t.amount);

        trend.add({
          'month': DateFormat('MMM').format(month),
          'income': income,
          'expense': expense,
          'savings': income - expense,
          'savingsRate': income > 0 ? ((income - expense) / income * 100) : 0,
        });
      }
    }

    return trend;
  }

  String _getSavingsPeriodLabel() {
    switch (_savingsFilter) {
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case '3months':
        return 'Last 3 Months';
      case '6months':
        return 'Last 6 Months';
      case 'year':
        return 'Last 12 Months';
      default:
        return 'Selected Period';
    }
  }

  String _getSavingsAverageLabel() {
    switch (_savingsFilter) {
      case 'week':
        return 'Daily';
      case 'month':
        return 'Weekly';
      case '3months':
        return 'Monthly';
      case '6months':
        return 'Monthly';
      case 'year':
        return 'Monthly';
      default:
        return 'Monthly';
    }
  }

  Widget _buildModernSavingsChart(List<FlSpot> spots, Currency currency, ThemeProvider theme, List<Map<String, dynamic>> trend, int labelInterval) {
    if (spots.isEmpty) {
      return _buildEmptyState('No savings data', Icons.trending_up, theme);
    }

    final values = spots.map((e) => e.y).toList();
    final maxY = values.reduce(math.max);
    final minY = values.reduce(math.min);
    final range = maxY - minY;
    final padding = range * 0.15;
    final adjustedMax = maxY + padding;
    final adjustedMin = minY - padding;

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: value == 0 ? Colors.grey[400]! : Colors.grey[200]!,
                strokeWidth: value == 0 ? 2 : 1,
                dashArray: value == 0 ? null : [5, 5],
              );
            },
          ),
          minY: adjustedMin,
          maxY: adjustedMax,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '${currency.symbol}${_formatCompactNumber(value)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: value < 0 ? AppColors.error : AppColors.textLight,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: labelInterval.toDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < trend.length && (index % labelInterval == 0 || index == trend.length - 1)) {
                    final label = trend[index]['month'] ?? trend[index]['week'] ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        label,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: theme.primaryColor,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: spot.y >= 0 ? AppColors.success : AppColors.error,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor.withOpacity(0.2),
                    theme.primaryColor.withOpacity(0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.spotIndex;
                  final label = trend[index]['month'] ?? trend[index]['week'] ?? '';
                  return LineTooltipItem(
                    '$label: ${currency.symbol} ${_formatNumber(spot.y)}',
                    TextStyle(
                      color: spot.y >= 0 ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  double _calculateTotalSavings(List<Map<String, dynamic>> trend) {
    double total = 0;
    for (var item in trend) {
      final savings = item['savings'];
      if (savings != null) {
        total += (savings as num).toDouble();
      }
    }
    return total;
  }

  double _calculateAvgSavings(List<Map<String, dynamic>> trend) {
    if (trend.isEmpty) return 0;
    return _calculateTotalSavings(trend) / trend.length;
  }

  Widget _buildSavingsStatCard(String label, double value, Currency currency, Color color) {
    return Column(
      children: [
        Text(
          '${currency.symbol} ${_formatNumber(value)}',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
      ],
    );
  }

  // ==================== BUDGET TAB ====================

  Widget _buildBudgetTab(Currency currency, ThemeProvider theme) {
    final transactions = _filterTransactions('month');
    final analysis = _analyzeBudgets(transactions);
    final insights = _generateBudgetInsights(analysis, transactions);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (analysis['totalBudget'] == 0)
            _buildEmptyState('No budgets created', Icons.account_balance_wallet, theme)
          else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _modernCardDecoration(theme),
              child: Row(
                children: [
                  _buildBudgetCircularGauge(
                    analysis['totalSpent'] / analysis['totalBudget'],
                    analysis['totalBudget'],
                    analysis['totalSpent'],
                    currency,
                    theme,
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBudgetStatRow('Total Budget', analysis['totalBudget'], currency, theme.primaryColor),
                        const SizedBox(height: 12),
                        _buildBudgetStatRow('Spent', analysis['totalSpent'], currency, AppColors.primaryBlue),
                        const SizedBox(height: 12),
                        _buildBudgetStatRow('Remaining', analysis['remaining'], currency,
                            analysis['remaining'] >= 0 ? AppColors.success : AppColors.error),
                        const SizedBox(height: 12),
                        _buildBudgetStatRow('Projected', analysis['projected'], currency,
                            analysis['projected'] > analysis['totalBudget'] ? AppColors.error : AppColors.warning),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: _modernCardDecoration(theme),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBudgetStatusChip('On Track', analysis['onTrack'], AppColors.success),
                      _buildBudgetStatusChip('Warning', analysis['warning'], AppColors.warning),
                      _buildBudgetStatusChip('Exceeded', analysis['exceeded'], AppColors.error),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Budget Health', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
                      Text(
                        '${analysis['healthScore'].toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: analysis['healthScore'] > 80 ? AppColors.success :
                          analysis['healthScore'] > 50 ? AppColors.warning : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (analysis['healthScore'] / 100).clamp(0, 1),
                      minHeight: 10,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        analysis['healthScore'] > 80 ? AppColors.success :
                        analysis['healthScore'] > 50 ? AppColors.warning : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            ...analysis['budgets'].map<Widget>((b) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: _modernCardDecoration(theme),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b['category'],
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${currency.symbol}${_formatNumber(b['spent'])} / ${currency.symbol}${_formatNumber(b['limit'])}',
                              style: TextStyle(fontSize: 14, color: AppColors.textLight),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: b['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: b['color'].withOpacity(0.3)),
                        ),
                        child: Text(
                          b['status'],
                          style: TextStyle(
                            fontSize: 12,
                            color: b['color'],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Progress', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
                                Text(
                                  '${b['progress'].toStringAsFixed(1)}%',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: b['color']),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (b['progress'] / 100).clamp(0, 1),
                                minHeight: 8,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(b['color']),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Daily Avg', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                            Text(
                              '${currency.symbol}${_formatNumber(b['dailyAvg'])}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text('Projected', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                            Text(
                              '${currency.symbol}${_formatNumber(b['projected'])}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: b['projected'] > b['limit'] ? AppColors.error : AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )).toList(),

            if (insights.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: _modernCardDecoration(theme),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.lightbulb, color: theme.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text('Budget Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...insights.map((i) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: i['color'].withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: i['color'].withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: i['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(i['icon'], color: i['color'], size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(i['title'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: i['color'])),
                                const SizedBox(height: 4),
                                Text(i['message'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildBudgetStatRow(String label, double value, Currency currency, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        Text(
          '${currency.symbol} ${_formatNumber(value)}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildBudgetStatusChip(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ==================== GOALS TAB ====================

  Widget _buildGoalsTab(Currency currency, ThemeProvider theme) {
    final analysis = _analyzeGoals();
    final insights = _generateGoalInsights(analysis);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (analysis['totalTarget'] == 0)
            _buildEmptyState('No savings goals created', Icons.flag, theme)
          else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _modernCardDecoration(theme),
              child: Row(
                children: [
                  _buildGoalsCircularGauge(
                    analysis['overallProgress'],
                    analysis['totalTarget'],
                    analysis['totalCurrent'],
                    currency,
                    theme,
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGoalStatRow('Total Target', analysis['totalTarget'], currency, theme.primaryColor),
                        const SizedBox(height: 12),
                        _buildGoalStatRow('Saved', analysis['totalCurrent'], currency, AppColors.success),
                        const SizedBox(height: 12),
                        _buildGoalStatRow('Remaining', analysis['totalRemaining'], currency, AppColors.warning),
                        const SizedBox(height: 12),
                        _buildGoalStatRow('Projected', analysis['projectedCompletion'], currency, Colors.purple, isText: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: _modernCardDecoration(theme),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildGoalStatusChip('Completed', analysis['completed'], AppColors.success),
                  _buildGoalStatusChip('On Track', analysis['onTrack'], theme.primaryColor),
                  _buildGoalStatusChip('Behind', analysis['behind'], AppColors.warning),
                ],
              ),
            ),
            const SizedBox(height: 16),

            ...analysis['goals'].map<Widget>((g) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: _modernCardDecoration(theme),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g['name'],
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${currency.symbol}${_formatNumber(g['current'])} / ${currency.symbol}${_formatNumber(g['target'])}',
                              style: TextStyle(fontSize: 14, color: AppColors.textLight),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: g['isBehind'] ? AppColors.warning.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: g['isBehind'] ? AppColors.warning.withOpacity(0.3) : AppColors.success.withOpacity(0.3)),
                        ),
                        child: Text(
                          g['isBehind'] ? 'Behind' : 'On Track',
                          style: TextStyle(
                            fontSize: 12,
                            color: g['isBehind'] ? AppColors.warning : AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Progress', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
                                Text(
                                  '${g['progress'].toStringAsFixed(1)}%',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: g['color']),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (g['progress'] / 100).clamp(0, 1),
                                minHeight: 8,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(g['color']),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Days Left', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                            Text(
                              '${g['daysLeft']}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text('Required/Day', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                            Text(
                              '${currency.symbol}${_formatNumber(g['requiredDaily'])}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: g['isBehind'] ? AppColors.error : AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (g['isBehind'] && g['daysLeft'] > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, color: AppColors.warning, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Need ${currency.symbol}${_formatNumber(g['requiredDaily'])} per day to catch up',
                                style: TextStyle(fontSize: 13, color: AppColors.warning, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            )).toList(),

            if (insights.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: _modernCardDecoration(theme),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.auto_awesome, color: theme.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text('Goal Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...insights.map((i) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: i['color'].withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: i['color'].withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: i['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(i['icon'], color: i['color'], size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(i['title'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: i['color'])),
                                const SizedBox(height: 4),
                                Text(i['message'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildGoalStatRow(String label, dynamic value, Currency currency, Color color, {bool isText = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        Text(
          isText ? value.toString() : '${currency.symbol} ${_formatNumber(value)}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildGoalStatusChip(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ==================== DISTRIBUTION TAB ====================

  Widget _buildDistributionTab(Currency currency, ThemeProvider theme) {
    if (_distributionFilter != 'all' &&
        _distributionFilter != 'week' &&
        _distributionFilter != 'month' &&
        _distributionFilter != '3months' &&
        _distributionFilter != '6months' &&
        _distributionFilter != 'year' &&
        _distributionFilter != 'custom') {
      _distributionFilter = 'week';
    }

    final transactions = _filterTransactions(_distributionFilter, start: _customStartDate, end: _customEndDate);
    final expenseData = _getCategoryBreakdown(transactions);
    final incomeData = _getIncomeBreakdown(transactions);

    if (_touchedExpensePieIndex != null && (_touchedExpensePieIndex! >= expenseData.length || expenseData.isEmpty)) {
      _touchedExpensePieIndex = null;
      _selectedExpenseSection = null;
    }
    if (_touchedIncomePieIndex != null && (_touchedIncomePieIndex! >= incomeData.length || incomeData.isEmpty)) {
      _touchedIncomePieIndex = null;
      _selectedIncomeSection = null;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Time', 'all', 'distribution', theme.primaryColor),
                _buildFilterChip('This Week', 'week', 'distribution', theme.primaryColor),
                _buildFilterChip('This Month', 'month', 'distribution', theme.primaryColor),
                _buildFilterChip('3 Months', '3months', 'distribution', theme.primaryColor),
                _buildFilterChip('6 Months', '6months', 'distribution', theme.primaryColor),
                _buildFilterChip('1 Year', 'year', 'distribution', theme.primaryColor),
                _buildFilterChip('Custom', 'custom', 'distribution', theme.primaryColor),
                if (_customStartDate != null)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${DateFormat('MMM d').format(_customStartDate!)} - ${DateFormat('MMM d').format(_customEndDate!)}',
                          style: TextStyle(fontSize: 12, color: theme.primaryColor, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(() {
                            _distributionFilter = 'week';
                            _customStartDate = null;
                            _customEndDate = null;
                            _touchedExpensePieIndex = null;
                            _touchedIncomePieIndex = null;
                            _selectedExpenseSection = null;
                            _selectedIncomeSection = null;
                          }),
                          child: Icon(Icons.close, size: 16, color: theme.primaryColor),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (expenseData.isNotEmpty) ...[
                  _buildEnhancedDistributionPieChart(
                    title: 'Expenses',
                    data: expenseData,
                    currency: currency,
                    theme: theme,
                    isExpense: true,
                  ),
                  const SizedBox(height: 20),
                ],
                if (incomeData.isNotEmpty) ...[
                  _buildEnhancedDistributionPieChart(
                    title: 'Income',
                    data: incomeData,
                    currency: currency,
                    theme: theme,
                    isExpense: false,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedDistributionPieChart({
    required String title,
    required Map<String, double> data,
    required Currency currency,
    required ThemeProvider theme,
    required bool isExpense,
  }) {
    final total = data.values.fold(0.0, (s, v) => s + v);
    final touchedIndex = isExpense ? _touchedExpensePieIndex : _touchedIncomePieIndex;
    final selectedSection = isExpense ? _selectedExpenseSection : _selectedIncomeSection;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _modernCardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isExpense ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isExpense ? Icons.shopping_cart : Icons.attach_money,
                  color: isExpense ? AppColors.error : AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isExpense ? AppColors.error : AppColors.success,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getDistributionPeriodLabel(),
                  style: TextStyle(fontSize: 11, color: theme.primaryColor, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Center(
            child: SizedBox(
              height: 194,
              width: 194,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 48,
                  sections: List.generate(min(data.length, 7), (i) {
                    final entry = data.entries.elementAt(i);
                    final percentage = entry.value / total * 100;
                    return PieChartSectionData(
                      value: entry.value,
                      title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                      radius: 70,
                      color: _getCategoryColor(entry.key),
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }),
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          if (isExpense) {
                            _touchedExpensePieIndex = null;
                            _selectedExpenseSection = null;
                          } else {
                            _touchedIncomePieIndex = null;
                            _selectedIncomeSection = null;
                          }
                          return;
                        }

                        final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        if (index >= 0 && index < min(data.length, 7)) {
                          final categoryKey = data.entries.elementAt(index).key;
                          if (isExpense) {
                            _touchedExpensePieIndex = index;
                            _selectedExpenseSection = {
                              'category': categoryKey,
                              'amount': data.entries.elementAt(index).value,
                              'percentage': (data.entries.elementAt(index).value / total * 100),
                              'color': _getCategoryColor(categoryKey),
                              'emoji': _getCategoryEmoji(categoryKey),
                            };
                          } else {
                            _touchedIncomePieIndex = index;
                            _selectedIncomeSection = {
                              'category': categoryKey,
                              'amount': data.entries.elementAt(index).value,
                              'percentage': (data.entries.elementAt(index).value / total * 100),
                              'color': _getCategoryColor(categoryKey),
                              'emoji': _getCategoryEmoji(categoryKey),
                            };
                          }
                        }
                      });
                    },
                    enabled: true,
                  ),
                ),
              ),
            ),
          ),

          if (selectedSection != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selectedSection['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selectedSection['color'].withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selectedSection['color'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        selectedSection['emoji'] ?? '📦',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedSection['category'],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${selectedSection['percentage'].toStringAsFixed(1)}% of total',
                          style: TextStyle(fontSize: 13, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${currency.symbol} ${_formatNumber(selectedSection['amount'])}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: selectedSection['color'],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          ...data.entries.take(5).map((e) {
            final color = _getCategoryColor(e.key);
            final percentage = (e.value / total * 100);
            final emoji = _getCategoryEmoji(e.key);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isExpense) {
                    _selectedExpenseSection = {
                      'category': e.key,
                      'amount': e.value,
                      'percentage': percentage,
                      'color': color,
                      'emoji': emoji,
                    };
                    _touchedExpensePieIndex = data.keys.toList().indexOf(e.key);
                  } else {
                    _selectedIncomeSection = {
                      'category': e.key,
                      'amount': e.value,
                      'percentage': percentage,
                      'color': color,
                      'emoji': emoji,
                    };
                    _touchedIncomePieIndex = data.keys.toList().indexOf(e.key);
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: _isSelected(e.key, isExpense) ? color.withOpacity(0.05) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        e.key,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Text(
                      '${currency.symbol}${_formatNumber(e.value)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

          if (data.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: GestureDetector(
                onTap: () => _showAllCategoriesSheet(
                  data,
                  total,
                  currency,
                  theme,
                  isExpense,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: theme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Show all ${data.length} categories',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isSelected(String category, bool isExpense) {
    if (isExpense && _selectedExpenseSection != null) {
      return _selectedExpenseSection!['category'] == category;
    }
    if (!isExpense && _selectedIncomeSection != null) {
      return _selectedIncomeSection!['category'] == category;
    }
    return false;
  }

  String _getDistributionPeriodLabel() {
    switch (_distributionFilter) {
      case 'all':
        return 'All Time';
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case '3months':
        return 'Last 3 Months';
      case '6months':
        return 'Last 6 Months';
      case 'year':
        return 'Last 12 Months';
      case 'custom':
        return 'Custom Range';
      default:
        return 'Selected Period';
    }
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildFilterChip(String label, String value, String group, Color activeColor) {
    bool isSelected;
    Function(String) onSelected;

    switch (group) {
      case 'overview':
        isSelected = _overviewFilter == value;
        onSelected = (v) => setState(() {
          _overviewFilter = v;
          _touchedExpensePieIndex = null;
          _touchedIncomePieIndex = null;
          _selectedExpenseSection = null;
          _selectedIncomeSection = null;
        });
        break;
      case 'cashflow':
        isSelected = _cashFlowFilter == value;
        onSelected = (v) => setState(() {
          _cashFlowFilter = v;
          _touchedExpensePieIndex = null;
          _touchedIncomePieIndex = null;
          _selectedExpenseSection = null;
          _selectedIncomeSection = null;
        });
        break;
      case 'period':
        isSelected = _periodFilter == value;
        onSelected = (v) => setState(() {
          _periodFilter = v;
          _touchedExpensePieIndex = null;
          _touchedIncomePieIndex = null;
          _selectedExpenseSection = null;
          _selectedIncomeSection = null;
        });
        break;
      case 'distribution':
        isSelected = _distributionFilter == value;
        onSelected = (v) {
          if (v == 'custom') {
            _pickDateRange();
          } else {
            setState(() {
              _distributionFilter = v;
              _customStartDate = null;
              _customEndDate = null;
              _touchedExpensePieIndex = null;
              _touchedIncomePieIndex = null;
              _selectedExpenseSection = null;
              _selectedIncomeSection = null;
            });
          }
        };
        break;
      case 'savings':
        isSelected = _savingsFilter == value;
        onSelected = (v) => setState(() {
          _savingsFilter = v;
          _touchedExpensePieIndex = null;
          _touchedIncomePieIndex = null;
          _selectedExpenseSection = null;
          _selectedIncomeSection = null;
        });
        break;
      default:
        isSelected = false;
        onSelected = (_) {};
    }

    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Provider.of<ThemeProvider>(context).primaryColor,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _distributionFilter = 'custom';
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _touchedExpensePieIndex = null;
        _touchedIncomePieIndex = null;
        _selectedExpenseSection = null;
        _selectedIncomeSection = null;
      });
    }
  }

  Widget _buildForecastCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: _modernCardDecoration(theme),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: theme.primaryColor.withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  BoxDecoration _modernCardDecoration(ThemeProvider theme) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
        BoxShadow(
          color: theme.primaryColor.withOpacity(0.05),
          blurRadius: 25,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  // ==================== UTILITY METHODS ====================

  int _getMonthCount(String filter) {
    switch (filter) {
      case '3months': return 3;
      case '6months': return 6;
      case 'year': return 12;
      default: return 6;
    }
  }

  String _formatNumber(double number) {
    if (number >= 10000000) return '${(number / 10000000).toStringAsFixed(1)}Cr';
    if (number >= 100000) return '${(number / 100000).toStringAsFixed(1)}L';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return NumberFormat('#,##,###').format(number);
  }

  String _formatCompactNumber(double number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toStringAsFixed(0);
  }

  double _roundUpToNiceNumber(double value) {
    if (value <= 0) return 100;
    double magnitude = math.pow(10, (math.log(value) / math.ln10).floor()).toDouble();
    double normalized = value / magnitude;
    if (normalized <= 1) return magnitude;
    if (normalized <= 2) return 2 * magnitude;
    if (normalized <= 5) return 5 * magnitude;
    return 10 * magnitude;
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

// Custom painter for modern circular gauge
class _ModernGaugePainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  _ModernGaugePainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 12.0;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    final glowPaint = Paint()
      ..color = progressColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

extension on DateTime {
  int get daysInMonth => DateTime(year, month + 1, 0).day;
}