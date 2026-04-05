import 'dart:math' as math; // Add this import at the top
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/user_model.dart';

class PersonalityService {
  // Main analysis function that returns consistent personality data
  static Map<String, dynamic> analyzeSpendingPersonality({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required List<SavingsGoal> goals,
    required double monthlyIncome,
    required double monthlyExpenses,
    required double totalBalance,
    Currency? currency,
  }) {
    final now = DateTime.now();
    final allExpenses = transactions.where((t) => t.type == TransactionType.expense).toList();
    final allIncome = transactions.where((t) => t.type == TransactionType.income).toList();
    final currentMonthExpenses = allExpenses.where((t) =>
    t.date.month == now.month && t.date.year == now.year).toList();
    final currentMonthIncome = allIncome.where((t) =>
    t.date.month == now.month && t.date.year == now.year).toList();

    // Check if user has sufficient data for meaningful analysis
    final bool hasSufficientData = allExpenses.length >= 5 && allIncome.length >= 1;
    final bool hasThreeMonthsData = _hasThreeMonthsData(allExpenses, allIncome);

    // === CORE METRICS CALCULATION ===

    // 1. Savings Rate (Key Indicator of Financial Health)
    final savingsRate = monthlyIncome > 0
        ? ((monthlyIncome - monthlyExpenses) / monthlyIncome * 100).clamp(0, 100).toDouble()
        : 0.0;

    // 2. Transaction Patterns - Normalized for data volume
    final totalTransactions = allExpenses.length;
    final avgTransactionAmount = totalTransactions > 0
        ? allExpenses.fold(0.0, (sum, t) => sum + t.amount) / totalTransactions
        : 0.0;

    // 3. Emergency Fund Status (based on total balance vs monthly expenses)
    final emergencyFundMonths = monthlyExpenses > 0
        ? totalBalance / monthlyExpenses
        : 0.0;

    // 4. Budget Adherence (only meaningful if budgets exist)
    final budgetAdherence = _calculateBudgetAdherence(budgets);

    // 5. Goal Progress (only meaningful if goals exist)
    final goalProgress = _calculateGoalProgress(goals);

    // 6. Spending Consistency (based on available data)
    final spendingConsistency = _calculateSpendingConsistency(allExpenses);

    // 7. Income Stability
    final incomeStability = _calculateIncomeStability(allIncome);

    // 8. Debt-to-Income Proxy (using spending vs income)
    final debtRiskScore = _calculateDebtRiskScore(monthlyIncome, monthlyExpenses, totalBalance);

    // 9. Essential vs Discretionary Spending Ratio
    final essentialRatio = _calculateEssentialRatio(currentMonthExpenses);

    // 10. Large Purchase Behavior
    final largePurchaseScore = _calculateLargePurchaseScore(allExpenses, avgTransactionAmount);

    // === PERSONALITY SCORING SYSTEM - Now with realistic baselines ===

    Map<String, double> personalityScores = {};

    // Base scores start at 0 - users must earn points through actual behavior
    // Maximum scores are capped at realistic levels

    // THE SAVER (High savings, good emergency fund)
    double saverScore = 0;
    if (hasSufficientData) {
      // Savings rate contribution (max 40 points)
      if (savingsRate >= 20) saverScore += 40;
      else if (savingsRate >= 15) saverScore += 30;
      else if (savingsRate >= 10) saverScore += 20;
      else if (savingsRate >= 5) saverScore += 10;
      else if (savingsRate > 0) saverScore += 5;

      // Emergency fund contribution (max 30 points)
      if (emergencyFundMonths >= 6) saverScore += 30;
      else if (emergencyFundMonths >= 3) saverScore += 20;
      else if (emergencyFundMonths >= 1) saverScore += 10;
      else if (emergencyFundMonths > 0) saverScore += 5;

      // Goal progress contribution (max 30 points)
      if (goals.isNotEmpty) {
        if (goalProgress >= 80) saverScore += 30;
        else if (goalProgress >= 50) saverScore += 20;
        else if (goalProgress >= 25) saverScore += 10;
        else if (goalProgress > 0) saverScore += 5;
      }
    }
    personalityScores['The Saver'] = saverScore.clamp(0, 100);

    // THE PLANNER (Good budget adherence, consistent spending, stable income)
    double plannerScore = 0;
    if (hasSufficientData) {
      // Budget adherence (max 40 points)
      if (budgets.isNotEmpty) {
        if (budgetAdherence >= 0.9) plannerScore += 40;
        else if (budgetAdherence >= 0.8) plannerScore += 30;
        else if (budgetAdherence >= 0.7) plannerScore += 20;
        else if (budgetAdherence >= 0.6) plannerScore += 10;
        else if (budgetAdherence > 0) plannerScore += 5;
      } else {
        // No budgets set - can't be a strong planner
        plannerScore += 10; // Small baseline for having no budgets (room for improvement)
      }

      // Spending consistency (max 30 points)
      if (hasThreeMonthsData) {
        if (spendingConsistency >= 0.8) plannerScore += 30;
        else if (spendingConsistency >= 0.6) plannerScore += 20;
        else if (spendingConsistency >= 0.4) plannerScore += 10;
        else if (spendingConsistency >= 0.2) plannerScore += 5;
      }

      // Income stability (max 30 points)
      if (incomeStability >= 0.9) plannerScore += 30;
      else if (incomeStability >= 0.7) plannerScore += 20;
      else if (incomeStability >= 0.5) plannerScore += 10;
      else if (incomeStability >= 0.3) plannerScore += 5;
    }
    personalityScores['The Planner'] = plannerScore.clamp(0, 100);

    // THE INVESTOR (High income, good savings, diversified)
    double investorScore = 0;
    if (hasSufficientData) {
      // Income level relative to expenses (max 30 points)
      final disposableIncome = monthlyIncome - monthlyExpenses;
      if (disposableIncome > monthlyExpenses) investorScore += 30;
      else if (disposableIncome > monthlyExpenses * 0.5) investorScore += 20;
      else if (disposableIncome > monthlyExpenses * 0.25) investorScore += 10;
      else if (disposableIncome > 0) investorScore += 5;

      // Savings rate (max 30 points)
      if (savingsRate >= 25) investorScore += 30;
      else if (savingsRate >= 20) investorScore += 20;
      else if (savingsRate >= 15) investorScore += 10;
      else if (savingsRate >= 10) investorScore += 5;

      // Emergency fund (max 20 points) - investors need safety net
      if (emergencyFundMonths >= 6) investorScore += 20;
      else if (emergencyFundMonths >= 3) investorScore += 10;
      else if (emergencyFundMonths >= 1) investorScore += 5;

      // Transaction diversity (max 20 points)
      final categoryCount = _getCategoryCount(currentMonthExpenses);
      if (categoryCount >= 8) investorScore += 20;
      else if (categoryCount >= 5) investorScore += 10;
      else if (categoryCount >= 3) investorScore += 5;
    }
    personalityScores['The Investor'] = investorScore.clamp(0, 100);

    // THE MINIMALIST (Low transactions, high essential ratio)
    double minimalistScore = 0;
    if (hasSufficientData) {
      // Transaction frequency (max 40 points) - fewer is better
      final monthlyTransactionCount = currentMonthExpenses.length;
      if (monthlyTransactionCount <= 10) minimalistScore += 40;
      else if (monthlyTransactionCount <= 20) minimalistScore += 30;
      else if (monthlyTransactionCount <= 30) minimalistScore += 20;
      else if (monthlyTransactionCount <= 40) minimalistScore += 10;

      // Essential spending ratio (max 40 points)
      if (essentialRatio >= 0.7) minimalistScore += 40;
      else if (essentialRatio >= 0.6) minimalistScore += 30;
      else if (essentialRatio >= 0.5) minimalistScore += 20;
      else if (essentialRatio >= 0.4) minimalistScore += 10;

      // Savings rate (max 20 points)
      if (savingsRate >= 20) minimalistScore += 20;
      else if (savingsRate >= 15) minimalistScore += 15;
      else if (savingsRate >= 10) minimalistScore += 10;
      else if (savingsRate >= 5) minimalistScore += 5;
    }
    personalityScores['The Minimalist'] = minimalistScore.clamp(0, 100);

    // THE BALANCED (Moderate scores across multiple categories)
    double balancedScore = 0;
    if (hasSufficientData) {
      // This is a composite score - being good at multiple things
      int goodCategories = 0;
      if (savingsRate >= 15) goodCategories++;
      if (budgetAdherence >= 0.7) goodCategories++;
      if (essentialRatio >= 0.5) goodCategories++;
      if (emergencyFundMonths >= 3) goodCategories++;
      if (spendingConsistency >= 0.6) goodCategories++;

      balancedScore = goodCategories * 15; // Max 75, plus bonus

      // Bonus for not being extreme in any category
      if (savingsRate < 40 && savingsRate > 5) balancedScore += 10;
      if (monthlyExpenses < monthlyIncome * 0.9) balancedScore += 5;

      // Cap at 100
      balancedScore = balancedScore.clamp(0, 100).toDouble();
    }
    personalityScores['The Balanced'] = balancedScore.clamp(0, 100);

    // THE ENTHUSIAST (High transaction frequency, enjoys experiences)
    double enthusiastScore = 0;
    if (hasSufficientData) {
      // Transaction frequency (max 40 points)
      final monthlyTransactionCount = currentMonthExpenses.length;
      if (monthlyTransactionCount >= 30) enthusiastScore += 40;
      else if (monthlyTransactionCount >= 20) enthusiastScore += 30;
      else if (monthlyTransactionCount >= 10) enthusiastScore += 20;
      else if (monthlyTransactionCount >= 5) enthusiastScore += 10;

      // Experience spending (max 30 points)
      final experienceRatio = _calculateExperienceRatio(currentMonthExpenses);
      if (experienceRatio >= 0.3) enthusiastScore += 30;
      else if (experienceRatio >= 0.2) enthusiastScore += 20;
      else if (experienceRatio >= 0.1) enthusiastScore += 10;
      else if (experienceRatio >= 0.05) enthusiastScore += 5;

      // Weekend spending (max 30 points)
      final weekendRatio = _calculateWeekendSpendingRatio(currentMonthExpenses);
      if (weekendRatio >= 0.4) enthusiastScore += 30;
      else if (weekendRatio >= 0.3) enthusiastScore += 20;
      else if (weekendRatio >= 0.2) enthusiastScore += 10;
      else if (weekendRatio >= 0.1) enthusiastScore += 5;
    }
    personalityScores['The Enthusiast'] = enthusiastScore.clamp(0, 100);

    // THE STRATEGIST (Optimizes categories, good with goals)
    double strategistScore = 0;
    if (hasSufficientData) {
      // Goal achievement (max 40 points)
      if (goals.isNotEmpty) {
        final completedGoals = goals.where((g) => g.progress >= 100).length;
        if (completedGoals >= 3) strategistScore += 40;
        else if (completedGoals >= 2) strategistScore += 30;
        else if (completedGoals >= 1) strategistScore += 20;
      }

      // Category optimization (max 30 points)
      final categoryEfficiency = _calculateCategoryEfficiency(currentMonthExpenses);
      if (categoryEfficiency >= 0.8) strategistScore += 30;
      else if (categoryEfficiency >= 0.6) strategistScore += 20;
      else if (categoryEfficiency >= 0.4) strategistScore += 10;

      // Budget utilization (max 30 points)
      if (budgets.isNotEmpty) {
        final wellManagedBudgets = budgets.where((b) => !b.isExceeded && b.progress > 50).length;
        if (wellManagedBudgets >= 3) strategistScore += 30;
        else if (wellManagedBudgets >= 2) strategistScore += 20;
        else if (wellManagedBudgets >= 1) strategistScore += 10;
      }
    }
    personalityScores['The Strategist'] = strategistScore.clamp(0, 100);

    // THE SECURITY-SEEKER (High emergency fund, low risk)
    double securitySeekerScore = 0;
    if (hasSufficientData) {
      // Emergency fund (max 50 points)
      if (emergencyFundMonths >= 12) securitySeekerScore += 50;
      else if (emergencyFundMonths >= 9) securitySeekerScore += 40;
      else if (emergencyFundMonths >= 6) securitySeekerScore += 30;
      else if (emergencyFundMonths >= 3) securitySeekerScore += 20;
      else if (emergencyFundMonths >= 1) securitySeekerScore += 10;

      // Debt risk score (max 30 points)
      if (debtRiskScore >= 80) securitySeekerScore += 30;
      else if (debtRiskScore >= 60) securitySeekerScore += 20;
      else if (debtRiskScore >= 40) securitySeekerScore += 10;

      // Savings rate (max 20 points)
      if (savingsRate >= 20) securitySeekerScore += 20;
      else if (savingsRate >= 15) securitySeekerScore += 15;
      else if (savingsRate >= 10) securitySeekerScore += 10;
      else if (savingsRate >= 5) securitySeekerScore += 5;
    }
    personalityScores['The Security-Seeker'] = securitySeekerScore.clamp(0, 100);

    // THE EXPERIENCE-SEEKER (High entertainment, travel, dining)
    double experienceSeekerScore = 0;
    if (hasSufficientData) {
      // Experience spending (max 50 points)
      final experienceRatio = _calculateExperienceRatio(currentMonthExpenses);
      if (experienceRatio >= 0.4) experienceSeekerScore += 50;
      else if (experienceRatio >= 0.3) experienceSeekerScore += 40;
      else if (experienceRatio >= 0.2) experienceSeekerScore += 30;
      else if (experienceRatio >= 0.1) experienceSeekerScore += 20;
      else if (experienceRatio >= 0.05) experienceSeekerScore += 10;

      // Weekend spending (max 30 points)
      final weekendRatio = _calculateWeekendSpendingRatio(currentMonthExpenses);
      if (weekendRatio >= 0.4) experienceSeekerScore += 30;
      else if (weekendRatio >= 0.3) experienceSeekerScore += 20;
      else if (weekendRatio >= 0.2) experienceSeekerScore += 10;

      // Transaction frequency (max 20 points)
      final monthlyTransactionCount = currentMonthExpenses.length;
      if (monthlyTransactionCount >= 25) experienceSeekerScore += 20;
      else if (monthlyTransactionCount >= 15) experienceSeekerScore += 10;
      else if (monthlyTransactionCount >= 10) experienceSeekerScore += 5;
    }
    personalityScores['The Experience-Seeker'] = experienceSeekerScore.clamp(0, 100);

    // THE DISCIPLINED (Strong budget adherence, consistent savings)
    double disciplinedScore = 0;
    if (hasSufficientData) {
      // Budget adherence (max 40 points)
      if (budgets.isNotEmpty) {
        if (budgetAdherence >= 0.9) disciplinedScore += 40;
        else if (budgetAdherence >= 0.8) disciplinedScore += 30;
        else if (budgetAdherence >= 0.7) disciplinedScore += 20;
        else if (budgetAdherence >= 0.6) disciplinedScore += 10;
      }

      // Savings consistency (max 30 points)
      if (hasThreeMonthsData) {
        final savingsConsistency = _calculateSavingsConsistency(allIncome, allExpenses);
        if (savingsConsistency >= 0.8) disciplinedScore += 30;
        else if (savingsConsistency >= 0.6) disciplinedScore += 20;
        else if (savingsConsistency >= 0.4) disciplinedScore += 10;
      }

      // Goal progress (max 30 points)
      if (goals.isNotEmpty) {
        if (goalProgress >= 80) disciplinedScore += 30;
        else if (goalProgress >= 60) disciplinedScore += 20;
        else if (goalProgress >= 40) disciplinedScore += 10;
        else if (goalProgress >= 20) disciplinedScore += 5;
      }
    }
    personalityScores['The Disciplined'] = disciplinedScore.clamp(0, 100);

    // Add a default low score for users with insufficient data
    if (!hasSufficientData) {
      personalityScores.forEach((key, value) {
        if (value == 0) personalityScores[key] = 10.0; // Base score for new users
      });
    }

    // Get top 2 personalities for context
    final sortedPersonalities = personalityScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final primaryPersonality = sortedPersonalities.first.key;
    final secondaryPersonality = sortedPersonalities.length > 1
        ? sortedPersonalities[1].key
        : primaryPersonality;
    final primaryScore = sortedPersonalities.first.value;
    final secondaryScore = sortedPersonalities.length > 1 ? sortedPersonalities[1].value : primaryScore;

    // Generate detailed reasoning based on actual data
    final reasoning = _generateReasoning(
      primaryPersonality,
      savingsRate,
      emergencyFundMonths,
      budgetAdherence,
      goalProgress,
      essentialRatio,
      totalTransactions,
      hasSufficientData,
      monthlyIncome,
      monthlyExpenses,
    );

    // Generate actionable advice
    final advice = _generateAdvice(
      primaryPersonality,
      savingsRate,
      emergencyFundMonths,
      budgetAdherence,
      goalProgress,
      essentialRatio,
      hasSufficientData,
    );

    // Compile evidence points (only show actual achievements)
    final evidence = _compileEvidence(
      savingsRate,
      emergencyFundMonths,
      budgetAdherence,
      goalProgress,
      essentialRatio,
      totalTransactions,
      monthlyIncome,
      monthlyExpenses,
      totalBalance,
      hasSufficientData,
    );

    return {
      'primary': primaryPersonality,
      'secondary': secondaryPersonality,
      'primaryScore': primaryScore,
      'secondaryScore': secondaryScore,
      'scores': personalityScores,
      'reasoning': reasoning,
      'advice': advice,
      'evidence': evidence,
      'metrics': {
        'savingsRate': savingsRate,
        'emergencyFundMonths': emergencyFundMonths,
        'budgetAdherence': budgetAdherence * 100,
        'goalProgress': goalProgress,
        'essentialRatio': essentialRatio * 100,
        'luxuryRatio': (1 - essentialRatio) * 100,
        'transactionCount': totalTransactions,
        'monthlyTransactionCount': currentMonthExpenses.length,
        'monthlyIncome': monthlyIncome,
        'monthlyExpenses': monthlyExpenses,
        'totalBalance': totalBalance,
        'totalTransactions': totalTransactions,
        'avgTransactionAmount': avgTransactionAmount,
        'hasSufficientData': hasSufficientData,
      },
    };
  }

