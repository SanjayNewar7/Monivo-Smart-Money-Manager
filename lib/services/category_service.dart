import 'dart:ui';

import '../models/transaction.dart';
import 'storage_service.dart';

class CategoryService {
  static Future<List<Category>> getExpenseCategories() async {
    final allCategories = await StorageService.getCategories();
    return allCategories
        .where((c) => c.type == TransactionType.expense)
        .toList();
  }

  static Future<List<Category>> getIncomeCategories() async {
    final allCategories = await StorageService.getCategories();
    return allCategories
        .where((c) => c.type == TransactionType.income)
        .toList();
  }

  static Future<Category?> getCategoryByName(String name) async {
    final allCategories = await StorageService.getCategories();
    try {
      return allCategories.firstWhere((c) => c.name == name);
    } catch (e) {
      return null;
    }
  }

  static Future<void> addCategory(Category category) async {
    final categories = await StorageService.getCategories();
    categories.add(category);
    await StorageService.saveCategories(categories);
  }

  static Future<void> updateCategory(Category updatedCategory) async {
    final categories = await StorageService.getCategories();
    final index = categories.indexWhere((c) => c.id == updatedCategory.id);
    if (index != -1) {
      categories[index] = updatedCategory;
      await StorageService.saveCategories(categories);
    }
  }

  static Future<void> deleteCategory(String id) async {
    final categories = await StorageService.getCategories();
    categories.removeWhere((c) => c.id == id && !c.isDefault);
    await StorageService.saveCategories(categories);
  }

  static String getCategoryIcon(String categoryName) {
    final Map<String, String> icons = {
      'Food & Dining': '🍕',
      'Transportation': '🚗',
      'Bills & Utilities': '💡',
      'Shopping': '🛍️',
      'Entertainment': '🎬',
      'Healthcare': '🏥',
      'Education': '📚',
      'Travel': '✈️',
      'Groceries': '🛒',
      'Insurance': '🛡️',
      'Subscriptions': '📱',
      'Personal Care': '💇',
      'Gifts & Donations': '🎁',
      'Home Maintenance': '🔧',
      'Salary': '💰',
      'Freelance': '💼',
      'Investment': '📈',
      'Business': '🏢',
      'Rental Income': '🏠',
      'Gift': '🎁',
      'Bonus': '✨',
      'Refund': '↩️',
      'Other Income': '💵',
      'Other': '📦',
    };
    return icons[categoryName] ?? '📦';
  }

  static Color getCategoryColor(String categoryName) {
    final Map<String, Color> colors = {
      'Food & Dining': const Color(0xFFFF6B6B),
      'Transportation': const Color(0xFF4ECDC4),
      'Bills & Utilities': const Color(0xFF45B7D1),
      'Shopping': const Color(0xFFFFA07A),
      'Entertainment': const Color(0xFFDDA15E),
      'Healthcare': const Color(0xFFBC6C25),
      'Education': const Color(0xFF606C38),
      'Travel': const Color(0xFF9C89B8),
      'Groceries': const Color(0xFFF2C14E),
      'Insurance': const Color(0xFFE5989B),
      'Subscriptions': const Color(0xFFB5838D),
      'Personal Care': const Color(0xFF6D6875),
      'Gifts & Donations': const Color(0xFFE5989B),
      'Home Maintenance': const Color(0xFFB23B3B),
      'Salary': const Color(0xFF52B788),
      'Freelance': const Color(0xFF74C69D),
      'Investment': const Color(0xFF95D5B2),
      'Business': const Color(0xFF40916C),
      'Rental Income': const Color(0xFF2D6A4F),
      'Gift': const Color(0xFFB7E4C7),
      'Bonus': const Color(0xFFA7C957),
      'Refund': const Color(0xFF6B9080),
      'Other Income': const Color(0xFF52B788),
      'Other': const Color(0xFF6C757D),
    };
    return colors[categoryName] ?? const Color(0xFF6C757D);
  }

  static Future<List<String>> getCategoryNamesByType(TransactionType type) async {
    final categories = await StorageService.getCategories();
    return categories
        .where((c) => c.type == type)
        .map((c) => c.name)
        .toList();
  }

  static Future<Map<String, double>> getCategoryTotals(
      List<Transaction> transactions,
      TransactionType type,
      ) {
    final filtered = transactions.where((t) => t.type == type);
    final Map<String, double> totals = {};

    for (var t in filtered) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }

    return Future.value(totals);
  }

  static Future<Map<String, double>> getCategoryPercentages(
      List<Transaction> transactions,
      TransactionType type,
      ) async {
    final totals = await getCategoryTotals(transactions, type);
    final totalAmount = totals.values.fold(0.0, (sum, amount) => sum + amount);

    final Map<String, double> percentages = {};
    totals.forEach((category, amount) {
      percentages[category] = (amount / totalAmount) * 100;
    });

    return percentages;
  }

  static Future<Map<String, dynamic>> getTopCategory(
      List<Transaction> transactions,
      TransactionType type,
      ) async {
    final totals = await getCategoryTotals(transactions, type);

    if (totals.isEmpty) {
      return {'name': 'N/A', 'amount': 0.0};
    }

    final topEntry = totals.entries.reduce((a, b) => a.value > b.value ? a : b);

    return {
      'name': topEntry.key,
      'amount': topEntry.value,
    };
  }
}