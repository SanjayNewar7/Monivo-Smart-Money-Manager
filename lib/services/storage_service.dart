import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class StorageService {
  static const String _userKey = 'user_profile_'; // Will append user ID
  static const String _transactionsKey = 'transactions_';
  static const String _budgetsKey = 'budgets_';
  static const String _goalsKey = 'savings_goals_';
  static const String _accountsKey = 'accounts_';
  static const String _categoriesKey = 'categories_';
  static const String _isFirstLaunchKey = 'is_first_launch';

  // Helper to get user-specific key
  static Future<String> _getUserId() async {
    final phone = await AuthService.getCurrentUserPhone();
    if (phone == null) {
      throw Exception('No user logged in');
    }
    return phone;
  }

  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstLaunchKey) ?? true;
  }

  static Future<void> setFirstLaunchCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstLaunchKey, false);
  }

  // Save user with ID
  static Future<void> saveUser(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_userKey${user.id}', jsonEncode(user.toJson()));
    await setFirstLaunchCompleted();
  }

  // Get user by ID
  static Future<UserProfile?> getUser([String? phone]) async {
    final prefs = await SharedPreferences.getInstance();
    final targetPhone = phone ?? await AuthService.getCurrentUserPhone();

    if (targetPhone == null || targetPhone.isEmpty) return null;

    final userJson = prefs.getString('$_userKey$targetPhone');
    if (userJson != null) {
      return UserProfile.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  // Save transactions for current user
  static Future<void> saveTransactions(List<Transaction> transactions) async {
    final userId = await _getUserId();
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = transactions.map((t) => t.toJson()).toList();
    await prefs.setString('$_transactionsKey$userId', jsonEncode(transactionsJson));
  }

  // Get transactions for current user
  static Future<List<Transaction>> getTransactions() async {
    final userId = await _getUserId();
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getString('$_transactionsKey$userId');
    if (transactionsJson != null) {
      final List<dynamic> decoded = jsonDecode(transactionsJson);
      return decoded.map((item) => Transaction.fromJson(item)).toList();
    }
    return [];
  }

  // FIXED: Add transaction with account balance update
  static Future<void> addTransaction(Transaction transaction) async {
    final transactions = await getTransactions();
    final accounts = await getAccounts();

    // Find the account involved in this transaction
    final accountIndex = accounts.indexWhere((a) => a.name == transaction.account);

    if (accountIndex != -1) {
      // Update the account balance based on transaction type
      if (transaction.type == TransactionType.income) {
        accounts[accountIndex] = Account(
          id: accounts[accountIndex].id,
          name: accounts[accountIndex].name,
          balance: accounts[accountIndex].balance + transaction.amount,
          bank: accounts[accountIndex].bank,
          accountNumber: accounts[accountIndex].accountNumber,
          icon: accounts[accountIndex].icon,
        );
      } else {
        accounts[accountIndex] = Account(
          id: accounts[accountIndex].id,
          name: accounts[accountIndex].name,
          balance: accounts[accountIndex].balance - transaction.amount,
          bank: accounts[accountIndex].bank,
          accountNumber: accounts[accountIndex].accountNumber,
          icon: accounts[accountIndex].icon,
        );
      }

      // Save updated accounts
      await saveAccounts(accounts);
    }

    // Add the transaction
    transactions.add(transaction);
    await saveTransactions(transactions);
  }

  // NEW: Update transaction with account balance adjustment
  static Future<void> updateTransaction(Transaction oldTransaction, Transaction newTransaction) async {
    final transactions = await getTransactions();
    final accounts = await getAccounts();

    // Revert the old transaction's effect
    final oldAccountIndex = accounts.indexWhere((a) => a.name == oldTransaction.account);
    if (oldAccountIndex != -1) {
      if (oldTransaction.type == TransactionType.income) {
        accounts[oldAccountIndex] = Account(
          id: accounts[oldAccountIndex].id,
          name: accounts[oldAccountIndex].name,
          balance: accounts[oldAccountIndex].balance - oldTransaction.amount,
          bank: accounts[oldAccountIndex].bank,
          accountNumber: accounts[oldAccountIndex].accountNumber,
          icon: accounts[oldAccountIndex].icon,
        );
      } else {
        accounts[oldAccountIndex] = Account(
          id: accounts[oldAccountIndex].id,
          name: accounts[oldAccountIndex].name,
          balance: accounts[oldAccountIndex].balance + oldTransaction.amount,
          bank: accounts[oldAccountIndex].bank,
          accountNumber: accounts[oldAccountIndex].accountNumber,
          icon: accounts[oldAccountIndex].icon,
        );
      }
    }

    // Apply the new transaction's effect
    final newAccountIndex = accounts.indexWhere((a) => a.name == newTransaction.account);
    if (newAccountIndex != -1) {
      if (newTransaction.type == TransactionType.income) {
        accounts[newAccountIndex] = Account(
          id: accounts[newAccountIndex].id,
          name: accounts[newAccountIndex].name,
          balance: accounts[newAccountIndex].balance + newTransaction.amount,
          bank: accounts[newAccountIndex].bank,
          accountNumber: accounts[newAccountIndex].accountNumber,
          icon: accounts[newAccountIndex].icon,
        );
      } else {
        accounts[newAccountIndex] = Account(
          id: accounts[newAccountIndex].id,
          name: accounts[newAccountIndex].name,
          balance: accounts[newAccountIndex].balance - newTransaction.amount,
          bank: accounts[newAccountIndex].bank,
          accountNumber: accounts[newAccountIndex].accountNumber,
          icon: accounts[newAccountIndex].icon,
        );
      }
    }

    // Save updated accounts
    await saveAccounts(accounts);

    // Update the transaction
    final index = transactions.indexWhere((t) => t.id == oldTransaction.id);
    if (index != -1) {
      transactions[index] = newTransaction;
      await saveTransactions(transactions);
    }
  }

  // NEW: Delete transaction with account balance adjustment
  static Future<void> deleteTransaction(Transaction transaction) async {
    final transactions = await getTransactions();
    final accounts = await getAccounts();

    // Revert the transaction's effect on account balance
    final accountIndex = accounts.indexWhere((a) => a.name == transaction.account);
    if (accountIndex != -1) {
      if (transaction.type == TransactionType.income) {
        accounts[accountIndex] = Account(
          id: accounts[accountIndex].id,
          name: accounts[accountIndex].name,
          balance: accounts[accountIndex].balance - transaction.amount,
          bank: accounts[accountIndex].bank,
          accountNumber: accounts[accountIndex].accountNumber,
          icon: accounts[accountIndex].icon,
        );
      } else {
        accounts[accountIndex] = Account(
          id: accounts[accountIndex].id,
          name: accounts[accountIndex].name,
          balance: accounts[accountIndex].balance + transaction.amount,
          bank: accounts[accountIndex].bank,
          accountNumber: accounts[accountIndex].accountNumber,
          icon: accounts[accountIndex].icon,
        );
      }

      // Save updated accounts
      await saveAccounts(accounts);
    }

    // Remove the transaction
    transactions.removeWhere((t) => t.id == transaction.id);
    await saveTransactions(transactions);
  }

  static Future<void> saveBudgets(List<Budget> budgets) async {
    final userId = await _getUserId();
    final prefs = await SharedPreferences.getInstance();
    final budgetsJson = budgets.map((b) => b.toJson()).toList();
    await prefs.setString('$_budgetsKey$userId', jsonEncode(budgetsJson));
  }

  static Future<List<Budget>> getBudgets() async {
    final userId = await _getUserId();
    final prefs = await SharedPreferences.getInstance();
    final budgetsJson = prefs.getString('$_budgetsKey$userId');
    if (budgetsJson != null) {
      final List<dynamic> decoded = jsonDecode(budgetsJson);
      return decoded.map((item) => Budget.fromJson(item)).toList();
    }
    return [];
  }

  static Future<void> saveSavingsGoals(List<SavingsGoal> goals) async {
    final userId = await _getUserId();
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = goals.map((g) => g.toJson()).toList();
    await prefs.setString('$_goalsKey$userId', jsonEncode(goalsJson));
  }

  static Future<List<SavingsGoal>> getSavingsGoals() async {
    final userId = await _getUserId();
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getString('$_goalsKey$userId');
    if (goalsJson != null) {
      final List<dynamic> decoded = jsonDecode(goalsJson);
      return decoded.map((item) => SavingsGoal.fromJson(item)).toList();
    }
    return [];
  }

  static Future<void> saveAccounts(List<Account> accounts) async {
    final userId = await _getUserId();
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = accounts.map((a) => a.toJson()).toList();
    await prefs.setString('$_accountsKey$userId', jsonEncode(accountsJson));
  }

  static Future<List<Account>> getAccounts() async {
    final userId = await _getUserId();
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getString('$_accountsKey$userId');
    if (accountsJson != null) {
      final List<dynamic> decoded = jsonDecode(accountsJson);
      return decoded.map((item) => Account.fromJson(item)).toList();
    }
    return [];
  }

  static Future<void> addAccount(Account account) async {
    final accounts = await getAccounts();
    accounts.add(account);
    await saveAccounts(accounts);
  }

  // NEW: Update single account balance
  static Future<void> updateAccountBalance(String accountName, double newBalance) async {
    final accounts = await getAccounts();
    final index = accounts.indexWhere((a) => a.name == accountName);

    if (index != -1) {
      accounts[index] = Account(
        id: accounts[index].id,
        name: accounts[index].name,
        balance: newBalance,
        bank: accounts[index].bank,
        accountNumber: accounts[index].accountNumber,
        icon: accounts[index].icon,
      );
      await saveAccounts(accounts);
    }
  }

  // NEW: Get total balance across all accounts
  static Future<double> getTotalBalance() async {
    final accounts = await getAccounts();
    double total = 0.0;
    for (final account in accounts) {
      total += account.balance;
    }
    return total;
  }

  static Future<void> saveCategories(List<Category> categories) async {
    final userId = await _getUserId();
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = categories.map((c) => c.toJson()).toList();
    await prefs.setString('$_categoriesKey$userId', jsonEncode(categoriesJson));
  }

  static Future<List<Category>> getCategories() async {
    final userId = await _getUserId();
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getString('$_categoriesKey$userId');
    if (categoriesJson != null) {
      final List<dynamic> decoded = jsonDecode(categoriesJson);
      return decoded.map((item) => Category.fromJson(item)).toList();
    }
    return _getDefaultCategories();
  }

  static List<Category> _getDefaultCategories() {
    return [
      // Expense Categories
      Category(id: '1', name: 'Food & Dining', icon: '🍕', color: '#FF6B6B', type: TransactionType.expense, isDefault: true),
      Category(id: '2', name: 'Transportation', icon: '🚗', color: '#4ECDC4', type: TransactionType.expense, isDefault: true),
      Category(id: '3', name: 'Bills & Utilities', icon: '💡', color: '#45B7D1', type: TransactionType.expense, isDefault: true),
      Category(id: '4', name: 'Shopping', icon: '🛍️', color: '#FFA07A', type: TransactionType.expense, isDefault: true),
      Category(id: '5', name: 'Entertainment', icon: '🎬', color: '#DDA15E', type: TransactionType.expense, isDefault: true),
      Category(id: '6', name: 'Healthcare', icon: '🏥', color: '#BC6C25', type: TransactionType.expense, isDefault: true),
      Category(id: '7', name: 'Education', icon: '📚', color: '#606C38', type: TransactionType.expense, isDefault: true),
      Category(id: '8', name: 'Travel', icon: '✈️', color: '#9C89B8', type: TransactionType.expense, isDefault: true),
      Category(id: '9', name: 'Groceries', icon: '🛒', color: '#F2C14E', type: TransactionType.expense, isDefault: true),
      Category(id: '10', name: 'Insurance', icon: '🛡️', color: '#E5989B', type: TransactionType.expense, isDefault: true),
      Category(id: '11', name: 'Subscriptions', icon: '📱', color: '#B5838D', type: TransactionType.expense, isDefault: true),
      Category(id: '12', name: 'Personal Care', icon: '💇', color: '#6D6875', type: TransactionType.expense, isDefault: true),
      Category(id: '13', name: 'Gifts & Donations', icon: '🎁', color: '#E5989B', type: TransactionType.expense, isDefault: true),
      Category(id: '14', name: 'Home Maintenance', icon: '🔧', color: '#B23B3B', type: TransactionType.expense, isDefault: true),
      Category(id: '15', name: 'Other', icon: '📦', color: '#6C757D', type: TransactionType.expense, isDefault: true),

      // Income Categories
      Category(id: '16', name: 'Salary', icon: '💰', color: '#52B788', type: TransactionType.income, isDefault: true),
      Category(id: '17', name: 'Freelance', icon: '💼', color: '#74C69D', type: TransactionType.income, isDefault: true),
      Category(id: '18', name: 'Investment', icon: '📈', color: '#95D5B2', type: TransactionType.income, isDefault: true),
      Category(id: '19', name: 'Business', icon: '🏢', color: '#40916C', type: TransactionType.income, isDefault: true),
      Category(id: '20', name: 'Rental Income', icon: '🏠', color: '#2D6A4F', type: TransactionType.income, isDefault: true),
      Category(id: '21', name: 'Gift', icon: '🎁', color: '#B7E4C7', type: TransactionType.income, isDefault: true),
      Category(id: '22', name: 'Bonus', icon: '✨', color: '#A7C957', type: TransactionType.income, isDefault: true),
      Category(id: '23', name: 'Refund', icon: '↩️', color: '#6B9080', type: TransactionType.income, isDefault: true),
      Category(id: '24', name: 'Other Income', icon: '💵', color: '#52B788', type: TransactionType.income, isDefault: true),
    ];
  }

  // NEW: Delete all user data
  static Future<void> deleteAllUserData() async {
    final userId = await _getUserId();
    final prefs = await SharedPreferences.getInstance();

    // Remove all user-specific data
    await prefs.remove('$_userKey$userId');
    await prefs.remove('$_transactionsKey$userId');
    await prefs.remove('$_budgetsKey$userId');
    await prefs.remove('$_goalsKey$userId');
    await prefs.remove('$_accountsKey$userId');
    await prefs.remove('$_categoriesKey$userId');
  }
}