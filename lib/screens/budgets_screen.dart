import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

// Use relative imports for all your own files
import '../utils/app_colors.dart';
import '../services/storage_service.dart';
import '../widgets/main_layout.dart';
import '../models/budget.dart';
import '../models/user_model.dart';
import '../models/transaction.dart';
import '../widgets/budget_card.dart';
import '../widgets/goal_card.dart';
import '../widgets/empty_state.dart';
import '../providers/theme_provider.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({Key? key}) : super(key: key);

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  List<Budget> _budgets = [];
  List<SavingsGoal> _goals = [];
  List<Transaction> _transactions = [];
  UserProfile? _user;
  bool _isLoading = true;
  String _selectedBudgetPeriod = 'month'; // week, month, year
  bool _showCompletedGoals = true; // Toggle for completed goals

  // Controllers for Add/Edit Budget
  final _budgetNameController = TextEditingController();
  final _budgetLimitController = TextEditingController();
  String _selectedBudgetCategory = 'Food & Dining';
  BudgetPeriod _budgetPeriod = BudgetPeriod.monthly;
  Color _selectedBudgetColor = AppColors.primaryBlue;

  // Controllers for Add/Edit Goal
  final _goalNameController = TextEditingController();
  final _goalTargetController = TextEditingController();
  final _goalCurrentController = TextEditingController();
  // CHANGED: Default deadline set to 1 month from now instead of 365 days
  DateTime _selectedGoalDeadline = DateTime.now().add(const Duration(days: 30));
  Color _selectedGoalColor = AppColors.primaryBlue;
  bool _isAutoSaveEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _budgetNameController.dispose();
    _budgetLimitController.dispose();
    _goalNameController.dispose();
    _goalTargetController.dispose();
    _goalCurrentController.dispose();
    super.dispose();
  }

  // Helper to get secondary color based on primary
  Color _getSecondaryColor(Color primary) {
    if (primary == const Color(0xFF007AFF)) return const Color(0xFF00C1D4);
    if (primary == const Color(0xFF34C759)) return const Color(0xFF74C69D);
    if (primary == const Color(0xFFAF52DE)) return const Color(0xFFD291FF);
    if (primary == const Color(0xFF1C1C1E)) return const Color(0xFF3A3A3C);
    return const Color(0xFF00C1D4);
  }

  // Get in-progress goals (progress < 100)
  List<SavingsGoal> get _inProgressGoals {
    return _goals.where((goal) => goal.progress < 100).toList();
  }

  // Get completed goals (progress >= 100)
  List<SavingsGoal> get _completedGoals {
    return _goals.where((goal) => goal.progress >= 100).toList();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final user = await StorageService.getUser();
    final budgets = await StorageService.getBudgets();
    final goals = await StorageService.getSavingsGoals();
    final transactions = await StorageService.getTransactions();

    // Update budget spent amounts based on actual transactions
    final updatedBudgets = _calculateBudgetSpent(budgets, transactions);

    setState(() {
      _user = user;
      _budgets = updatedBudgets;
      _goals = goals;
      _transactions = transactions;
      _isLoading = false;
    });
  }

  List<Budget> _calculateBudgetSpent(List<Budget> budgets, List<Transaction> transactions) {
    final now = DateTime.now();
    final currentMonthTransactions = transactions.where((t) =>
    t.type == TransactionType.expense &&
        t.date.month == now.month &&
        t.date.year == now.year
    ).toList();

    return budgets.map((budget) {
      double spent = 0.0;

      // Calculate spent amount for this budget category
      final categoryTransactions = currentMonthTransactions.where((t) =>
      t.category == budget.category
      ).toList();

      spent = categoryTransactions.fold(0.0, (sum, t) => sum + t.amount);

      // Create updated budget with calculated spent
      return Budget(
        id: budget.id,
        category: budget.category,
        limit: budget.limit,
        spent: spent,
        color: budget.color,
        startDate: budget.startDate,
        endDate: budget.endDate,
        period: budget.period,
      );
    }).toList();
  }

  void _showAddBudgetDialog({Budget? budgetToEdit}) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    if (budgetToEdit != null) {
      _budgetNameController.text = budgetToEdit.category;
      _budgetLimitController.text = budgetToEdit.limit.toString();
      _selectedBudgetCategory = budgetToEdit.category;
      _budgetPeriod = budgetToEdit.period;
      _selectedBudgetColor = Color(int.parse(budgetToEdit.color.replaceFirst('#', '0xff')));
    } else {
      _budgetNameController.clear();
      _budgetLimitController.clear();
      _selectedBudgetCategory = 'Food & Dining';
      _budgetPeriod = BudgetPeriod.monthly;
      _selectedBudgetColor = themeProvider.primaryColor;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Local state for the dialog
        String localCategory = _selectedBudgetCategory;
        BudgetPeriod localPeriod = _budgetPeriod;
        Color localColor = _selectedBudgetColor;

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  // Header with theme gradient
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          themeProvider.primaryColor,
                          _getSecondaryColor(themeProvider.primaryColor),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                budgetToEdit != null ? Icons.edit : Icons.add_chart,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              budgetToEdit != null ? 'Edit Budget' : 'Create New Budget',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildCategorySelector(
                            selectedCategory: localCategory,
                            onCategorySelected: (category) {
                              setState(() {
                                localCategory = category;
                                _selectedBudgetCategory = category;
                              });
                            },
                            themeProvider: themeProvider,
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'Budget Name',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _budgetNameController,
                            decoration: InputDecoration(
                              hintText: 'e.g., Monthly Groceries',
                              prefixIcon: Icon(Icons.label_outline, color: themeProvider.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: AppColors.lightGray,
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: themeProvider.primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'Budget Limit',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _budgetLimitController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Enter amount',
                              prefixIcon: Icon(Icons.attach_money, color: themeProvider.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: AppColors.lightGray,
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: themeProvider.primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'Period',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.lightGray,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                _buildPeriodOption('Weekly', BudgetPeriod.weekly, localPeriod, (period) {
                                  setState(() {
                                    localPeriod = period;
                                    _budgetPeriod = period;
                                  });
                                }, themeProvider),
                                _buildPeriodOption('Monthly', BudgetPeriod.monthly, localPeriod, (period) {
                                  setState(() {
                                    localPeriod = period;
                                    _budgetPeriod = period;
                                  });
                                }, themeProvider),
                                _buildPeriodOption('Yearly', BudgetPeriod.yearly, localPeriod, (period) {
                                  setState(() {
                                    localPeriod = period;
                                    _budgetPeriod = period;
                                  });
                                }, themeProvider),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'Color Theme',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildColorSelector(
                            selectedColor: localColor,
                            onColorSelected: (color) {
                              setState(() {
                                localColor = color;
                                _selectedBudgetColor = color;
                              });
                            },
                            themeProvider: themeProvider,
                          ),

                          const SizedBox(height: 32),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                _saveBudget(budgetToEdit);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeProvider.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                budgetToEdit != null ? 'Update Budget' : 'Create Budget',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPeriodOption(String label, BudgetPeriod period, BudgetPeriod selectedPeriod, Function(BudgetPeriod) onSelected, ThemeProvider themeProvider) {
    final isSelected = selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(period),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? themeProvider.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector({
    required String selectedCategory,
    required Function(String) onCategorySelected,
    required ThemeProvider themeProvider,
  }) {
    final categories = [
      'Food & Dining',
      'Transportation',
      'Shopping',
      'Entertainment',
      'Bills & Utilities',
      'Healthcare',
      'Education',
      'Other',
    ];

    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;
          return GestureDetector(
            onTap: () => onCategorySelected(category),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? themeProvider.primaryColor : AppColors.lightGray,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorSelector({
    required Color selectedColor,
    required Function(Color) onColorSelected,
    required ThemeProvider themeProvider,
  }) {
    final colors = [
      themeProvider.primaryColor,
      AppColors.success,
      AppColors.error,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        final isSelected = selectedColor.value == color.value;
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: isSelected
                ? const Center(
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 20,
              ),
            )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Future<void> _saveBudget([Budget? existingBudget]) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    if (_budgetLimitController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter budget limit'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final limit = double.tryParse(_budgetLimitController.text) ?? 0.0;
    if (limit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (_budgetPeriod) {
      case BudgetPeriod.weekly:
        startDate = DateTime(now.year, now.month, now.day - now.weekday + 1);
        endDate = startDate.add(const Duration(days: 6));
        break;
      case BudgetPeriod.monthly:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case BudgetPeriod.yearly:
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31);
        break;
    }

    final budget = Budget(
      id: existingBudget?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      category: _selectedBudgetCategory,
      limit: limit,
      spent: existingBudget?.spent ?? 0.0,
      color: '#${_selectedBudgetColor.value.toRadixString(16).substring(2)}',
      startDate: startDate,
      endDate: endDate,
      period: _budgetPeriod,
    );

    List<Budget> updatedBudgets;
    if (existingBudget != null) {
      updatedBudgets = _budgets.map((b) => b.id == budget.id ? budget : b).toList();
    } else {
      updatedBudgets = [..._budgets, budget];
    }

    await StorageService.saveBudgets(updatedBudgets);

    setState(() {
      _budgets = updatedBudgets;
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(existingBudget != null ? 'Budget updated!' : 'Budget created!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  // REDESIGNED: Delete Budget Dialog with proper theming
  Future<void> _deleteBudget(Budget budget) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 340),
          child: Material(
            color: Colors.transparent,
            child: Container(
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
                  // Header with gradient
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.error,
                          Color(0xFFFF6B6B),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Delete Budget',
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

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Budget Preview
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.lightGray,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _parseColor(budget.color).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.pie_chart,
                                    color: _parseColor(budget.color),
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      budget.category,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Limit: ${_user?.preferredCurrency.symbol ?? '₹'} ${_formatNumber(budget.limit)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'Are you sure you want to delete this budget?',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'This action cannot be undone.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textLight,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  side: BorderSide(color: Colors.grey[300]!),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context); // Close dialog

                                  // Show loading
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );

                                  try {
                                    final updatedBudgets = _budgets.where((b) => b.id != budget.id).toList();
                                    await StorageService.saveBudgets(updatedBudgets);

                                    setState(() {
                                      _budgets = updatedBudgets;
                                    });

                                    if (mounted) Navigator.pop(context); // Close loading

                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.check,
                                                  color: themeProvider.primaryColor,
                                                  size: 14,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              const Expanded(
                                                child: Text(
                                                  'Budget deleted successfully',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: themeProvider.primaryColor,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          margin: const EdgeInsets.all(16),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) Navigator.pop(context); // Close loading
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text('Error: $e'),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: AppColors.error,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        margin: const EdgeInsets.all(16),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
    );
  }

  void _addMoneyToGoal(SavingsGoal goal) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final currency = _user?.preferredCurrency ?? Currency.npr;
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with theme gradient
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            themeProvider.primaryColor,
                            _getSecondaryColor(themeProvider.primaryColor),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
                              Icons.add_circle_outline,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Add Money to Goal',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  goal.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Scrollable Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Progress Summary
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: themeProvider.primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: themeProvider.primaryColor.withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Current Progress',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${currency.symbol} ${_formatNumber(goal.current)}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 30,
                                    color: Colors.grey[300],
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'Target',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${currency.symbol} ${_formatNumber(goal.target)}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Progress Bar
                            Stack(
                              children: [
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: (goal.current / goal.target).clamp(0, 1),
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [themeProvider.primaryColor, _getSecondaryColor(themeProvider.primaryColor)],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${((goal.current / goal.target) * 100).toStringAsFixed(1)}% complete',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${goal.daysRemaining} days left',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Amount Input
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.lightGray,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              child: TextField(
                                controller: amountController,
                                keyboardType: TextInputType.number,
                                autofocus: true,
                                decoration: InputDecoration(
                                  labelText: 'Enter amount to add',
                                  labelStyle: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                  prefixIcon: Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      currency.symbol,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: themeProvider.primaryColor,
                                      ),
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: themeProvider.primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Quick amount suggestions
                            Row(
                              children: [
                                Expanded(
                                  child: _buildQuickAmountButton(
                                    amount: goal.target * 0.1,
                                    label: '10%',
                                    currency: currency,
                                    onTap: () {
                                      amountController.text = (goal.target * 0.1).toStringAsFixed(0);
                                    },
                                    themeProvider: themeProvider,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildQuickAmountButton(
                                    amount: goal.target * 0.25,
                                    label: '25%',
                                    currency: currency,
                                    onTap: () {
                                      amountController.text = (goal.target * 0.25).toStringAsFixed(0);
                                    },
                                    themeProvider: themeProvider,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildQuickAmountButton(
                                    amount: goal.target * 0.5,
                                    label: '50%',
                                    currency: currency,
                                    onTap: () {
                                      amountController.text = (goal.target * 0.5).toStringAsFixed(0);
                                    },
                                    themeProvider: themeProvider,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.textSecondary,
                                      side: const BorderSide(color: AppColors.textLight),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final amount = double.tryParse(amountController.text) ?? 0.0;
                                      if (amount > 0) {
                                        _processAddMoney(goal, amount);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Please enter a valid amount'),
                                            backgroundColor: AppColors.error,
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: themeProvider.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Add Money',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickAmountButton({
    required double amount,
    required String label,
    required Currency currency,
    required VoidCallback onTap,
    required ThemeProvider themeProvider,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: themeProvider.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: themeProvider.primaryColor.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${currency.symbol}${_formatCompactNumber(amount)}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: themeProvider.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processAddMoney(SavingsGoal goal, double amount) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    Navigator.pop(context); // Close the add money dialog

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final updatedGoal = SavingsGoal(
        id: goal.id,
        name: goal.name,
        target: goal.target,
        current: goal.current + amount,
        color: goal.color,
        deadline: goal.deadline,
        isAutoSave: goal.isAutoSave,
      );

      final updatedGoals = _goals.map((g) => g.id == goal.id ? updatedGoal : g).toList();
      await StorageService.saveSavingsGoals(updatedGoals);

      setState(() {
        _goals = updatedGoals;
      });

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${_formatNumber(amount)} to "${goal.name}"'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding money: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showAddGoalDialog({SavingsGoal? goalToEdit}) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    if (goalToEdit != null) {
      _goalNameController.text = goalToEdit.name;
      _goalTargetController.text = goalToEdit.target.toString();
      _goalCurrentController.text = goalToEdit.current.toString();
      _selectedGoalDeadline = goalToEdit.deadline;
      _selectedGoalColor = Color(int.parse(goalToEdit.color.replaceFirst('#', '0xff')));
      _isAutoSaveEnabled = goalToEdit.isAutoSave;
    } else {
      _goalNameController.clear();
      _goalTargetController.clear();
      _goalCurrentController.clear();
      // CHANGED: Default to 30 days from now instead of 365 days
      _selectedGoalDeadline = DateTime.now().add(const Duration(days: 30));
      _selectedGoalColor = themeProvider.primaryColor;
      _isAutoSaveEnabled = false;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Local state for the dialog
        DateTime localDeadline = _selectedGoalDeadline;
        Color localColor = _selectedGoalColor;
        bool localAutoSave = _isAutoSaveEnabled;

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  // Header with theme gradient
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          themeProvider.primaryColor,
                          _getSecondaryColor(themeProvider.primaryColor),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                goalToEdit != null ? Icons.edit : Icons.flag,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              goalToEdit != null ? 'Edit Goal' : 'Create Savings Goal',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Goal Name',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _goalNameController,
                            decoration: InputDecoration(
                              hintText: 'e.g., New Car, Vacation, Emergency Fund',
                              prefixIcon: Icon(Icons.flag_outlined, color: themeProvider.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: AppColors.lightGray,
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: themeProvider.primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'Target Amount',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _goalTargetController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Enter target amount',
                              prefixIcon: Icon(Icons.attach_money, color: themeProvider.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: AppColors.lightGray,
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: themeProvider.primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'Current Savings',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _goalCurrentController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Enter current amount',
                              prefixIcon: Icon(Icons.savings, color: themeProvider.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: AppColors.lightGray,
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: themeProvider.primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'Target Date',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: localDeadline,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 3650)),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: themeProvider.primaryColor,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: AppColors.textPrimary,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (date != null) {
                                setState(() {
                                  localDeadline = date;
                                  _selectedGoalDeadline = date;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: AppColors.lightGray,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, color: themeProvider.primaryColor, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat('MMMM d, yyyy').format(localDeadline),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'Color Theme',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildGoalColorSelector(
                            selectedColor: localColor,
                            onColorSelected: (color) {
                              setState(() {
                                localColor = color;
                                _selectedGoalColor = color;
                              });
                            },
                            themeProvider: themeProvider,
                          ),

                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.lightGray,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[300]!,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  localAutoSave ? Icons.auto_graph : Icons.auto_graph_outlined,
                                  color: localAutoSave ? themeProvider.primaryColor : AppColors.textLight,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Enable Auto-Save',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: localAutoSave,
                                  onChanged: (value) {
                                    setState(() {
                                      localAutoSave = value;
                                      _isAutoSaveEnabled = value;
                                    });
                                  },
                                  activeColor: themeProvider.primaryColor,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                _saveGoal(goalToEdit);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeProvider.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                goalToEdit != null ? 'Update Goal' : 'Create Goal',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGoalColorSelector({
    required Color selectedColor,
    required Function(Color) onColorSelected,
    required ThemeProvider themeProvider,
  }) {
    final colors = [
      themeProvider.primaryColor,
      AppColors.success,
      AppColors.accentTeal,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        final isSelected = selectedColor.value == color.value;
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: isSelected
                ? const Center(
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 20,
              ),
            )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Future<void> _saveGoal([SavingsGoal? existingGoal]) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    if (_goalNameController.text.isEmpty ||
        _goalTargetController.text.isEmpty ||
        _goalCurrentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final target = double.tryParse(_goalTargetController.text) ?? 0.0;
    final current = double.tryParse(_goalCurrentController.text) ?? 0.0;

    if (target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid target amount'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final goal = SavingsGoal(
      id: existingGoal?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _goalNameController.text,
      target: target,
      current: current,
      color: '#${_selectedGoalColor.value.toRadixString(16).substring(2)}',
      deadline: _selectedGoalDeadline,
      isAutoSave: _isAutoSaveEnabled,
    );

    List<SavingsGoal> updatedGoals;
    if (existingGoal != null) {
      updatedGoals = _goals.map((g) => g.id == goal.id ? goal : g).toList();
    } else {
      updatedGoals = [..._goals, goal];
    }

    await StorageService.saveSavingsGoals(updatedGoals);

    setState(() {
      _goals = updatedGoals;
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(existingGoal != null ? 'Goal updated!' : 'Goal created!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  // REDESIGNED: Delete Goal Dialog with proper theming
  Future<void> _deleteGoal(SavingsGoal goal) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 340),
          child: Material(
            color: Colors.transparent,
            child: Container(
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
                  // Header with gradient
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.error,
                          Color(0xFFFF6B6B),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Delete Goal',
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

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Goal Preview
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.lightGray,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _parseColor(goal.color).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    goal.icon ?? '🎯',
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
                                      goal.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Target: ${_user?.preferredCurrency.symbol ?? '₹'} ${_formatNumber(goal.target)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      'Progress: ${goal.progress.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: goal.progress >= 100 ? AppColors.success : themeProvider.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          goal.progress >= 100
                              ? 'This goal is completed. Are you sure you want to remove it from view?'
                              : 'Are you sure you want to delete this goal?',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'This will only remove it from this screen. All transaction data will remain intact.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textLight,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  side: BorderSide(color: Colors.grey[300]!),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context); // Close dialog

                                  // Show loading
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );

                                  try {
                                    final updatedGoals = _goals.where((g) => g.id != goal.id).toList();
                                    await StorageService.saveSavingsGoals(updatedGoals);

                                    setState(() {
                                      _goals = updatedGoals;
                                    });

                                    if (mounted) Navigator.pop(context); // Close loading

                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.check,
                                                  color: themeProvider.primaryColor,
                                                  size: 14,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              const Expanded(
                                                child: Text(
                                                  'Goal removed from view',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: themeProvider.primaryColor,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          margin: const EdgeInsets.all(16),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) Navigator.pop(context); // Close loading
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text('Error: $e'),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: AppColors.error,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        margin: const EdgeInsets.all(16),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Remove',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
    );
  }

  // Budget Overview Chart
  Widget _buildBudgetOverviewChart(Currency currency, ThemeProvider themeProvider) {
    if (_budgets.isEmpty) return const SizedBox.shrink();

    final totalBudget = _budgets.fold(0.0, (sum, budget) => sum + budget.limit);
    final totalSpent = _budgets.fold(0.0, (sum, budget) => sum + budget.spent);
    final remaining = totalBudget - totalSpent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Budget Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.primaryColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${((totalSpent / totalBudget) * 100).toStringAsFixed(1)}% used',
                  style: TextStyle(
                    fontSize: 12,
                    color: themeProvider.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              children: [
                Expanded(
                  flex: (totalSpent / totalBudget * 100).toInt(),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [themeProvider.primaryColor, _getSecondaryColor(themeProvider.primaryColor)],
                      ),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                    ),
                    child: Center(
                      child: Text(
                        '${currency.symbol}${_formatCompactNumber(totalSpent)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 100 - (totalSpent / totalBudget * 100).toInt(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                    ),
                    child: Center(
                      child: Text(
                        '${currency.symbol}${_formatCompactNumber(remaining)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${currency.symbol}${_formatNumber(totalSpent)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                'Remaining: ${currency.symbol}${_formatNumber(remaining)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Category Distribution Chart
  Widget _buildCategoryDistributionChart(Currency currency, ThemeProvider themeProvider) {
    if (_budgets.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: themeProvider.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ..._budgets.take(5).map((budget) {
            final percentage = (budget.spent / budget.limit * 100).clamp(0, 100);
            final isOverBudget = budget.isExceeded;
            final color = isOverBudget ? AppColors.error : themeProvider.primaryColor;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          budget.category,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${currency.symbol}${_formatNumber(budget.spent)} / ${_formatNumber(budget.limit)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverBudget ? AppColors.error : AppColors.textSecondary,
                          fontWeight: isOverBudget ? FontWeight.w600 : FontWeight.normal,
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
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percentage / 100,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isOverBudget
                                  ? [AppColors.error, AppColors.error.withOpacity(0.7)]
                                  : [themeProvider.primaryColor, _getSecondaryColor(themeProvider.primaryColor)],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
          if (_budgets.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+${_budgets.length - 5} more categories',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Savings Progress Chart
  Widget _buildSavingsProgressChart(Currency currency, ThemeProvider themeProvider) {
    if (_goals.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Goal Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: themeProvider.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ..._goals.take(3).map((goal) {
            final progress = goal.progress.clamp(0, 100);
            final daysLeft = goal.daysRemaining;
            final requiredDaily = goal.requiredDaily;
            final goalColor = _parseColor(goal.color);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: goalColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.flag,
                          color: goalColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${currency.symbol}${_formatNumber(goal.current)} of ${_formatNumber(goal.target)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${progress.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: goalColor,
                            ),
                          ),
                          Text(
                            '$daysLeft days left',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress / 100,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                goalColor,
                                goalColor.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (requiredDaily > 0 && daysLeft > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: goal.isBehind ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Need ${currency.symbol}${_formatNumber(requiredDaily)}/day',
                              style: TextStyle(
                                fontSize: 10,
                                color: goal.isBehind ? AppColors.error : AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          if (_goals.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  '+${_goals.length - 3} more goals',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  String _formatNumber(double number) {
    if (number >= 10000000) {
      return '${(number / 10000000).toStringAsFixed(1)}Cr';
    } else if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(1)}L';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return NumberFormat('#,##,###').format(number);
  }

  String _formatCompactNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MainLayout(
        currentIndex: 3,
        child: const Scaffold(
          backgroundColor: AppColors.lightGray,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final currency = _user?.preferredCurrency ?? Currency.npr;
    final inProgressGoals = _inProgressGoals;
    final completedGoals = _completedGoals;

    return MainLayout(
      currentIndex: 3,
      child: Scaffold(
        backgroundColor: AppColors.lightGray,
        body: CustomScrollView(
          slivers: [
            // Header with theme colors
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: Colors.white,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Budgets & Goals',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: themeProvider.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Track your spending limits',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: themeProvider.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.add, color: themeProvider.primaryColor),
                                  onPressed: _showAddBudgetDialog,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: themeProvider.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.flag, color: themeProvider.primaryColor),
                                  onPressed: _showAddGoalDialog,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Charts Section
                  if (_budgets.isNotEmpty || _goals.isNotEmpty) ...[
                    if (_budgets.isNotEmpty) ...[
                      _buildBudgetOverviewChart(currency, themeProvider),
                      const SizedBox(height: 16),
                      _buildCategoryDistributionChart(currency, themeProvider),
                    ],
                    if (_goals.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildSavingsProgressChart(currency, themeProvider),
                    ],
                    const SizedBox(height: 24),
                  ],

                  // IN PROGRESS GOALS SECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'In Progress (${inProgressGoals.length})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.primaryColor,
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: themeProvider.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.add, color: themeProvider.primaryColor, size: 20),
                          onPressed: _showAddGoalDialog,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (inProgressGoals.isEmpty)
                    EmptyState(
                      title: 'No Goals in Progress',
                      message: 'Create a new savings goal to start saving!',
                      icon: Icons.trending_up,
                      buttonText: 'Create Goal',
                      onButtonPressed: _showAddGoalDialog,
                    )
                  else
                    ...inProgressGoals.map((goal) => GoalCard(
                      goal: goal,
                      currency: currency,
                      onTap: () => _showAddGoalDialog(goalToEdit: goal),
                      onEdit: () => _showAddGoalDialog(goalToEdit: goal),
                      onDelete: () => _deleteGoal(goal),
                      onAddMoney: () => _addMoneyToGoal(goal),
                    )).toList(),

                  const SizedBox(height: 32),

                  // COMPLETED GOALS SECTION with Toggle
                  if (completedGoals.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Completed (${completedGoals.length})',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.primaryColor,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              _showCompletedGoals ? 'Hide' : 'Show',
                              style: TextStyle(
                                fontSize: 13,
                                color: themeProvider.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: _showCompletedGoals,
                              onChanged: (value) {
                                setState(() {
                                  _showCompletedGoals = value;
                                });
                              },
                              activeColor: themeProvider.primaryColor,
                              activeTrackColor: themeProvider.primaryColor.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_showCompletedGoals)
                      ...completedGoals.map((goal) => GoalCard(
                        goal: goal,
                        currency: currency,
                        onTap: () => _showAddGoalDialog(goalToEdit: goal),
                        onEdit: () => _showAddGoalDialog(goalToEdit: goal),
                        onDelete: () => _deleteGoal(goal),
                        onAddMoney: null,
                      )).toList(),

                    const SizedBox(height: 32),
                  ],

                  // Monthly Budgets Section
                  Text(
                    'Monthly Budgets',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_budgets.isEmpty)
                    EmptyState(
                      title: 'No Budgets',
                      message: 'Create your first budget to track spending!',
                      icon: Icons.pie_chart,
                      buttonText: 'Create Budget',
                      onButtonPressed: _showAddBudgetDialog,
                    )
                  else
                    ..._budgets.map((budget) => BudgetCard(
                      budget: budget,
                      currency: currency,
                      onTap: () => _showAddBudgetDialog(budgetToEdit: budget),
                      onEdit: () => _showAddBudgetDialog(budgetToEdit: budget),
                      onDelete: () => _deleteBudget(budget),
                    )).toList(),

                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}