  // === HELPER FUNCTIONS ===

  static bool _hasThreeMonthsData(List<Transaction> expenses, List<Transaction> incomes) {
    if (expenses.isEmpty || incomes.isEmpty) return false;

    final dates = [...expenses.map((t) => t.date), ...incomes.map((t) => t.date)];
    if (dates.isEmpty) return false;

    dates.sort();
    final oldest = dates.first;
    final newest = dates.last;
    final monthsDiff = (newest.year - oldest.year) * 12 + (newest.month - oldest.month);

    return monthsDiff >= 2; // At least 3 months of data (current month + 2 previous)
  }

  static double _calculateBudgetAdherence(List<Budget> budgets) {
    if (budgets.isEmpty) return 0.5; // Neutral if no budgets

    double totalScore = 0.0;
    int validBudgets = 0;

    for (var budget in budgets) {
      if (budget.limit > 0) {
        validBudgets++;
        if (budget.isExceeded) {
          totalScore += 0.0;
        } else if (budget.isWarning) {
          totalScore += 0.5;
        } else {
          totalScore += 1.0;
        }
      }
    }

    return validBudgets > 0 ? totalScore / validBudgets : 0.5;
  }

  static double _calculateGoalProgress(List<SavingsGoal> goals) {
    if (goals.isEmpty) return 0.0;

    double totalProgress = 0.0;
    for (var goal in goals) {
      totalProgress += goal.progress;
    }

    return totalProgress / goals.length;
  }

