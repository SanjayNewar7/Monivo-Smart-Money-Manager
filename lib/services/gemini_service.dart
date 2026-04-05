import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/user_model.dart';
import 'multi_api_key_manager.dart';

class GeminiService {
  static const String _model = 'gemini-3-flash-preview';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  String _currentKey = APIKeyManager.getCurrentKey();

  Future<String> getFinancialAdvice(
      String userQuery,
      FinancialContext context,
      ) async {
    final prompt = _buildUltraCompactPrompt(userQuery, context);
    int maxAttempts = APIKeyManager.getKeyCount();

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        print('📤 Attempt ${attempt + 1} with API Key ${_getKeyIndex(_currentKey) + 1}');

        final response = await http.post(
          Uri.parse('$_baseUrl?key=$_currentKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {'parts': [{'text': prompt}]}
            ],
            'generationConfig': {
              'temperature': 0.5, // Lower temperature for more focused responses
              'maxOutputTokens': 1000, // Increased for complete responses
            }
          }),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          APIKeyManager.markKeySuccessful(_currentKey);
          final data = jsonDecode(response.body);
          String aiText = data['candidates'][0]['content']['parts'][0]['text'];

          // Force complete the response if truncated
          aiText = _forceCompleteResponse(aiText, userQuery);
          aiText = _ensureCompleteResponse(aiText);

          return aiText.trim();
        } else if (response.statusCode == 429 || response.statusCode == 403) {
          print('❌ Key ${_getKeyIndex(_currentKey) + 1} failed');
          APIKeyManager.markKeyFailed(_currentKey, 'Status ${response.statusCode}');
          _currentKey = APIKeyManager.getNextKey();
          continue;
        } else {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
          print('❌ Error: $errorMessage');
          _currentKey = APIKeyManager.getNextKey();
          continue;
        }
      } catch (e) {
        print('❌ Network Error: $e');
        _currentKey = APIKeyManager.getNextKey();
        continue;
      }
    }

    APIKeyManager.printKeyStatus();
    return "⚠️ All API services unavailable. Please try again in a few minutes.";
  }

  // ULTRA COMPACT PROMPT - Uses minimum tokens
  String _buildUltraCompactPrompt(String query, FinancialContext context) {
    // One-line health status
    String health = context.monthlySavings < 0
        ? "DEFICIT: -${context.currency}${(-context.monthlySavings).toStringAsFixed(0)}"
        : "Saves ${context.currency}${context.monthlySavings.toStringAsFixed(0)} (${context.savingsRate.toStringAsFixed(0)}%)";

    return '''
Monivo AI. Answer COMPLETELY. Max 150 words. NEVER stop mid-sentence.

User: ${context.userName}
$health
Top spend: ${context.topCategory} ${context.currency}${context.topCategoryAmount.toStringAsFixed(0)}
Budget: ${context.budgetsExceeded} exceeded
Goal: ${context.overallGoalProgress.toStringAsFixed(0)}%

Q: $query

FORMAT:
[Emoji] [Complete 2-3 sentence answer]

**Tips:**
• [Short action 1]
• [Short action 2]

[Closing sentence] ⚠️ Educational advice.

WRITE COMPLETE RESPONSE NOW (FINISH ALL SENTENCES):
''';
  }

  // Force complete truncated responses
  String _forceCompleteResponse(String text, String originalQuery) {
    if (text.isEmpty) return text;

    // Check if response is incomplete
    bool isIncomplete = false;
    String trimmed = text.trim();

    // Check for incomplete endings
    if (trimmed.endsWith('•') || trimmed.endsWith('-') || trimmed.endsWith(',') ||
        trimmed.endsWith('and') || trimmed.endsWith('or') || trimmed.endsWith('to') ||
        trimmed.endsWith('for') || trimmed.endsWith('with') || trimmed.endsWith('from')) {
      isIncomplete = true;
    }

    // Check last character
    String lastChar = trimmed.substring(trimmed.length - 1);
    if (!['.', '!', '?', '"', ')', '⚠️'].contains(lastChar) && trimmed.length > 50) {
      isIncomplete = true;
    }

    // If incomplete, append appropriate completion
    if (isIncomplete) {
      // Remove incomplete last line
      List<String> lines = text.split('\n');
      if (lines.isNotEmpty) {
        String lastLine = lines.last;
        if (lastLine.contains('•') && lastLine.length < 40) {
          lines.removeLast(); // Remove incomplete bullet
        } else if (!lastLine.contains('⚠️') && lastLine.length < 50) {
          lines.removeLast(); // Remove incomplete sentence
        }
        text = lines.join('\n');
      }

      // Add smart completion based on query
      String completion = '';
      String qLower = originalQuery.toLowerCase();

      if (qLower.contains('book') || qLower.contains('read') || qLower.contains('recommend')) {
        completion = '\n\n📚 Start with "The Psychology of Money" by Morgan Housel and "Rich Dad Poor Dad" by Robert Kiyosaki.';
      } else if (qLower.contains('save') || qLower.contains('saving')) {
        completion = '\n\n💡 Track expenses for 30 days. Cut top non-essential category by 20%. Automate savings.';
      } else if (qLower.contains('budget')) {
        completion = '\n\n📊 Follow 50/30/20 rule: 50% needs, 30% wants, 20% savings/debt.';
      } else if (qLower.contains('invest')) {
        completion = '\n\n💰 Start with index funds or mutual funds. Diversify across stocks and bonds.';
      } else if (qLower.contains('debt')) {
        completion = '\n\n🎯 Use debt avalanche method: pay highest interest first while making minimum payments on others.';
      } else {
        completion = '\n\n💪 Small consistent steps lead to financial freedom. Review your progress weekly.';
      }

      text = text.trim() + completion;
    }

    return text;
  }

  // Helper to ensure response is complete with disclaimer
  String _ensureCompleteResponse(String text) {
    if (text.isEmpty) return text;

    if (!text.contains('⚠️ Educational advice') && !text.contains('⚠️ This is educational advice')) {
      text += '\n\n⚠️ Educational advice.';
    }

    return text.trim();
  }

  String _getMaskedKey(String key) {
    if (key.length <= 8) return '***';
    return '...${key.substring(key.length - 4)}';
  }

  int _getKeyIndex(String key) {
    return APIKeyManager.getKeyIndex(key);
  }

  Future<bool> testApiConnection() async {
    print('🔍 Testing all API keys...');
    APIKeyManager.printKeyStatus();

    for (int i = 0; i < APIKeyManager.getKeyCount(); i++) {
      final testKey = APIKeyManager.getKeyByIndex(i);
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl?key=$testKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {'parts': [{'text': 'Say "OK" if you can read this message.'}]}
            ]
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          print('✅ API Key ${i + 1} is working!');
          APIKeyManager.markKeySuccessful(testKey);
        } else {
          print('❌ API Key ${i + 1} failed');
          APIKeyManager.markKeyFailed(testKey, 'Test failed');
        }
      } catch (e) {
        print('❌ API Key ${i + 1} error: $e');
        APIKeyManager.markKeyFailed(testKey, e.toString());
      }
    }
    return APIKeyManager.hasAvailableKey();
  }
}

