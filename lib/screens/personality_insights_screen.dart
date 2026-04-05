import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../models/user_model.dart';
import '../widgets/currency_formatter.dart';
import '../providers/theme_provider.dart';

class PersonalityInsightsScreen extends StatelessWidget {
  final Map<String, dynamic> analysis;
  final Currency currency;

  const PersonalityInsightsScreen({
    Key? key,
    required this.analysis,
    required this.currency,
  }) : super(key: key);

  // Helper to get secondary color based on primary
  Color _getSecondaryColor(Color primary) {
    if (primary == const Color(0xFF007AFF)) return const Color(0xFF00C1D4);
    if (primary == const Color(0xFF34C759)) return const Color(0xFF74C69D);
    if (primary == const Color(0xFFAF52DE)) return const Color(0xFFD291FF);
    if (primary == const Color(0xFF1C1C1E)) return const Color(0xFF3A3A3C);
    return const Color(0xFF00C1D4);
  }

  // Calculate realistic scores based on data volume
  double _getRealisticScore(double rawScore, int transactionCount) {
    // If user has very few transactions, scores should be more conservative
    if (transactionCount < 10) {
      // Cap scores at 40 for users with minimal data
      return (rawScore * 0.4).clamp(0, 40);
    } else if (transactionCount < 30) {
      // Cap at 60 for users with some data
      return (rawScore * 0.6).clamp(0, 60);
    } else if (transactionCount < 100) {
      // Cap at 80 for users with moderate data
      return (rawScore * 0.8).clamp(0, 80);
    } else {
      // Full range for users with substantial data
      return rawScore.clamp(0, 100);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final primaryPersonality = analysis['primary'] as String;
    final secondaryPersonality = analysis['secondary'] as String;
    final scores = analysis['scores'] as Map<String, double>;
    final reasoning = analysis['reasoning'] as String;
    final advice = analysis['advice'] as String;
    final evidence = analysis['evidence'] as Map<String, String>;
    final metrics = analysis['metrics'] as Map<String, dynamic>;

    // Get transaction count for scaling
    final transactionCount = metrics['totalTransactions'] as int? ?? 0;
    final hasSufficientData = metrics['hasSufficientData'] as bool? ?? false;

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text('Personality Insights'),
        backgroundColor: themeProvider.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data Quality Indicator (for users with few transactions)
            if (transactionCount < 30)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warning.withOpacity(0.1),
                      AppColors.warning.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: AppColors.warning,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Building Your Profile',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            transactionCount < 10
                                ? 'Add more transactions (${10 - transactionCount} more) for more accurate insights'
                                : 'Keep tracking! Your personality will become clearer with more data',
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
              ),

            // Primary Personality Header with theme colors
            Container(
              padding: const EdgeInsets.all(24),
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
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeProvider.primaryColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.psychology,
                      color: themeProvider.primaryColor,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      primaryPersonality,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Also showing traits of $secondaryPersonality',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    reasoning,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!hasSufficientData) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.track_changes,
                            color: AppColors.info,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Based on $transactionCount transactions',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Personality Scores with realistic scaling
            Container(
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
                    children: [
                      Text(
                        'Personality Scores',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.primaryColor,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeProvider.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Max: ${transactionCount < 10 ? 40 : transactionCount < 30 ? 60 : transactionCount < 100 ? 80 : 100}pts',
                          style: TextStyle(
                            fontSize: 11,
                            color: themeProvider.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildScoreBar('Saver', _getRealisticScore(scores['The Saver'] ?? 0, transactionCount), themeProvider),
                  _buildScoreBar('Planner', _getRealisticScore(scores['The Planner'] ?? 0, transactionCount), themeProvider),
                  _buildScoreBar('Investor', _getRealisticScore(scores['The Investor'] ?? 0, transactionCount), themeProvider),
                  _buildScoreBar('Minimalist', _getRealisticScore(scores['The Minimalist'] ?? 0, transactionCount), themeProvider),
                  _buildScoreBar('Balanced', _getRealisticScore(scores['The Balanced'] ?? 0, transactionCount), themeProvider),
                  _buildScoreBar('Enthusiast', _getRealisticScore(scores['The Enthusiast'] ?? 0, transactionCount), themeProvider),
                  _buildScoreBar('Strategist', _getRealisticScore(scores['The Strategist'] ?? 0, transactionCount), themeProvider),
                  _buildScoreBar('Security-Seeker', _getRealisticScore(scores['The Security-Seeker'] ?? 0, transactionCount), themeProvider),
                  _buildScoreBar('Experience-Seeker', _getRealisticScore(scores['The Experience-Seeker'] ?? 0, transactionCount), themeProvider),
                  _buildScoreBar('Disciplined', _getRealisticScore(scores['The Disciplined'] ?? 0, transactionCount), themeProvider),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Personalized Advice with theme colors
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeProvider.primaryColor.withOpacity(0.1),
                    _getSecondaryColor(themeProvider.primaryColor).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: themeProvider.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: themeProvider.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Personalized Advice',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    advice,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  if (!hasSufficientData) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tips_and_updates,
                            color: themeProvider.primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Track at least 30 transactions for more personalized advice',
                              style: TextStyle(
                                fontSize: 12,
                                color: themeProvider.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Evidence-Based Reasons
            Container(
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
                    children: [
                      Icon(
                        Icons.analytics,
                        color: themeProvider.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Why You Are a $primaryPersonality',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (evidence.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 40,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              transactionCount < 10
                                  ? 'Add more transactions to see evidence'
                                  : 'Evidence will appear as you track more',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...evidence.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: themeProvider.primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.value,
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

            const SizedBox(height: 20),

            // Key Metrics with currency from user model
            Container(
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
                  Text(
                    'Key Financial Metrics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMetricRow(
                    'Savings Rate',
                    '${(metrics['savingsRate'] as double).toStringAsFixed(1)}%',
                    Icons.trending_up,
                    themeProvider,
                  ),
                  _buildMetricRow(
                    'Emergency Fund',
                    '${(metrics['emergencyFundMonths'] as double).toStringAsFixed(1)} months',
                    Icons.security,
                    themeProvider,
                  ),
                  _buildMetricRow(
                    'Budget Adherence',
                    '${(metrics['budgetAdherence'] as double).toStringAsFixed(1)}%',
                    Icons.pie_chart,
                    themeProvider,
                  ),
                  _buildMetricRow(
                    'Goal Progress',
                    '${(metrics['goalProgress'] as double).toStringAsFixed(1)}%',
                    Icons.flag,
                    themeProvider,
                  ),
                  _buildMetricRow(
                    'Luxury Ratio',
                    '${(metrics['luxuryRatio'] as double).toStringAsFixed(1)}%',
                    Icons.weekend,
                    themeProvider,
                  ),
                  _buildMetricRow(
                    'Total Transactions',
                    '${metrics['totalTransactions']}',
                    Icons.receipt,
                    themeProvider,
                  ),
                  _buildMetricRow(
                    'Avg Transaction',
                    CurrencyFormatter.format(metrics['avgTransactionAmount'] as double, currency),
                    Icons.attach_money,
                    themeProvider,
                  ),
                  _buildMetricRow(
                    'Monthly Income',
                    CurrencyFormatter.format(metrics['monthlyIncome'] as double, currency),
                    Icons.trending_up,
                    themeProvider,
                  ),
                  _buildMetricRow(
                    'Monthly Expenses',
                    CurrencyFormatter.format(metrics['monthlyExpenses'] as double, currency),
                    Icons.trending_down,
                    themeProvider,
                  ),
                  _buildMetricRow(
                    'Total Balance',
                    CurrencyFormatter.format(metrics['totalBalance'] as double, currency),
                    Icons.account_balance_wallet,
                    themeProvider,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBar(String label, double score, ThemeProvider themeProvider) {
    final double normalizedScore = (score / 100).clamp(0, 1).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${score.toStringAsFixed(0)} pts',
                style: TextStyle(
                  fontSize: 12,
                  color: score < 30 ? AppColors.textLight : themeProvider.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
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
                widthFactor: normalizedScore,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [themeProvider.primaryColor, _getSecondaryColor(themeProvider.primaryColor)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: themeProvider.primaryColor.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: themeProvider.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: themeProvider.primaryColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}