  static double _calculateSpendingConsistency(List<Transaction> expenses) {
    if (expenses.length < 10) return 0.3; // Not enough data

    // Group by month
    final Map<String, double> monthlySpending = {};
    for (var t in expenses) {
      final monthKey = '${t.date.year}-${t.date.month}';
      monthlySpending[monthKey] = (monthlySpending[monthKey] ?? 0.0) + t.amount;
    }

    if (monthlySpending.length < 2) return 0.3;

    final amounts = monthlySpending.values.toList();
    final mean = amounts.reduce((a, b) => a + b) / amounts.length;
    if (mean == 0) return 0.3;

    final variance = amounts.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / amounts.length;
    final stdDev = math.sqrt(variance);
    final cv = stdDev / mean; // Coefficient of variation

    // Lower CV means more consistent
    if (cv <= 0.2) return 0.9;
    if (cv <= 0.3) return 0.7;
    if (cv <= 0.4) return 0.5;
    if (cv <= 0.5) return 0.3;
    return 0.1;
  }

  static double _calculateIncomeStability(List<Transaction> incomes) {
    if (incomes.length < 3) return 0.3; // Not enough data

    // Group by month
    final Map<String, double> monthlyIncome = {};
    for (var t in incomes) {
      final monthKey = '${t.date.year}-${t.date.month}';
      monthlyIncome[monthKey] = (monthlyIncome[monthKey] ?? 0.0) + t.amount;
    }

    if (monthlyIncome.length < 2) return 0.3;

    final amounts = monthlyIncome.values.toList();
    final mean = amounts.reduce((a, b) => a + b) / amounts.length;
    if (mean == 0) return 0.3;

    final variance = amounts.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / amounts.length;
    final stdDev = math.sqrt(variance);
    final cv = stdDev / mean;

    if (cv <= 0.1) return 0.95;
    if (cv <= 0.2) return 0.8;
    if (cv <= 0.3) return 0.6;
    if (cv <= 0.4) return 0.4;
    return 0.2;
  }

