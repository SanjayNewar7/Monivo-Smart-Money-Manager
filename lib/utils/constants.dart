import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AppConstants {
  // App Info
  static const String appName = 'BlueWallet NP';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String userKey = 'user_profile';
  static const String transactionsKey = 'transactions';
  static const String budgetsKey = 'budgets';
  static const String goalsKey = 'savings_goals';
  static const String accountsKey = 'accounts';
  static const String categoriesKey = 'categories';
  static const String isFirstLaunchKey = 'is_first_launch';

  // Date Formats
  static const String dateFormatFull = 'EEEE, MMMM d, yyyy';
  static const String dateFormatMedium = 'MMM d, yyyy';
  static const String dateFormatShort = 'MMM d';
  static const String dateFormatMonth = 'MMMM yyyy';
  static const String timeFormat = 'h:mm a';

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Default Values
  static const double defaultBudgetLimit = 10000;
  static const double defaultGoalTarget = 50000;

  // Categories
  static const List<String> expenseCategories = [
    'Food & Dining',
    'Transportation',
    'Bills & Utilities',
    'Shopping',
    'Entertainment',
    'Healthcare',
    'Education',
    'Travel',
    'Groceries',
    'Insurance',
    'Subscriptions',
    'Personal Care',
    'Gifts & Donations',
    'Home Maintenance',
    'Other',
  ];

  static const List<String> incomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Business',
    'Rental Income',
    'Gift',
    'Bonus',
    'Refund',
    'Other Income',
  ];

  // Icons Map
  static const Map<String, String> categoryIcons = {
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

  // Colors Map
  static const Map<String, Color> categoryColors = {
    'Food & Dining': Color(0xFFFF6B6B),
    'Transportation': Color(0xFF4ECDC4),
    'Bills & Utilities': Color(0xFF45B7D1),
    'Shopping': Color(0xFFFFA07A),
    'Entertainment': Color(0xFFDDA15E),
    'Healthcare': Color(0xFFBC6C25),
    'Education': Color(0xFF606C38),
    'Travel': Color(0xFF9C89B8),
    'Groceries': Color(0xFFF2C14E),
    'Insurance': Color(0xFFE5989B),
    'Subscriptions': Color(0xFFB5838D),
    'Personal Care': Color(0xFF6D6875),
    'Gifts & Donations': Color(0xFFE5989B),
    'Home Maintenance': Color(0xFFB23B3B),
    'Salary': Color(0xFF52B788),
    'Freelance': Color(0xFF74C69D),
    'Investment': Color(0xFF95D5B2),
    'Business': Color(0xFF40916C),
    'Rental Income': Color(0xFF2D6A4F),
    'Gift': Color(0xFFB7E4C7),
    'Bonus': Color(0xFFA7C957),
    'Refund': Color(0xFF6B9080),
    'Other Income': Color(0xFF52B788),
    'Other': Color(0xFF6C757D),
  };

  // Currencies List
  static const List<Currency> currencies = [
    Currency.inr,
    Currency.usd,
    Currency.eur,
    Currency.gbp,
    Currency.jpy,
    Currency.cad,
    Currency.aud,
    Currency.chf,
    Currency.cny,
    Currency.krw,
  ];
}

class ApiEndpoints {
  static const String baseUrl = 'https://api.bluewallet.com/v1';
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String transactions = '$baseUrl/transactions';
  static const String budgets = '$baseUrl/budgets';
  static const String goals = '$baseUrl/goals';
  static const String accounts = '$baseUrl/accounts';
  static const String categories = '$baseUrl/categories';
  static const String user = '$baseUrl/user';
  static const String analytics = '$baseUrl/analytics';
}

class ErrorMessages {
  static const String networkError = 'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unauthorized = 'Session expired. Please login again.';
  static const String invalidData = 'Invalid data. Please check your input.';
  static const String emptyField = 'This field cannot be empty.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String invalidPhone = 'Please enter a valid phone number.';
  static const String passwordTooShort = 'Password must be at least 6 characters.';
  static const String passwordsDoNotMatch = 'Passwords do not match.';
  static const String amountTooHigh = 'Amount exceeds maximum limit.';
  static const String insufficientBalance = 'Insufficient balance.';
  static const String budgetExceeded = 'This transaction will exceed your budget!';
}

class SuccessMessages {
  static const String transactionAdded = 'Transaction added successfully!';
  static const String transactionUpdated = 'Transaction updated successfully!';
  static const String transactionDeleted = 'Transaction deleted successfully!';
  static const String budgetCreated = 'Budget created successfully!';
  static const String budgetUpdated = 'Budget updated successfully!';
  static const String goalCreated = 'Savings goal created successfully!';
  static const String goalUpdated = 'Savings goal updated successfully!';
  static const String profileUpdated = 'Profile updated successfully!';
  static const String accountLinked = 'Account linked successfully!';
  static const String settingsSaved = 'Settings saved successfully!';
}