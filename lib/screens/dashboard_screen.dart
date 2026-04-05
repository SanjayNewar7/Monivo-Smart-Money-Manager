import 'dart:io';
import 'package:bluewallet_np/widgets/ai_chat_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
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
import 'spending_insights_screen.dart';
import 'personality_insights_screen.dart';
import 'analytics_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Transaction> _transactions = [];
  List<Account> _accounts = [];
  List<Budget> _budgets = [];
  List<SavingsGoal> _goals = [];
  List<Category> _categories = [];
  UserProfile? _user;
  double _totalIncome = 0;
  double _totalExpenses = 0;
  double _currentBalance = 0;
  bool _isLoading = true;
  late Map<String, dynamic> _personalityAnalysis;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = await StorageService.getUser();
      final transactions = await StorageService.getTransactions();
      final accounts = await StorageService.getAccounts();
      final budgets = await StorageService.getBudgets();
      final goals = await StorageService.getSavingsGoals();
      final categories = await StorageService.getCategories();

      final now = DateTime.now();
      final currentMonthTransactions = transactions.where((t) =>
      t.date.month == now.month && t.date.year == now.year);

      final totalIncome = currentMonthTransactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);

      final totalExpenses = currentMonthTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);

      final currentBalance = accounts.fold(0.0, (sum, acc) => sum + acc.balance);

      _personalityAnalysis = PersonalityService.analyzeSpendingPersonality(
        transactions: transactions,
        budgets: budgets,
        goals: goals,
        monthlyIncome: totalIncome,
        monthlyExpenses: totalExpenses,
        totalBalance: currentBalance,
        currency: user?.preferredCurrency,
      );

      if (mounted) {
        setState(() {
          _user = user;
          _transactions = transactions;
          _accounts = accounts;
          _budgets = budgets;
          _goals = goals;
          _categories = categories;
          _totalIncome = totalIncome;
          _totalExpenses = totalExpenses;
          _currentBalance = currentBalance;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  List<Transaction> get _recentTransactions {
    final sorted = List<Transaction>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(5).toList();
  }

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

  String _getBudgetStatusText() {
    if (_budgets.isEmpty) return 'No Budgets';
    final exceeded = _budgets.where((b) => b.isExceeded).length;
    if (exceeded > 0) return '$exceeded Exceeded';
    final warning = _budgets.where((b) => b.isWarning).length;
    if (warning > 0) return '$warning Near Limit';
    return 'On Track';
  }

  Color _getBudgetStatusColor(ThemeProvider themeProvider) {
    if (_budgets.isEmpty) return AppColors.textLight;
    final exceeded = _budgets.where((b) => b.isExceeded).length;
    if (exceeded > 0) return AppColors.error;
    final warning = _budgets.where((b) => b.isWarning).length;
    if (warning > 0) return AppColors.warning;
    return themeProvider.primaryColor;
  }

  String _getGoalStatusText() {
    if (_goals.isEmpty) return 'No Goals';
    final behind = _goals.where((g) => g.isBehind).length;
    if (behind > 0) return '$behind Behind';
    final completed = _goals.where((g) => g.progress >= 100).length;
    if (completed > 0) return '$completed Completed';
    return 'On Track';
  }

  Color _getGoalStatusColor(ThemeProvider themeProvider) {
    if (_goals.isEmpty) return AppColors.textLight;
    final behind = _goals.where((g) => g.isBehind).length;
    if (behind > 0) return AppColors.warning;
    final completed = _goals.where((g) => g.progress >= 100).length;
    if (completed > 0) return AppColors.success;
    return themeProvider.primaryColor;
  }

  Color _getSecondaryColor(Color primary) {
    if (primary == AppColors.primaryBlue) return AppColors.accentTeal;
    if (primary == const Color(0xFF34C759)) return const Color(0xFF74C69D);
    if (primary == const Color(0xFFAF52DE)) return const Color(0xFFD291FF);
    if (primary == const Color(0xFF1C1C1E)) return const Color(0xFF3A3A3C);
    return AppColors.accentTeal;
  }

  Widget _buildBalanceChip(String label, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$label: $amount',
              style: const TextStyle(fontSize: 11, color: Colors.white),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Returns Container instead of Expanded to prevent nested Expanded issue
  Widget _buildQuickStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingInsights(Currency currency, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Spending Insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SpendingInsightsScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: themeProvider.primaryColor,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View Details'),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInsightItem(
                  'Top Category',
                  _getTopCategory(),
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[200],
              ),
              Expanded(
                child: _buildInsightItem(
                  'Daily Avg',
                  CurrencyFormatter.format(
                      _totalExpenses / (DateTime.now().day > 0 ? DateTime.now().day : 1),
                      currency
                  ),
                  Icons.calendar_today,
                  themeProvider.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalitySection(Currency currency, ThemeProvider themeProvider) {
    final primaryPersonality = _personalityAnalysis['primary'] as String;
    final secondaryPersonality = _personalityAnalysis['secondary'] as String;
    final reasoning = _personalityAnalysis['reasoning'] as String;
    final scores = _personalityAnalysis['scores'] as Map<String, double>;
    final metrics = _personalityAnalysis['metrics'] as Map<String, dynamic>;
    final topTraits = _getTopTraits(scores);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeProvider.primaryColor,
            _getSecondaryColor(themeProvider.primaryColor),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: themeProvider.primaryColor.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.psychology,
                        color: themeProvider.primaryColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'YOUR STYLE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: themeProvider.primaryColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'also $secondaryPersonality',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            primaryPersonality.replaceFirst('The ', ''),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricChip(
                        'Savings',
                        '${metrics['savingsRate'].toStringAsFixed(0)}%',
                        Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricChip(
                        'Emergency',
                        '${metrics['emergencyFundMonths'].toStringAsFixed(1)}mo',
                        Icons.security,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricChip(
                        'Budget',
                        '${metrics['budgetAdherence'].toStringAsFixed(0)}%',
                        Icons.pie_chart,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      ...topTraits.map((trait) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTraitMeter(
                          trait['name'] as String,
                          trait['score'] as double,
                        ),
                      )).toList(),
                      const SizedBox(height: 12),
                      Text(
                        reasoning,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          height: 1.4,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        'View Full Analysis',
                        Icons.trending_up,
                        themeProvider,
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PersonalityInsightsScreen(
                                analysis: _personalityAnalysis,
                                currency: _user?.preferredCurrency ?? Currency.npr,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getTopTraits(Map<String, double> scores) {
    final List<Map<String, dynamic>> traits = [];
    scores.forEach((key, value) {
      traits.add({
        'name': key.replaceFirst('The ', ''),
        'score': (value / 100).clamp(0, 1).toDouble(),
      });
    });
    traits.sort((a, b) => b['score'].compareTo(a['score']));
    return traits.take(3).toList();
  }

  Widget _buildMetricChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withOpacity(0.8),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildTraitMeter(String trait, double score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              trait,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${(score * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: score,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFE0E0E0)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, ThemeProvider themeProvider, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: themeProvider.primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: themeProvider.primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.primaryColor,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetAndGoalsSection(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Budgets & Goals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/budgets');
                },
                style: TextButton.styleFrom(
                  foregroundColor: themeProvider.primaryColor,
                ),
                child: const Text('Manage'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.pie_chart,
                  color: themeProvider.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Budgets',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_budgets.length} active budgets',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getBudgetStatusColor(themeProvider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getBudgetStatusText(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flag,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Savings Goals',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_goals.length} active goals',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getGoalStatusColor(themeProvider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getGoalStatusText(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          if (_budgets.isNotEmpty || _goals.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Add Money',
                    Icons.add_circle,
                    themeProvider.primaryColor,
                        () {
                      if (_goals.isNotEmpty) {
                        Navigator.pushNamed(context, '/budgets');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Create a savings goal first'),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    'Adjust Budget',
                    Icons.tune,
                    _getSecondaryColor(themeProvider.primaryColor),
                        () {
                      Navigator.pushNamed(context, '/budgets');
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(Currency currency, ThemeProvider themeProvider) {
    final recentTransactions = _recentTransactions;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_transactions.isNotEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/transactions');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: themeProvider.primaryColor,
                  ),
                  child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (_transactions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        size: 40,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No transactions yet!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Record your first transaction to start tracking',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.pushNamed(context, '/add-transaction');
                        if (result == true) {
                          await _refreshData();
                        }
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Transaction'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (recentTransactions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No recent transactions',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                ...recentTransactions.map((transaction) {
                  return _buildTransactionItem(transaction, currency);
                }).toList(),
                if (_transactions.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: Text(
                        '+ ${_transactions.length - 5} more transactions',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction, Currency currency) {
    try {
      final isIncome = transaction.type == TransactionType.income;
      final icon = _getCategoryIcon(transaction.category);

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isIncome
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.category,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.note.isNotEmpty ? transaction.note : 'No description',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.account,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount, currency)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isIncome ? AppColors.success : AppColors.error,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d').format(transaction.date),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error building transaction item: $e');
      return const SizedBox.shrink();
    }
  }

  String _getTopCategory() {
    if (_transactions.isEmpty) return 'N/A';
    final expenseTransactions = _transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    if (expenseTransactions.isEmpty) return 'N/A';
    final Map<String, double> categoryTotals = {};
    for (var t in expenseTransactions) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }
    return categoryTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MainLayout(
        currentIndex: 0,
        child: const Scaffold(
          backgroundColor: AppColors.lightGray,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final currency = _user?.preferredCurrency ?? Currency.npr;
    final monthlySavings = _totalIncome - _totalExpenses;

    return MainLayout(
      currentIndex: 0,
      child: Scaffold(
        backgroundColor: AppColors.lightGray,
        body: RefreshIndicator(
          onRefresh: _refreshData,
          color: themeProvider.primaryColor,
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 280,
                    pinned: false,
                    automaticallyImplyLeading: false,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              themeProvider.primaryColor,
                              _getSecondaryColor(themeProvider.primaryColor),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hi, ${_user?.name?.split(' ').first ?? 'User'}!',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('EEEE, MMMM d').format(DateTime.now()),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(context, '/profile');
                                      },
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                          image: _user?.profileImagePath != null
                                              ? DecorationImage(
                                            image: FileImage(File(_user!.profileImagePath!)),
                                            fit: BoxFit.cover,
                                          )
                                              : null,
                                        ),
                                        child: _user?.profileImagePath == null
                                            ? const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                        )
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Current Balance',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        CurrencyFormatter.format(_currentBalance, currency),
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildBalanceChip(
                                              'Income',
                                              CurrencyFormatter.format(_totalIncome, currency),
                                              Icons.arrow_upward,
                                              Colors.green.shade700,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildBalanceChip(
                                              'Expenses',
                                              CurrencyFormatter.format(_totalExpenses, currency),
                                              Icons.arrow_downward,
                                              Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Quick Stats - FIXED: Expanded is now properly placed
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickStatCard(
                                title: 'Monthly Savings',
                                value: CurrencyFormatter.format(monthlySavings, currency),
                                icon: Icons.savings,
                                color: Colors.green,
                                subtitle: monthlySavings > 0
                                    ? '+${((monthlySavings / (_totalIncome > 0 ? _totalIncome : 1)) * 100).toStringAsFixed(1)}%'
                                    : '0%',
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AnalyticsScreen(),
                                      settings: const RouteSettings(arguments: {'tab': 'savings'}),
                                    ),
                                  );
                                  if (result == true) await _refreshData();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickStatCard(
                                title: 'Transactions',
                                value: _transactions.length.toString(),
                                icon: Icons.swap_horiz,
                                color: themeProvider.primaryColor,
                                subtitle: 'Total',
                                onTap: null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildSpendingInsights(currency, themeProvider),
                        const SizedBox(height: 20),
                        _buildRecentTransactions(currency, themeProvider),
                        const SizedBox(height: 20),
                        _buildPersonalitySection(currency, themeProvider),
                        const SizedBox(height: 20),
                        _buildBudgetAndGoalsSection(themeProvider),
                        const SizedBox(height: 20),
                        const _FinancialTipsCarousel(),
                        const SizedBox(height: 20),
                      ]),
                    ),
                  ),
                ],
              ),
              // AI Chatbot Button - LEFT SIDE
              // AI Chatbot Button - LEFT SIDE
              Positioned(
                bottom: 16,
                left: 16,
                child: FloatingActionButton(
                  heroTag: 'ai_assistant',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AIChatBottomSheet(),
                    );
                  },
                  backgroundColor: themeProvider.primaryColor, // Now uses theme color
                  child: const Icon(Icons.chat, size: 32, color: Colors.white), // Changed icon to chat, size 32 to match add button
                ),
              ),
              // Add Transaction Button - RIGHT SIDE
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  heroTag: 'add_transaction',
                  onPressed: () async {
                    final result = await Navigator.pushNamed(context, '/add-transaction');
                    if (result == true) await _refreshData();
                  },
                  backgroundColor: themeProvider.primaryColor,
                  child: const Icon(Icons.add, size: 32, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Financial Tips Carousel - Infinite forward scrolling only
class _FinancialTipsCarousel extends StatefulWidget {
  const _FinancialTipsCarousel({Key? key}) : super(key: key);

  @override
  State<_FinancialTipsCarousel> createState() => _FinancialTipsCarouselState();
}

class _FinancialTipsCarouselState extends State<_FinancialTipsCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  late Timer _timer;

  final List<Map<String, dynamic>> _tips = [
    {
      'title': 'Investment Tips',
      'description': '10 Smart Year-End Financial Moves to Make Before 2026',
      'url': 'https://www.futurefocusedwealth.com/blog/10-smart-year-end-financial-moves-before-2026/',
      'color': Colors.deepPurple,
      'icon': Icons.trending_up,
    },
    {
      'title': 'Budgeting 101',
      'description': 'Master your money with simple techniques',
      'url': 'https://www.nerdwallet.com/article/finance/how-to-budget',
      'color': Colors.orange,
      'icon': Icons.account_balance_wallet,
    },
    {
      'title': 'Emergency Fund',
      'description': 'Build a safety net for unexpected expenses',
      'url': 'https://www.bankrate.com/banking/savings/emergency-fund-guide/',
      'color': Colors.teal,
      'icon': Icons.security,
    },
    {
      'title': 'Unlock Your Creativity',
      'description': 'Take a break from finances and explore artistic side with Aakriti',
      'url': 'https://play.google.com/store/apps/details?id=com.sanjaya.aakriti',
      'color': const Color(0xFFFF6B6B),
      'icon': Icons.brush,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _tips.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openLink(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Cannot open link');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: _tips.map((tip) => _buildSlide(tip, theme)).toList(),
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _tips.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? theme.primaryColor
                        : Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(Map<String, dynamic> tip, ThemeData theme) {
    final color = tip['color'] as Color;
    final icon = tip['icon'] as IconData;
    final title = tip['title'] as String;
    final description = tip['description'] as String;
    final url = tip['url'] as String;

    return GestureDetector(
      onTap: () => _openLink(url),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: CustomPaint(painter: _PatternPainter()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title == 'Unlock Your Creativity' ? 'Explore Now' : 'Learn More',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward,
                                size: 12,
                                color: Colors.white.withOpacity(0.9),
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
          ],
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(size.width * (i * 0.2), size.height * 0.3),
        15 + (i * 5).toDouble(),
        paint,
      );
    }

    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(size.width * 0.1, size.height * 0.7),
        Offset(size.width * 0.9, size.height * 0.7 + (i * 10)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}