  static double _calculateDebtRiskScore(double monthlyIncome, double monthlyExpenses, double totalBalance) {
    if (monthlyIncome <= 0) return 0;

    // Calculate how many months of expenses are covered by balance
    final coverageMonths = monthlyExpenses > 0 ? totalBalance / monthlyExpenses : 0;

    // Calculate expense-to-income ratio
    final expenseRatio = monthlyExpenses / monthlyIncome;

    // Debt risk score (higher is better - lower risk)
    double score = 0;

    // Coverage months contribution (max 60)
    if (coverageMonths >= 6) score += 60;
    else if (coverageMonths >= 3) score += 40;
    else if (coverageMonths >= 1) score += 20;
    else if (coverageMonths > 0) score += 10;

    // Expense ratio contribution (max 40)
    if (expenseRatio <= 0.5) score += 40;
    else if (expenseRatio <= 0.7) score += 30;
    else if (expenseRatio <= 0.8) score += 20;
    else if (expenseRatio <= 0.9) score += 10;

    return score;
  }

  static double _calculateEssentialRatio(List<Transaction> expenses) {
    if (expenses.isEmpty) return 0.5;

    final essentialCategories = [
      'Groceries', 'Bills & Utilities', 'Healthcare', 'Education',
      'Transportation', 'Insurance', 'Rent', 'Mortgage', 'EMI'
    ];

    double essentialTotal = 0.0;
    double total = 0.0;

    for (var t in expenses) {
      total += t.amount;
      if (essentialCategories.any((cat) => t.category.contains(cat))) {
        essentialTotal += t.amount;
      }
    }

    return total > 0 ? essentialTotal / total : 0.5;
  }