// FinancialContext class remains the same
class FinancialContext {
  final String userName;
  final String currency;
  final String? occupation;
  final String? location;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double monthlySavings;
  final double savingsRate;
  final double expenseToIncomeRatio;
  final String topCategory;
  final double topCategoryAmount;
  final double topCategoryPercentage;
  final int categoryCount;
  final double dailyAverageSpend;
  final int budgetCount;
  final int budgetsOnTrack;
  final int budgetsAtRisk;
  final int budgetsExceeded;
  final String topBudgetInfo;
  final int goalCount;
  final int goalsOnTrack;
  final int goalsBehind;
  final double totalGoalTarget;
  final double totalGoalCurrent;
  final double overallGoalProgress;
  final String goalNames;
  final int accountCount;
  final double totalBalance;
  final String primaryAccountInfo;
  final int transactionCount;
  final int currentMonthTransactionCount;
  final String? mostActiveSpendingDay;
  final String recentTransactions;

  FinancialContext({
    required this.userName,
    required this.currency,
    this.occupation,
    this.location,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.monthlySavings,
    required this.savingsRate,
    required this.expenseToIncomeRatio,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.topCategoryPercentage,
    required this.categoryCount,
    required this.dailyAverageSpend,
    required this.budgetCount,
    required this.budgetsOnTrack,
    required this.budgetsAtRisk,
    required this.budgetsExceeded,
    required this.topBudgetInfo,
    required this.goalCount,
    required this.goalsOnTrack,
    required this.goalsBehind,
    required this.totalGoalTarget,
    required this.totalGoalCurrent,
    required this.overallGoalProgress,
    required this.goalNames,
    required this.accountCount,
    required this.totalBalance,
    required this.primaryAccountInfo,
    required this.transactionCount,
    required this.currentMonthTransactionCount,
    this.mostActiveSpendingDay,
    required this.recentTransactions,
  });
}