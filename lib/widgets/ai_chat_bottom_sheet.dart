import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../models/transaction.dart';
import '../models/user_model.dart';
import '../models/budget.dart';
import '../providers/theme_provider.dart';

class AIChatBottomSheet extends StatefulWidget {
  const AIChatBottomSheet({Key? key}) : super(key: key);

  @override
  State<AIChatBottomSheet> createState() => _AIChatBottomSheetState();
}

class _AIChatBottomSheetState extends State<AIChatBottomSheet> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final GeminiService _gemini = GeminiService();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isFirstLoad = true;
  bool _isCheckingConsent = true;
  FinancialContext? _context;
  UserProfile? _user;

  final List<String> _suggestions = [
    'How can I save more money this month?',
    'Am I spending too much on dining out?',
    'Is my savings rate good enough?',
    'How to reach my goal faster?',
    'Where can I cut expenses?',
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUserAndCheckConsent();
    await _loadContext();
    setState(() {
      _isCheckingConsent = false;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _loadUserAndCheckConsent() async {
    final user = await StorageService.getUser();
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  Future<void> _saveConsentToUser(bool enabled) async {
    if (_user != null) {
      final updatedUser = _user!.copyWith(aiAssistantEnabled: enabled);
      await StorageService.saveUser(updatedUser);
      if (mounted) {
        setState(() {
          _user = updatedUser;
        });
      }
    }
  }

  Future<void> _showConsentDialog() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: constraints.maxWidth * 0.9,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeProvider.primaryColor,
                          _getSecondaryColor(themeProvider.primaryColor),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'AI Financial Assistant',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'Monivo AI uses Google Gemini to provide personalized financial insights.',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Your financial data is used only to generate responses and is not stored permanently.',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, size: 20, color: Colors.amber),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'AI provides educational information only, not professional financial advice.',
                                  style: TextStyle(fontSize: 12, color: Colors.amber),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context, false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey,
                                  side: const BorderSide(color: Colors.grey),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Not Now'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeProvider.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Enable'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    if (result == true) {
      await _saveConsentToUser(true);
      await _loadContext();
      if (mounted) {
        setState(() {});
      }
    } else {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _loadContext() async {
    final user = await StorageService.getUser();
    final transactions = await StorageService.getTransactions();
    final budgets = await StorageService.getBudgets();
    final goals = await StorageService.getSavingsGoals();
    final accounts = await StorageService.getAccounts();

    // Get currency from user
    final currencySymbol = user?.preferredCurrency.symbol ?? '₹';

    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Income & Expenses
    final monthlyIncome = transactions
        .where((t) => t.type == TransactionType.income &&
        t.date.month == currentMonth && t.date.year == currentYear)
        .fold(0.0, (sum, t) => sum + t.amount);

    final monthlyExpenses = transactions
        .where((t) => t.type == TransactionType.expense &&
        t.date.month == currentMonth && t.date.year == currentYear)
        .fold(0.0, (sum, t) => sum + t.amount);

    final monthlySavings = monthlyIncome - monthlyExpenses;
    final savingsRate = monthlyIncome > 0
        ? ((monthlySavings) / monthlyIncome * 100).clamp(0.0, 100.0)
        : 0.0;
    final expenseToIncomeRatio = monthlyIncome > 0
        ? (monthlyExpenses / monthlyIncome * 100).clamp(0.0, 100.0)
        : 0.0;

    // Spending Analysis
    final expenseTransactions = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    final categoryTotals = <String, double>{};
    for (var t in expenseTransactions) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0.0) + t.amount;
    }

    String topCategory = 'None';
    double topCategoryAmount = 0.0;
    double topCategoryPercentage = 0.0;

    if (categoryTotals.isNotEmpty) {
      final top = categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      topCategory = top.key;
      topCategoryAmount = top.value;
      topCategoryPercentage = monthlyExpenses > 0
          ? (topCategoryAmount / monthlyExpenses * 100).clamp(0.0, 100.0)
          : 0.0;
    }

    final daysPassed = now.day;
    final dailyAverageSpend = daysPassed > 0 ? monthlyExpenses / daysPassed : 0.0;

    // Budget Status
    int budgetsOnTrack = 0;
    int budgetsAtRisk = 0;
    int budgetsExceeded = 0;
    String topBudgetInfo = '';

    for (var budget in budgets) {
      if (budget.isExceeded) {
        budgetsExceeded++;
      } else if (budget.isWarning) {
        budgetsAtRisk++;
      } else if (budget.isOnTrack) {
        budgetsOnTrack++;
      }
    }

    if (budgets.isNotEmpty) {
      final highestRiskBudget = budgets
          .where((b) => b.progress > 80)
          .toList()
          .fold<Budget?>(null, (max, b) =>
      max == null || b.progress > max.progress ? b : max);
      if (highestRiskBudget != null) {
        topBudgetInfo = '${highestRiskBudget.category} at ${highestRiskBudget.progress.toStringAsFixed(0)}%';
      }
    }

    // Savings Goals
    int goalsOnTrack = 0;
    int goalsBehind = 0;
    double totalGoalTarget = 0;
    double totalGoalCurrent = 0;

    for (var goal in goals) {
      totalGoalTarget += goal.target;
      totalGoalCurrent += goal.current;
      if (goal.isBehind) {
        goalsBehind++;
      } else {
        goalsOnTrack++;
      }
    }

    final overallGoalProgress = totalGoalTarget > 0
        ? (totalGoalCurrent / totalGoalTarget * 100).clamp(0.0, 100.0)
        : 0.0;

    final goalNames = goals.take(3).map((g) => '${g.name} (${g.progress.toStringAsFixed(0)}%)').join(', ');

    // Accounts
    final totalBalance = accounts.fold(0.0, (sum, acc) => sum + acc.balance);
    final primaryAccount = accounts.isNotEmpty
        ? accounts.reduce((a, b) => a.balance > b.balance ? a : b)
        : null;
    final primaryAccountInfo = primaryAccount != null
        ? '${primaryAccount.name} ($currencySymbol${primaryAccount.balance.toStringAsFixed(0)})'
        : '';

    // Transactions
    final currentMonthTransactionCount = transactions
        .where((t) => t.date.month == currentMonth && t.date.year == currentYear)
        .length;

    // Most active spending day (last 30 days)
    final last30Days = DateTime.now().subtract(const Duration(days: 30));
    final recentTransactionsList = transactions
        .where((t) => t.date.isAfter(last30Days) && t.type == TransactionType.expense)
        .toList();

    final spendingByDay = <int, double>{};
    for (var t in recentTransactionsList) {
      final day = t.date.weekday;
      spendingByDay[day] = (spendingByDay[day] ?? 0) + t.amount;
    }

    String? mostActiveSpendingDay;
    if (spendingByDay.isNotEmpty) {
      final maxDay = spendingByDay.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      mostActiveSpendingDay = weekdays[maxDay - 1];
    }

    // Recent transactions summary (last 7 days)
    final last7Days = DateTime.now().subtract(const Duration(days: 7));
    final recentTransactionsList7 = transactions
        .where((t) => t.date.isAfter(last7Days))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final recentTransactionsSummary = recentTransactionsList7.take(5).map((t) {
      final sign = t.type == TransactionType.income ? '+' : '-';
      return '${t.date.day}/${t.date.month}: $sign$currencySymbol${t.amount.toStringAsFixed(0)} - ${t.category}';
    }).join('\n');

    if (mounted) {
      setState(() {
        _context = FinancialContext(
          userName: user?.name?.split(' ').first ?? 'User',
          currency: currencySymbol,
          occupation: user?.occupation,
          location: user?.location,
          monthlyIncome: monthlyIncome,
          monthlyExpenses: monthlyExpenses,
          monthlySavings: monthlySavings,
          savingsRate: savingsRate,
          expenseToIncomeRatio: expenseToIncomeRatio,
          topCategory: topCategory,
          topCategoryAmount: topCategoryAmount,
          topCategoryPercentage: topCategoryPercentage,
          categoryCount: categoryTotals.length,
          dailyAverageSpend: dailyAverageSpend,
          budgetCount: budgets.length,
          budgetsOnTrack: budgetsOnTrack,
          budgetsAtRisk: budgetsAtRisk,
          budgetsExceeded: budgetsExceeded,
          topBudgetInfo: topBudgetInfo,
          goalCount: goals.length,
          goalsOnTrack: goalsOnTrack,
          goalsBehind: goalsBehind,
          totalGoalTarget: totalGoalTarget,
          totalGoalCurrent: totalGoalCurrent,
          overallGoalProgress: overallGoalProgress,
          goalNames: goalNames,
          accountCount: accounts.length,
          totalBalance: totalBalance,
          primaryAccountInfo: primaryAccountInfo,
          transactionCount: transactions.length,
          currentMonthTransactionCount: currentMonthTransactionCount,
          mostActiveSpendingDay: mostActiveSpendingDay,
          recentTransactions: recentTransactionsSummary.isEmpty
              ? 'No recent transactions'
              : recentTransactionsSummary,
        );
        _isFirstLoad = false;
      });
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty || _isLoading || _context == null) return;

    setState(() {
      _messages.add({'role': 'user', 'content': message});
      _messageController.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    final response = await _gemini.getFinancialAdvice(message, _context!);

    if (mounted) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': response});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Color _getSecondaryColor(Color primary) {
    if (primary == const Color(0xFF007AFF)) return const Color(0xFF00C1D4);
    if (primary == const Color(0xFF34C759)) return const Color(0xFF74C69D);
    if (primary == const Color(0xFFAF52DE)) return const Color(0xFFD291FF);
    if (primary == const Color(0xFF1C1C1E)) return const Color(0xFF3A3A3C);
    return const Color(0xFF00C1D4);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    if (_isCheckingConsent) {
      return Container(
        height: screenHeight * 0.75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final hasConsented = _user?.aiAssistantEnabled ?? false;

    if (!hasConsented) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showConsentDialog();
      });
      return Container(
        height: screenHeight * 0.75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_context == null && _isFirstLoad) {
      return Container(
        height: screenHeight * 0.75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final bottomSheetHeight = isKeyboardVisible ? screenHeight * 0.9 : screenHeight * 0.8;

    return Container(
      height: bottomSheetHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: themeProvider.primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chat, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monivo AI',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Smart Assistant',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: _messages.isEmpty
                ? SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.05),
                  Container(
                    width: screenWidth * 0.2,
                    height: screenWidth * 0.2,
                    constraints: const BoxConstraints(maxWidth: 80, maxHeight: 80),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat,
                      size: screenWidth * 0.1,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ask me anything about your finances!',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: _suggestions.map((s) => _buildSuggestionChip(s, themeProvider)).toList(),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(
                      maxWidth: screenWidth * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? themeProvider.primaryColor : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                      ),
                    ),
                    child: Text(
                      msg['content']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Monivo AI is thinking...',
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

          // Input
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask something...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(_messageController.text),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_messageController.text),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: () => _sendMessage(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: themeProvider.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: themeProvider.primaryColor.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 12, color: themeProvider.primaryColor),
        ),
      ),
    );
  }
}