  static double _calculateLargePurchaseScore(List<Transaction> expenses, double avgAmount) {
    if (expenses.isEmpty || avgAmount == 0) return 0.5;

    // Count purchases that are 3x average or more
    final largePurchases = expenses.where((t) => t.amount > avgAmount * 3).length;
    final totalPurchases = expenses.length;

    if (totalPurchases == 0) return 0.5;

    final largePurchaseRatio = largePurchases / totalPurchases;

    // Lower ratio is better for most personalities
    if (largePurchaseRatio <= 0.05) return 0.9;
    if (largePurchaseRatio <= 0.1) return 0.7;
    if (largePurchaseRatio <= 0.15) return 0.5;
    if (largePurchaseRatio <= 0.2) return 0.3;
    return 0.1;
  }

  static int _getCategoryCount(List<Transaction> expenses) {
    final categories = expenses.map((t) => t.category).toSet();
    return categories.length;
  }

  static double _calculateExperienceRatio(List<Transaction> expenses) {
    if (expenses.isEmpty) return 0;

    final experienceCategories = [
      'Entertainment', 'Travel', 'Dining', 'Restaurant',
      'Movies', 'Concert', 'Sports', 'Events', 'Museum',
      'Vacation', 'Hotel', 'Flight'
    ];

    double experienceTotal = 0.0;
    double total = 0.0;

    for (var t in expenses) {
      total += t.amount;
      if (experienceCategories.any((cat) => t.category.contains(cat))) {
        experienceTotal += t.amount;
      }
    }

    return total > 0 ? experienceTotal / total : 0;
  }

  static double _calculateWeekendSpendingRatio(List<Transaction> expenses) {
    if (expenses.isEmpty) return 0;

    double weekendTotal = 0.0;
    double total = 0.0;

    for (var t in expenses) {
      total += t.amount;
      if (t.date.weekday == DateTime.saturday || t.date.weekday == DateTime.sunday) {
        weekendTotal += t.amount;
      }
    }

    return total > 0 ? weekendTotal / total : 0;
  }

  static double _calculateCategoryEfficiency(List<Transaction> expenses) {
    if (expenses.isEmpty) return 0.5;

    // Efficiency is about having a balanced but focused category distribution
    final Map<String, double> categoryTotals = {};
    for (var t in expenses) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0.0) + t.amount;
    }

    if (categoryTotals.isEmpty) return 0.5;

    // Calculate Herfindahl-Hirschman Index for concentration
    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
    double hhi = 0.0;
    categoryTotals.values.forEach((amount) {
      final share = amount / total;
      hhi += share * share;
    });

    // Ideal HHI is moderate (not too concentrated, not too分散)
    // 0.2-0.3 is good for most people
    if (hhi <= 0.15) return 0.3; // Too分散
    if (hhi <= 0.2) return 0.5;
    if (hhi <= 0.25) return 0.8;
    if (hhi <= 0.3) return 0.9;
    if (hhi <= 0.4) return 0.7;
    return 0.4; // Too concentrated
  }

  static double _calculateSavingsConsistency(List<Transaction> incomes, List<Transaction> expenses) {
    if (incomes.length < 3 || expenses.length < 3) return 0.3;

    // Group by month
    final Map<String, double> monthlySavings = {};

    // Get all months from both incomes and expenses
    final allDates = [...incomes.map((t) => t.date), ...expenses.map((t) => t.date)];
    final months = allDates.map((d) => '${d.year}-${d.month}').toSet();

    for (var month in months) {
      final monthlyIncome = incomes
          .where((t) => '${t.date.year}-${t.date.month}' == month)
          .fold(0.0, (sum, t) => sum + t.amount);
      final monthlyExpense = expenses
          .where((t) => '${t.date.year}-${t.date.month}' == month)
          .fold(0.0, (sum, t) => sum + t.amount);
      monthlySavings[month] = monthlyIncome - monthlyExpense;
    }

    final savings = monthlySavings.values.toList();
    if (savings.length < 2) return 0.3;

    final mean = savings.reduce((a, b) => a + b) / savings.length;
    if (mean == 0) return 0.3;

    final variance = savings.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / savings.length;
    final stdDev = math.sqrt(variance);
    final cv = stdDev / mean.abs();

    if (cv <= 0.3) return 0.9;
    if (cv <= 0.5) return 0.7;
    if (cv <= 0.7) return 0.5;
    if (cv <= 1.0) return 0.3;
    return 0.1;
  }

  static String _generateReasoning(
      String personality,
      double savingsRate,
      double emergencyFundMonths,
      double budgetAdherence,
      double goalProgress,
      double essentialRatio,
      int totalTransactions,
      bool hasSufficientData,
      double monthlyIncome,
      double monthlyExpenses,
      ) {

    if (!hasSufficientData) {
      return "We're still learning about your spending habits. Add more transactions to get personalized insights! The more you track, the better we can understand your financial personality.";
    }

    switch (personality) {
      case 'The Saver':
        if (savingsRate > 25) {
          return "You're an exceptional saver! With a savings rate of ${savingsRate.toStringAsFixed(1)}%, you're building wealth faster than most. This habit will serve you well for major life goals and retirement.";
        } else if (savingsRate > 15) {
          return "You have strong saving habits, saving ${savingsRate.toStringAsFixed(1)}% of your income. This puts you ahead of the average person and builds a solid foundation for financial security.";
        } else {
          return "You're developing good saving habits with a ${savingsRate.toStringAsFixed(1)}% savings rate. Small increases in this percentage can have a big impact over time.";
        }

      case 'The Planner':
        if (budgetAdherence > 0.8) {
          return "You're a meticulous planner! You stick to your budgets ${(budgetAdherence * 100).toStringAsFixed(0)}% of the time, which shows exceptional discipline and foresight.";
        } else if (budgetAdherence > 0.5) {
          return "You're making progress with budgeting. Creating budgets is the first step, and you're learning to stick to them. Keep refining your approach.";
        } else {
          return "You haven't set up budgets yet, which is a great opportunity to start planning your spending more intentionally.";
        }

      case 'The Investor':
        if (monthlyIncome - monthlyExpenses > monthlyExpenses) {
          return "You have significant investable income - ${_formatCurrency(monthlyIncome - monthlyExpenses, null)} per month. This puts you in a strong position to build wealth through investments.";
        } else if (savingsRate > 15) {
          return "Your saving habits provide a solid foundation for investing. Even small, consistent investments can grow substantially over time through compound interest.";
        } else {
          return "You're building the foundation for investing by tracking your finances. The next step is to start putting your savings to work in investment vehicles.";
        }

      case 'The Minimalist':
        if (essentialRatio > 0.7) {
          return "You're a true minimalist - ${(essentialRatio * 100).toStringAsFixed(0)}% of your spending goes to essentials. This focused approach reduces financial waste and increases your savings potential.";
        } else {
          return "You have a balanced approach to spending, with ${(essentialRatio * 100).toStringAsFixed(0)}% on essentials. There's room to optimize, but you're on the right track.";
        }

      case 'The Balanced':
        return "You've found a healthy balance in your finances. Your savings rate of ${savingsRate.toStringAsFixed(1)}%, essential spending of ${(essentialRatio * 100).toStringAsFixed(0)}%, and budget adherence show a well-rounded approach to money management.";

      case 'The Enthusiast':
        return "You're actively engaged with your finances! With $totalTransactions transactions tracked, you're building awareness of your spending patterns. This awareness is the foundation of financial intelligence.";

      case 'The Strategist':
        if (goalProgress > 50) {
          return "You're making excellent progress on your savings goals - ${goalProgress.toStringAsFixed(0)}% complete on average. Your strategic approach to saving is paying off.";
        } else {
          return "You've set clear savings goals, which is a strategic move. Breaking them down into smaller milestones can help maintain momentum.";
        }

      case 'The Security-Seeker':
        if (emergencyFundMonths > 6) {
          return "Your emergency fund of ${emergencyFundMonths.toStringAsFixed(1)} months of expenses provides exceptional financial security. This peace of mind is invaluable.";
        } else if (emergencyFundMonths > 3) {
          return "You've built a solid emergency fund covering ${emergencyFundMonths.toStringAsFixed(1)} months of expenses. This puts you ahead of most people.";
        } else if (emergencyFundMonths > 0) {
          return "You're building your emergency fund. Even a small fund can prevent debt when unexpected expenses arise.";
        } else {
          return "Building an emergency fund should be your top priority. Aim for 3-6 months of expenses as your safety net.";
        }

      case 'The Experience-Seeker':
        return "You prioritize experiences and enjoyment in your spending. This life-affirming approach is valuable - the key is balancing it with long-term financial health.";

      case 'The Disciplined':
        return "Your financial discipline is impressive. Whether through budgets, consistent savings, or goal progress, you're showing the consistency that builds lasting wealth.";

      default:
        return "Your financial personality is emerging. Keep tracking to discover more insights about your unique approach to money.";
    }
  }

  static String _generateAdvice(
      String personality,
      double savingsRate,
      double emergencyFundMonths,
      double budgetAdherence,
      double goalProgress,
      double essentialRatio,
      bool hasSufficientData,
      ) {

    if (!hasSufficientData) {
      return "Start by tracking your expenses consistently for 30 days. This will give you a clear picture of where your money goes and help us provide personalized advice.";
    }

    switch (personality) {
      case 'The Saver':
        if (savingsRate > 25) {
          return "You're saving excellently! Now consider whether your savings are working hard enough. Look into tax-advantaged retirement accounts or index funds to make your money grow.";
        } else if (savingsRate > 15) {
          return "Great saving habits! Try to increase your savings rate by 1-2% each year. Even small increases compound significantly over time.";
        } else {
          return "Good start on saving. The 50/30/20 rule is a helpful guide: 50% for needs, 30% for wants, and 20% for savings. You're at ${savingsRate.toStringAsFixed(0)}% savings - aim to gradually increase it.";
        }

      case 'The Planner':
        if (budgetAdherence > 0.8) {
          return "Your budgeting is excellent. Next step: try zero-based budgeting where every dollar has a job. This can help optimize your spending even further.";
        } else if (budgetAdherence > 0.5) {
          return "You're using budgets well. Review them monthly and adjust categories that are consistently over or under. Budgets should be flexible tools, not rigid restrictions.";
        } else {
          return "Start with a simple budget: track your income, fixed expenses, and discretionary spending. Apps like this one make it easy. Even a basic budget increases financial awareness by 30%.";
        }

      case 'The Investor':
        if (savingsRate > 20) {
          return "With your saving capacity, consider the investment order: 1) Emergency fund, 2) Employer retirement match, 3) High-interest debt, 4) Tax-advantaged accounts, 5) Taxable investments.";
        } else {
          return "Building an investment portfolio starts with savings. Focus on increasing your savings rate first, then explore low-cost index funds for long-term growth.";
        }

      case 'The Minimalist':
        if (essentialRatio > 0.7) {
          return "Your minimalist approach is powerful. Consider applying it to subscriptions and recurring expenses too - you might find more areas to simplify.";
        } else {
          return "Try a 'spending freeze' week where you only buy essentials. This can reveal which discretionary expenses truly add value to your life.";
        }

      case 'The Balanced':
        return "Your balanced approach is sustainable. To optimize, track your spending for 3 months and look for patterns. Small tweaks in your highest spending categories can yield significant savings.";

      case 'The Enthusiast':
        if (savingsRate < 10) {
          return "Your engagement is great! Try the 'pay yourself first' method - automatically transfer money to savings right after payday. This ensures you save before spending on enjoyment.";
        } else {
          return "You're balancing enjoyment with savings well. Consider tracking your spending by category to see if your spending aligns with your values and priorities.";
        }

      case 'The Strategist':
        if (goalProgress > 50) {
          return "Your goal progress is impressive. Consider setting up separate sinking funds for different goals to track them more precisely and stay motivated.";
        } else {
          return "Break your goals into smaller milestones and celebrate each achievement. This psychological boost can help maintain momentum toward larger targets.";
        }

      case 'The Security-Seeker':
        if (emergencyFundMonths > 6) {
          return "Your emergency fund is strong. Consider investing excess cash beyond 6 months of expenses in moderate-risk investments for better returns.";
        } else if (emergencyFundMonths > 3) {
          return "You have a solid emergency fund. Next, consider if you have appropriate insurance coverage - health, life, and disability insurance are the next layer of financial protection.";
        } else if (emergencyFundMonths > 0) {
          return "Focus on building your emergency fund to 3-6 months of expenses. Even ₹500 per week adds up to ₹26,000 in a year. Start small but start now.";
        } else {
          return "Your top priority should be building an emergency fund of 3-6 months of expenses. This is your financial safety net.";
        }

      case 'The Experience-Seeker':
        if (essentialRatio < 0.5) {
          return "You prioritize experiences, which is wonderful. Just ensure your essential needs are fully covered first. Consider the 50/30/20 framework as a reality check.";
        } else {
          return "You're balancing experiences with responsibilities well. To afford more experiences, look for ways to reduce fixed costs like subscriptions or utilities.";
        }

      case 'The Disciplined':
        return "Your discipline is your superpower. Use it to automate your finances: automatic bill payments, automatic savings transfers, and automatic investments. This creates a system that works even when you're not thinking about it.";

      default:
        return "The first step to financial wellness is awareness. You're already tracking your expenses, which puts you ahead of most people. Keep going!";
    }
  }

  static Map<String, String> _compileEvidence(
      double savingsRate,
      double emergencyFundMonths,
      double budgetAdherence,
      double goalProgress,
      double essentialRatio,
      int totalTransactions,
      double monthlyIncome,
      double monthlyExpenses,
      double totalBalance,
      bool hasSufficientData,
      ) {

    final evidence = <String, String>{};

    if (!hasSufficientData) {
      evidence['Getting Started'] = "You've begun tracking your finances. Add more transactions to unlock detailed insights.";
      return evidence;
    }

    // Only add evidence for actual achievements - no fluff
    if (savingsRate > 20) {
      evidence['Strong Saver'] = "You save ${savingsRate.toStringAsFixed(0)}% of your income - well above the average of 5-10%";
    } else if (savingsRate > 10) {
      evidence['Consistent Saver'] = "You save ${savingsRate.toStringAsFixed(0)}% of your income, matching or exceeding recommended rates";
    } else if (savingsRate > 0) {
      evidence['Building Savings'] = "You're saving ${savingsRate.toStringAsFixed(0)}% of your income. Every bit counts!";
    }

    if (emergencyFundMonths >= 6) {
      evidence['Fully Protected'] = "Your emergency fund covers ${emergencyFundMonths.toStringAsFixed(1)} months of expenses - excellent financial security";
    } else if (emergencyFundMonths >= 3) {
      evidence['Good Safety Net'] = "Your emergency fund covers ${emergencyFundMonths.toStringAsFixed(1)} months of expenses - you're prepared for most surprises";
    } else if (emergencyFundMonths >= 1) {
      evidence['Starting Safety Net'] = "You have ${emergencyFundMonths.toStringAsFixed(1)} months of expenses saved - a good start";
    }

    if (budgetAdherence > 0.8) {
      evidence['Budget Master'] = "You stick to your budgets ${(budgetAdherence * 100).toStringAsFixed(0)}% of the time - exceptional discipline";
    } else if (budgetAdherence > 0.6) {
      evidence['Budget Conscious'] = "You follow your budgets most of the time - good financial awareness";
    }

    if (goalProgress > 80) {
      evidence['Goal Getter'] = "You're ${goalProgress.toStringAsFixed(0)}% toward your savings goals - almost there!";
    } else if (goalProgress > 50) {
      evidence['Making Progress'] = "You're more than halfway to your savings goals - keep going!";
    } else if (goalProgress > 0) {
      evidence['Goal Setter'] = "You've started working toward your savings goal(s) - that's the first step";
    }

    if (essentialRatio > 0.6) {
      evidence['Essential Focus'] = "${(essentialRatio * 100).toStringAsFixed(0)}% of your spending goes to necessities - disciplined approach";
    } else if (essentialRatio < 0.4) {
      evidence['Lifestyle Focus'] = "Most of your spending goes to discretionary items - you value experiences and lifestyle";
    }

    if (totalTransactions > 50) {
      evidence['Diligent Tracker'] = "You've tracked over $totalTransactions transactions - excellent financial awareness";
    } else if (totalTransactions > 20) {
      evidence['Active Tracker'] = "You've tracked $totalTransactions transactions - building good habits";
    }

    if (monthlyIncome > monthlyExpenses * 1.5) {
      evidence['High Income Margin'] = "Your income significantly exceeds expenses - great capacity for savings and investments";
    }

    if (totalBalance > monthlyExpenses * 12) {
      evidence['Wealth Builder'] = "You have over a year of expenses saved - exceptional financial position";
    }

    return evidence;
  }

  static String _formatCurrency(double amount, Currency? currency) {
    final symbol = currency?.symbol ?? '₹';

    if (amount >= 100000) {
      return '$symbol${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '$symbol${amount.toStringAsFixed(0)}';
  }
}