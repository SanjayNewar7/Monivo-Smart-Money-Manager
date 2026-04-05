import 'dart:io';

import 'package:bluewallet_np/screens/about_screen.dart';
import 'package:bluewallet_np/screens/help_support_screen.dart';
import 'package:bluewallet_np/screens/privacy_policy_screen.dart';
import 'package:bluewallet_np/screens/privacy_security_screen.dart';
import 'package:bluewallet_np/screens/terms_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_colors.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../services/storage_service.dart';
import '../services/category_service.dart';
import '../services/automatic_notification_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../widgets/main_layout.dart';
import '../models/transaction.dart';
import '../models/user_model.dart';
import '../providers/theme_provider.dart';
import '../screens/manage_categories_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserProfile? _user;
  List<Account> _accounts = [];
  bool _notificationsEnabled = true;
  bool _budgetAlerts = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  bool _aiEnabled = true;

  Future<void> _saveAISetting(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_consent', enabled);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = await StorageService.getUser();
    final accounts = await StorageService.getAccounts();
    final prefs = await SharedPreferences.getInstance(); // Add this line

    setState(() {
      _user = user;
      _accounts = accounts;
      _notificationsEnabled = user?.notificationsEnabled ?? true;
      _budgetAlerts = user?.budgetAlertsEnabled ?? true;
      _aiEnabled = prefs.getBool('ai_consent') ?? true; // Add this line
      _isLoading = false;
    });
  }

  // Helper to get secondary color based on primary
  Color _getSecondaryColor(Color primary) {
    if (primary == const Color(0xFF007AFF)) return const Color(0xFF00C1D4);
    if (primary == const Color(0xFF34C759)) return const Color(0xFF74C69D);
    if (primary == const Color(0xFFAF52DE)) return const Color(0xFFD291FF);
    if (primary == const Color(0xFF1C1C1E)) return const Color(0xFF3A3A3C);
    return const Color(0xFF00C1D4);
  }

  // Helper to check if a number string has more than 9 digits
  bool _hasMoreThanNineDigits(String value) {
    final cleanValue = value.replaceAll('.', '').replaceAll('-', '');
    return cleanValue.length > 9;
  }

  Future<void> _saveNotificationSettings() async {
    if (_user == null) return;

    final updatedUser = UserProfile(
      id: _user!.id,
      name: _user!.name,
      email: _user!.email,
      phone: _user!.phone,
      profileImagePath: _user!.profileImagePath,
      preferredCurrency: _user!.preferredCurrency,
      theme: _user!.theme,
      notificationsEnabled: _notificationsEnabled,
      budgetAlertsEnabled: _budgetAlerts,
      dailyRemindersEnabled: _user!.dailyRemindersEnabled,
      createdAt: _user!.createdAt,
      lastLogin: _user!.lastLogin,
      securityQuestion: _user!.securityQuestion,
      securityAnswer: _user!.securityAnswer,
    );

    await StorageService.saveUser(updatedUser);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  // Check if account is secure (has password)
  Future<bool> _isAccountSecure() async {
    if (_user == null) return false;
    return await AuthService.userHasPassword(_user!.id);
  }

  // Modern Logout Dialog with security check
  Future<void> _logout() async {
    final isSecure = await _isAccountSecure();

    if (!isSecure) {
      _showIncompleteProfileWarning();
      return;
    }

    _showLogoutConfirmationDialog();
  }

  // Modern Logout Confirmation Dialog
  void _showLogoutConfirmationDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeProvider.primaryColor,
                      _getSecondaryColor(themeProvider.primaryColor),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Sign out of your account',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
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
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeProvider.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: themeProvider.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Are you sure you want to logout?',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              _showLoadingDialog();
                              await AuthService().logout();
                              if (mounted) {
                                Navigator.pop(context);
                                Navigator.pushReplacementNamed(context, '/login');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeProvider.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 15,
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
    );
  }

  // Modern Incomplete Profile Warning Dialog
  void _showIncompleteProfileWarning() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warning,
                      Color(0xFFFFA07A),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Important!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Account not protected',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
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
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'You haven\'t set up a password yet.',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          _buildWarningItem('All your account data will be permanently deleted'),
                          const SizedBox(height: 8),
                          _buildWarningItem('You will not be able to recover this account'),
                          const SizedBox(height: 8),
                          _buildWarningItem('Create a password first to save your data'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PrivacySecurityScreen(),
                                ),
                              ).then((_) => _loadData());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeProvider.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                            child: const Text('Set Password'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirm Logout'),
                            content: const Text(
                              'Are you absolutely sure? All your data will be lost forever.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                ),
                                child: const Text('Yes, Delete Data'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          _showLoadingDialog();
                          try {
                            await StorageService.deleteAllUserData();
                            await AuthService().logout();
                            if (mounted) {
                              Navigator.pop(context);
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.pop(context);
                              _showErrorSnackBar('Error: ${e.toString()}');
                            }
                          }
                        }
                      },
                      child: const Text(
                        'Proceed anyway (data will be lost)',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Row(
      children: [
        Icon(
          Icons.error_outline,
          size: 16,
          color: AppColors.warning,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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

  // FIXED: Delete Account Dialog with proper state management
  Future<void> _deleteAccount(Account account) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final currency = _user?.preferredCurrency ?? Currency.npr;
    final TextEditingController confirmController = TextEditingController();

    // Use a ValueNotifier for state management
    final ValueNotifier<bool> isConfirmedNotifier = ValueNotifier<bool>(false);
    final ValueNotifier<bool> isDeletingNotifier = ValueNotifier<bool>(false);

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 380, maxHeight: 560),
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
                      // Warning Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFDC2626),
                              Color(0xFFEF4444),
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
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delete Account',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'This action cannot be undone',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Account Preview Card
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.lightGray,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[200]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            themeProvider.primaryColor.withOpacity(0.2),
                                            themeProvider.primaryColor.withOpacity(0.05),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: themeProvider.primaryColor.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.credit_card,
                                        color: themeProvider.primaryColor,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            account.name,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            account.bank,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          Text(
                                            'Balance: ${currency.symbol} ${NumberFormat('#,##,###').format(account.balance)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.success,
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
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.error.withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: AppColors.error,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Permanently delete "${account.name}"',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'All transactions linked to this account will be removed.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.lightGray,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: confirmController.text == "DELETE"
                                        ? AppColors.success.withOpacity(0.5)
                                        : AppColors.error.withOpacity(0.3),
                                  ),
                                ),
                                child: TextFormField(
                                  controller: confirmController,
                                  textAlign: TextAlign.center,
                                  onChanged: (value) {
                                    setState(() {
                                      isConfirmedNotifier.value = value == "DELETE";
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Type "DELETE" to confirm',
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      color: isConfirmedNotifier.value ? AppColors.success : AppColors.error,
                                    ),
                                    floatingLabelStyle: TextStyle(
                                      color: isConfirmedNotifier.value ? AppColors.success : AppColors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    hintText: 'DELETE',
                                    hintStyle: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textLight,
                                    ),
                                    prefixIcon: Icon(
                                      isConfirmedNotifier.value ? Icons.check_circle : Icons.warning,
                                      color: isConfirmedNotifier.value ? AppColors.success : AppColors.error,
                                      size: 18,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(dialogContext),
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
                                    child: ValueListenableBuilder<bool>(
                                      valueListenable: isDeletingNotifier,
                                      builder: (context, isDeleting, child) {
                                        return ElevatedButton(
                                          onPressed: isDeleting || !isConfirmedNotifier.value
                                              ? null
                                              : () async {
                                            isDeletingNotifier.value = true;
                                            setState(() {});

                                            // Show loading indicator
                                            showDialog(
                                              context: dialogContext,
                                              barrierDismissible: false,
                                              builder: (loadingContext) => const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            );

                                            try {
                                              final accounts = await StorageService.getAccounts();
                                              accounts.removeWhere((a) => a.id == account.id);
                                              await StorageService.saveAccounts(accounts);

                                              if (mounted) {
                                                // Close loading dialog
                                                Navigator.pop(dialogContext);
                                                // Close the delete dialog
                                                Navigator.pop(dialogContext);
                                                // Refresh the data
                                                await _loadData();

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
                                                        Expanded(
                                                          child: Text(
                                                            '"${account.name}" deleted successfully!',
                                                            style: const TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    backgroundColor: AppColors.success,
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
                                              if (mounted) {
                                                Navigator.pop(dialogContext);
                                                isDeletingNotifier.value = false;
                                                setState(() {});
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
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isConfirmedNotifier.value ? AppColors.error : Colors.grey,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: isDeleting
                                              ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                              : const Text(
                                            'DELETE',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
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
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==============================
  // ADDITIONAL SETTINGS METHODS
  // ==============================

  void _rateApp() async {
    final Uri playStoreUri = Uri.parse('https://play.google.com/store/apps/details?id=com.sanjaya.monivo');
    try {
      await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showErrorSnackBar('Could not open Play Store');
    }
  }

  void _showTermsDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 380, maxHeight: 600),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
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
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
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
                        Icons.description,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Terms of Service',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('1. Acceptance of Terms'),
                      const SizedBox(height: 8),
                      _buildSectionContent(
                        'By downloading, accessing, or using Monivo ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('2. Description of Service'),
                      const SizedBox(height: 8),
                      _buildSectionContent(
                        'Monivo is a personal finance management application that helps users track expenses, create budgets, set savings goals, and gain insights into their spending habits. The App provides tools for financial organization but does not provide financial advice.',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('3. User Accounts'),
                      const SizedBox(height: 8),
                      _buildSectionContent(
                        'You are responsible for maintaining the confidentiality of your account credentials. You agree to accept responsibility for all activities that occur under your account. You must be at least 13 years old to use this App.',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('4. Data Privacy'),
                      const SizedBox(height: 8),
                      _buildSectionContent(
                        'Your financial data is stored locally on your device. We do not collect or store your financial information on external servers. Please review our Privacy Policy for more information about how we handle your data.',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('5. User Conduct'),
                      const SizedBox(height: 8),
                      _buildSectionContent(
                        'You agree not to: (a) use the App for any illegal purpose; (b) attempt to gain unauthorized access to the App or its systems; (c) interfere with or disrupt the App\'s operation; (d) upload malicious code or content.',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('6. Intellectual Property'),
                      const SizedBox(height: 8),
                      _buildSectionContent(
                        'The App and its original content, features, and functionality are owned by Monivo and are protected by copyright, trademark, and other intellectual property laws.',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('7. Limitation of Liability'),
                      const SizedBox(height: 8),
                      _buildSectionContent(
                        'Monivo shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the App. The App is provided "as is" without warranties of any kind.',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('8. Modifications to Service'),
                      const SizedBox(height: 8),
                      _buildSectionContent(
                        'We reserve the right to modify or discontinue, temporarily or permanently, the App or any features with or without notice. We shall not be liable to you or any third party for any modification, suspension, or discontinuance.',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('9. Governing Law'),
                      const SizedBox(height: 8),
                      _buildSectionContent(
                        'These Terms shall be governed by and construed in accordance with the laws of Nepal, without regard to its conflict of law provisions.',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('10. Contact Information'),
                      const SizedBox(height: 8),
                      _buildSectionContent(
                        'For any questions about these Terms, please contact us at sanjaynewar007@gmail.com.',
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Last Updated: March 24, 2026',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 380, maxHeight: 600),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
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
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
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
                        Icons.privacy_tip,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Privacy Policy',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Information We Collect'),
                      const SizedBox(height: 8),
                      _buildSectionContent(
                        'Monivo collects the following information to provide its services:\n\n'
                            '• Personal Information: Name, phone number, and optional profile information like email, occupation, and location.\n\n'
                            '• Financial Information: Transaction data, budget settings, savings goals, and account balances that you voluntarily enter.\n\n'
                            '• Device Information: Basic device information for app functionality and crash reporting.\n\n'
                            '• Usage Data: Anonymous usage statistics to improve the app experience.',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('How We Use Your Information'),
                      const SizedBox(height: 8),
                      _buildSectionContent(
                        'We use your information to:\n\n'
                            '• Provide and maintain the App\'s core functionality\n'
                            '• Generate personalized spending insights and personality analysis\n'
                            '• Send notifications about budgets, goals, and spending patterns (if enabled)\n'
                            '• Improve and optimize the App based on usage patterns\n'
                            '• Respond to support inquiries and feedback',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Data Storage and Security'),
                      const SizedBox(height: 8),
                      _buildSectionContent(
                        'All your financial data is stored locally on your device using encrypted SharedPreferences. We do not transmit your financial data to external servers. Your password is hashed using SHA-256 before storage. We implement industry-standard security measures to protect your information.',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Third-Party Services'),
                      const SizedBox(height: 8),
                      _buildSectionContent(
                        'Monivo does not share your personal or financial data with third parties. The App may include links to external websites for informational purposes (e.g., financial tips), but these sites have their own privacy policies.',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Your Rights and Choices'),
                      const SizedBox(height: 8),
                      _buildSectionContent(
                        'You have the right to:\n\n'
                            '• Access and export your data\n'
                            '• Correct or update your information\n'
                            '• Delete your account and all associated data\n'
                            '• Opt out of notifications at any time\n'
                            '• Clear local data from the app settings',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Children\'s Privacy'),
                      const SizedBox(height: 8),
                      _buildSectionContent(
                        'Monivo is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Changes to This Policy'),
                      const SizedBox(height: 8),
                      _buildSectionContent(
                        'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy in the app and updating the "Last Updated" date.',
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Contact Us'),
                      const SizedBox(height: 8),
                      _buildSectionContent(
                        'If you have questions about this Privacy Policy, please contact us at sanjaynewar007@gmail.com.',
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Last Updated: March 24, 2026',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
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
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
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
                        Icons.info_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'About Monivo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: themeProvider.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        size: 40,
                        color: themeProvider.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Monivo',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.5',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Your Smart Money Manager',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Monivo helps you take control of your finances by tracking expenses, setting budgets, and achieving savings goals. Simple, secure, and designed for you.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildAboutInfoRow('Developer', 'Sanjaya Rajbhandari'),
                    const SizedBox(height: 8),
                    _buildAboutInfoRow('Email', 'sanjaynewar007@gmail.com'),
                    const SizedBox(height: 8),
                    _buildAboutInfoRow('Website', 'coming soon'),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildAboutInfoRow('Made with', '❤️ in Nepal'),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Text(
      content,
      style: TextStyle(
        fontSize: 13,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
    );
  }

  Widget _buildAboutInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // Themed Permission Dialog
  Future<void> _showPermissionDialog() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    bool? dialogResult;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeProvider.primaryColor,
                      _getSecondaryColor(themeProvider.primaryColor),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enable Notifications',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Stay updated with your finances',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeProvider.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: themeProvider.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: themeProvider.primaryColor,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Monivo needs notification permission to:',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildPermissionItem(
                            icon: Icons.track_changes,
                            text: 'Alert you when nearing budget limits',
                            color: themeProvider.primaryColor,
                          ),
                          const SizedBox(height: 12),
                          _buildPermissionItem(
                            icon: Icons.flag,
                            text: 'Remind you about savings goals',
                            color: themeProvider.primaryColor,
                          ),
                          const SizedBox(height: 12),
                          _buildPermissionItem(
                            icon: Icons.lightbulb,
                            text: 'Send personalized spending insights',
                            color: themeProvider.primaryColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Not Now',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeProvider.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Allow',
                              style: TextStyle(
                                fontSize: 15,
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
    ).then((value) => dialogResult = value);

    if (dialogResult == true) {
      _showLoadingDialog();
      final granted = await NotificationService().requestPermissions();
      if (mounted) Navigator.pop(context);

      if (granted) {
        final user = await StorageService.getUser();
        final transactions = await StorageService.getTransactions();
        final budgets = await StorageService.getBudgets();
        final goals = await StorageService.getSavingsGoals();
        if (user != null) {
          await AutomaticNotificationService().scheduleAllNotifications(
            user: user,
            transactions: transactions,
            budgets: budgets,
            goals: goals,
          );
        }
        if (mounted) {
          _showSuccessSnackBar('Notifications enabled successfully!');
        }
      } else {
        if (mounted) {
          _showPermissionInstructions();
        }
      }
    }
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  void _showPermissionInstructions() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warning,
                      Color(0xFFFFA07A),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.notifications_off,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Permission Required',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Enable notifications in settings',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'To receive notifications, please enable them in your device settings:',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          _buildInstructionStep('1', 'Open Settings app'),
                          const SizedBox(height: 12),
                          _buildInstructionStep('2', 'Tap on "Apps" or "App Management"'),
                          const SizedBox(height: 12),
                          _buildInstructionStep('3', 'Find and tap on "Monivo"'),
                          const SizedBox(height: 12),
                          _buildInstructionStep('4', 'Tap on "Notifications"'),
                          const SizedBox(height: 12),
                          _buildInstructionStep('5', 'Enable "Allow notifications"'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Got it',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showAIConsentDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeProvider.primaryColor,
                      _getSecondaryColor(themeProvider.primaryColor),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enable AI Assistant',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Personalized financial insights',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeProvider.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: themeProvider.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: themeProvider.primaryColor,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Monivo AI uses Google Gemini to provide:',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildPermissionItem(
                            icon: Icons.insights,
                            text: 'Personalized spending insights',
                            color: themeProvider.primaryColor,
                          ),
                          const SizedBox(height: 12),
                          _buildPermissionItem(
                            icon: Icons.savings,
                            text: 'Smart savings recommendations',
                            color: themeProvider.primaryColor,
                          ),
                          const SizedBox(height: 12),
                          _buildPermissionItem(
                            icon: Icons.auto_awesome,
                            text: 'Budget optimization tips',
                            color: themeProvider.primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.shield_outlined, size: 18, color: Colors.amber.shade700),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Your data stays private & is never stored permanently',
                                    style: TextStyle(fontSize: 11, color: Colors.amber),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Not Now',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('ai_consent', true);
                              setState(() => _aiEnabled = true);
                              Navigator.pop(context);

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
                                          'AI Assistant enabled!',
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
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeProvider.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Enable',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Learn more about AI features',
                        style: TextStyle(
                          fontSize: 12,
                          color: themeProvider.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String step, String instruction) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.warning,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            instruction,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // Improved Add Account Dialog with balance limit
  Future<void> _addAccount() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final TextEditingController nameController = TextEditingController();
    final TextEditingController bankController = TextEditingController();
    final TextEditingController balanceController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
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
                      borderRadius: const BorderRadius.only(
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
                            Icons.credit_card,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Add New Account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Account Name',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: nameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter account name';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'e.g., Main Account',
                                prefixIcon: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.account_balance_wallet_outlined,
                                    color: themeProvider.primaryColor,
                                    size: 18,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppColors.lightGray,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: themeProvider.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.error,
                                    width: 1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Bank Name',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: bankController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter bank name';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'e.g., Sanima Bank',
                                prefixIcon: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.business_outlined,
                                    color: themeProvider.primaryColor,
                                    size: 18,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppColors.lightGray,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: themeProvider.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.error,
                                    width: 1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Initial Balance',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: balanceController,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter initial balance';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                final balance = double.parse(value);
                                if (balance < 0) {
                                  return 'Balance cannot be negative';
                                }
                                if (_hasMoreThanNineDigits(value)) {
                                  return 'Please be realistic and add your actual balance (max 999,999,999)';
                                }
                                if (balance > 999999999) {
                                  return 'Please be realistic and add your actual balance (max 999,999,999)';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: '0.00',
                                helperText: 'Maximum 9 digits (up to 999,999,999)',
                                helperStyle: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                                prefixIcon: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    _user?.preferredCurrency.symbol ?? '₹',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: themeProvider.primaryColor,
                                    ),
                                  ),
                                ),
                                filled: true,
                                fillColor: AppColors.lightGray,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: themeProvider.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.error,
                                    width: 1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.textSecondary,
                                      side: BorderSide(color: Colors.grey[300]!),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (_formKey.currentState!.validate()) {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) => const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );

                                        try {
                                          final account = Account(
                                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                                            name: nameController.text.trim(),
                                            bank: bankController.text.trim(),
                                            balance: double.tryParse(balanceController.text) ?? 0,
                                          );

                                          final accounts = await StorageService.getAccounts();
                                          accounts.add(account);
                                          await StorageService.saveAccounts(accounts);

                                          if (mounted) Navigator.pop(context);
                                          if (mounted) Navigator.pop(context);
                                          await _loadData();

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
                                                        'Account added successfully!',
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
                                          if (mounted) Navigator.pop(context);
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
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: themeProvider.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Add Account',
                                      style: TextStyle(
                                        fontSize: 15,
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

  // Improved Edit Account Dialog with balance limit
  Future<void> _editAccount(Account account) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final TextEditingController nameController = TextEditingController(text: account.name);
    final TextEditingController bankController = TextEditingController(text: account.bank);
    final TextEditingController balanceController = TextEditingController(text: account.balance.toString());
    final _formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
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
                      borderRadius: const BorderRadius.only(
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
                            Icons.edit,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Edit Account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Account Name',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: nameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter account name';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'e.g., Main Account',
                                prefixIcon: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.account_balance_wallet_outlined,
                                    color: themeProvider.primaryColor,
                                    size: 18,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppColors.lightGray,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: themeProvider.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.error,
                                    width: 1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Bank Name',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: bankController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter bank name';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'e.g., Sanima Bank',
                                prefixIcon: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.business_outlined,
                                    color: themeProvider.primaryColor,
                                    size: 18,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppColors.lightGray,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: themeProvider.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.error,
                                    width: 1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Balance',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: balanceController,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter balance';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                final balance = double.parse(value);
                                if (balance < 0) {
                                  return 'Balance cannot be negative';
                                }
                                if (_hasMoreThanNineDigits(value)) {
                                  return 'Please be realistic and add your actual balance (max 999,999,999)';
                                }
                                if (balance > 999999999) {
                                  return 'Please be realistic and add your actual balance (max 999,999,999)';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: '0.00',
                                helperText: 'Maximum 9 digits (up to 999,999,999)',
                                helperStyle: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                                prefixIcon: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    _user?.preferredCurrency.symbol ?? '₹',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: themeProvider.primaryColor,
                                    ),
                                  ),
                                ),
                                filled: true,
                                fillColor: AppColors.lightGray,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: themeProvider.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.error,
                                    width: 1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.textSecondary,
                                      side: BorderSide(color: Colors.grey[300]!),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (_formKey.currentState!.validate()) {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) => const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );

                                        try {
                                          final updatedAccount = Account(
                                            id: account.id,
                                            name: nameController.text.trim(),
                                            bank: bankController.text.trim(),
                                            balance: double.tryParse(balanceController.text) ?? account.balance,
                                          );

                                          final accounts = await StorageService.getAccounts();
                                          final index = accounts.indexWhere((a) => a.id == account.id);
                                          if (index != -1) {
                                            accounts[index] = updatedAccount;
                                            await StorageService.saveAccounts(accounts);
                                          }

                                          if (mounted) Navigator.pop(context);
                                          if (mounted) Navigator.pop(context);
                                          await _loadData();

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
                                                        'Account updated successfully!',
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
                                          if (mounted) Navigator.pop(context);
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
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: themeProvider.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        fontSize: 15,
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

  void _showThemePicker() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.6,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themeProvider.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.palette,
                          color: themeProvider.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Select Theme',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: AppTheme.values.length,
                      itemBuilder: (context, index) {
                        final theme = AppTheme.values[index];
                        final isSelected = _user?.theme == theme;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.primaryColor.withOpacity(0.05) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.palette,
                                  color: theme.primaryColor,
                                  size: 24,
                                ),
                              ),
                            ),
                            title: Text(
                              theme.displayName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            trailing: isSelected
                                ? Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              ),
                            )
                                : null,
                            onTap: () async {
                              if (_user != null) {
                                final updatedUser = UserProfile(
                                  id: _user!.id,
                                  name: _user!.name,
                                  email: _user!.email,
                                  phone: _user!.phone,
                                  profileImagePath: _user!.profileImagePath,
                                  bio: _user!.bio,
                                  location: _user!.location,
                                  occupation: _user!.occupation,
                                  preferredCurrency: _user!.preferredCurrency,
                                  theme: theme,
                                  notificationsEnabled: _user!.notificationsEnabled,
                                  budgetAlertsEnabled: _user!.budgetAlertsEnabled,
                                  dailyRemindersEnabled: _user!.dailyRemindersEnabled,
                                  createdAt: _user!.createdAt,
                                  lastLogin: _user!.lastLogin,
                                  securityQuestion: _user!.securityQuestion,
                                  securityAnswer: _user!.securityAnswer,
                                );

                                await StorageService.saveUser(updatedUser);
                                Provider.of<ThemeProvider>(context, listen: false).setTheme(theme);

                                if (mounted) {
                                  Navigator.pop(context);
                                  _loadData();
                                }
                              }
                            },
                          ),
                        );
                      },
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

  // UNIFIED CURRENCY ICON HELPER
  IconData _getCurrencyIcon(Currency currency) {
    switch (currency) {
      case Currency.npr:
        return TablerIcons.currency_rupee_nepalese;
      case Currency.inr:
        return Icons.currency_rupee;
      case Currency.bdt:
        return Icons.currency_rupee;
      case Currency.lkr:
        return Icons.currency_rupee;
      case Currency.pkr:
        return Icons.currency_rupee;
      case Currency.usd:
      case Currency.cad:
      case Currency.aud:
        return Icons.attach_money;
      case Currency.eur:
        return Icons.euro;
      case Currency.gbp:
        return Icons.currency_pound;
      case Currency.jpy:
      case Currency.cny:
      case Currency.krw:
      case Currency.kpw:
        return Icons.currency_yen;
      case Currency.chf:
        return Icons.account_balance;
      case Currency.btn:
        return Icons.temple_buddhist;
      case Currency.mvr:
        return Icons.beach_access;
      case Currency.aed:
      case Currency.qar:
        return Icons.mosque;
      default:
        return Icons.attach_money;
    }
  }

  void _showCurrencyPicker() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themeProvider.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCurrencyIcon(_user?.preferredCurrency ?? Currency.npr),
                          color: themeProvider.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Select Currency',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search currency...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.lightGray,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (query) {},
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: Currency.values.length,
                      itemBuilder: (context, index) {
                        final currency = Currency.values[index];
                        final isSelected = _user?.preferredCurrency == currency;
                        final icon = _getCurrencyIcon(currency);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? themeProvider.primaryColor.withOpacity(0.05) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? themeProvider.primaryColor
                                    : themeProvider.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(
                                  icon,
                                  size: 20,
                                  color: isSelected
                                      ? Colors.white
                                      : themeProvider.primaryColor,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  currency.flag,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  currency.country,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              '${currency.symbol} ${currency.code}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textLight,
                              ),
                            ),
                            trailing: isSelected
                                ? Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: themeProvider.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              ),
                            )
                                : null,
                            onTap: () async {
                              if (_user != null) {
                                final updatedUser = UserProfile(
                                  id: _user!.id,
                                  name: _user!.name,
                                  email: _user!.email,
                                  phone: _user!.phone,
                                  profileImagePath: _user!.profileImagePath,
                                  bio: _user!.bio,
                                  location: _user!.location,
                                  occupation: _user!.occupation,
                                  preferredCurrency: currency,
                                  theme: _user!.theme,
                                  notificationsEnabled: _user!.notificationsEnabled,
                                  budgetAlertsEnabled: _user!.budgetAlertsEnabled,
                                  dailyRemindersEnabled: _user!.dailyRemindersEnabled,
                                  createdAt: _user!.createdAt,
                                  lastLogin: _user!.lastLogin,
                                  securityQuestion: _user!.securityQuestion,
                                  securityAnswer: _user!.securityAnswer,
                                );

                                await StorageService.saveUser(updatedUser);

                                if (mounted) {
                                  Navigator.pop(context);
                                  _loadData();
                                }
                              }
                            },
                          ),
                        );
                      },
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

  @override
  @override
  Widget build(BuildContext context) {
    final currency = _user?.preferredCurrency ?? Currency.npr;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MainLayout(
      currentIndex: 4,
      child: Scaffold(
        backgroundColor: AppColors.lightGray,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _loadData,
          color: themeProvider.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Header with theme gradient
                Container(
                  width: double.infinity,
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
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () async {
                              final result = await Navigator.pushNamed(context, '/profile');
                              if (result == true) {
                                _loadData();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(32),
                                      image: _user?.profileImagePath != null
                                          ? DecorationImage(
                                        image: FileImage(File(_user!.profileImagePath!)),
                                        fit: BoxFit.cover,
                                      )
                                          : null,
                                    ),
                                    child: _user?.profileImagePath == null
                                        ? Icon(
                                      Icons.person,
                                      size: 32,
                                      color: themeProvider.primaryColor,
                                    )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _user?.name ?? 'User',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _user?.email ?? 'Tap to edit profile',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.white70,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Linked Accounts Section
                      _buildSection(
                        title: 'Linked Accounts',
                        icon: Icons.credit_card,
                        themeProvider: themeProvider,
                        children: [
                          ..._accounts
                              .asMap()
                              .entries
                              .map((entry) {
                            final index = entry.key;
                            final account = entry.value;
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: index < _accounts.length - 1
                                    ? Border(
                                  bottom: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: themeProvider.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.credit_card,
                                      size: 24,
                                      color: themeProvider.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          account.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          account.bank,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${currency.symbol} ${NumberFormat('#,##,###').format(account.balance)}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  PopupMenuButton(
                                    icon: Icon(Icons.more_vert, size: 20, color: themeProvider.primaryColor),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 18, color: AppColors.error),
                                            SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(color: AppColors.error)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        await _editAccount(account);
                                        await _loadData();
                                      } else if (value == 'delete') {
                                        await _deleteAccount(account);
                                        await _loadData();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          })
                              .toList(),
                          InkWell(
                            onTap: _addAccount,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add,
                                    size: 20,
                                    color: themeProvider.primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add Account',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: themeProvider.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Preferences Section
                      _buildSection(
                        title: 'Preferences',
                        icon: Icons.settings_outlined,
                        themeProvider: themeProvider,
                        children: [
                          _buildMenuItem(
                            'Currency',
                            _getCurrencyIcon(_user?.preferredCurrency ?? Currency.npr),
                            themeProvider.primaryColor,
                            value: '${_user?.preferredCurrency.flag ?? '🇳🇵'} ${_user?.preferredCurrency.code ?? 'NPR'}',
                            showDivider: true,
                            onTap: _showCurrencyPicker,
                          ),
                          _buildMenuItem(
                            'Theme',
                            Icons.palette,
                            themeProvider.primaryColor,
                            value: _user?.theme.displayName ?? 'Blue',
                            showDivider: true,
                            onTap: _showThemePicker,
                          ),
                          _buildToggleItem(
                            'AI Assistant',
                            'Get personalized financial advice',
                            Icons.chat,
                            themeProvider.primaryColor,
                            _aiEnabled,
                                (value) async {
                              setState(() => _aiEnabled = value);
                              if (value) {
                                final prefs = await SharedPreferences.getInstance();
                                final hasConsented = prefs.getBool('ai_consent') ?? false;
                                if (!hasConsented) {
                                  _showAIConsentDialog();
                                } else {
                                  await prefs.setBool('ai_consent', true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('AI Assistant enabled!'),
                                      backgroundColor: AppColors.success,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } else {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setBool('ai_consent', false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('AI Assistant disabled'),
                                    backgroundColor: AppColors.warning,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            showDivider: false,
                            themeProvider: themeProvider,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Notifications Section
                      _buildSection(
                        title: 'Notifications',
                        icon: Icons.notifications_outlined,
                        themeProvider: themeProvider,
                        children: [
                          _buildToggleItem(
                            'Push Notifications',
                            'Master switch for all automatic insights and reminders',
                            Icons.notifications,
                            themeProvider.primaryColor,
                            _notificationsEnabled,
                                (value) async {
                              setState(() {
                                _notificationsEnabled = value;
                              });
                              if (value) {
                                final hasPermission = await NotificationService().requestPermissions();
                                if (!hasPermission) {
                                  await _showPermissionDialog();
                                  final permissionGranted = await NotificationService().requestPermissions();
                                  if (!permissionGranted) {
                                    setState(() {
                                      _notificationsEnabled = false;
                                    });
                                    await _saveNotificationSettings();
                                    return;
                                  }
                                }
                                final user = await StorageService.getUser();
                                final transactions = await StorageService.getTransactions();
                                final budgets = await StorageService.getBudgets();
                                final goals = await StorageService.getSavingsGoals();
                                if (user != null) {
                                  await AutomaticNotificationService().scheduleAllNotifications(
                                    user: user,
                                    transactions: transactions,
                                    budgets: budgets,
                                    goals: goals,
                                  );
                                }
                              } else {
                                await NotificationService().cancelNotificationsInRange(10000, 19999);
                              }
                              await _saveNotificationSettings();
                            },
                            showDivider: true,
                            themeProvider: themeProvider,
                          ),
                          _buildToggleItem(
                            'Budget Alerts',
                            'Alert when exceeding budget',
                            Icons.notifications_active,
                            themeProvider.primaryColor,
                            _budgetAlerts,
                                (value) {
                              setState(() {
                                _budgetAlerts = value;
                              });
                              _saveNotificationSettings();
                            },
                            showDivider: false,
                            themeProvider: themeProvider,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // General Section
                      _buildSection(
                        title: 'General',
                        icon: Icons.menu,
                        themeProvider: themeProvider,
                        children: [
                          _buildMenuItem(
                            'Manage Categories',
                            Icons.label,
                            themeProvider.primaryColor,
                            showDivider: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ManageCategoriesScreen(),
                                ),
                              );
                            },
                          ),
                          _buildMenuItem(
                            'Privacy & Security',
                            Icons.security,
                            themeProvider.primaryColor,
                            showDivider: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PrivacySecurityScreen(),
                                ),
                              ).then((_) => _loadData());
                            },
                          ),
                          _buildMenuItem(
                            'Help & Support',
                            Icons.help_outline,
                            themeProvider.primaryColor,
                            showDivider: false,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HelpSupportScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // More Info Section
                      _buildSection(
                        title: 'More Info',
                        icon: Icons.info_outline,
                        themeProvider: themeProvider,
                        children: [
                          _buildMenuItem(
                            'Rate Us',
                            Icons.star,
                            Colors.amber,
                            showDivider: true,
                            onTap: _rateApp,
                          ),
                          _buildMenuItem(
                            'Terms of Service',
                            Icons.description,
                            themeProvider.primaryColor,
                            showDivider: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TermsScreen(),
                                ),
                              );
                            },
                          ),
                          _buildMenuItem(
                            'Privacy Policy',
                            Icons.privacy_tip,
                            themeProvider.primaryColor,
                            showDivider: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PrivacyPolicyScreen(),
                                ),
                              );
                            },
                          ),
                          _buildMenuItem(
                            'About',
                            Icons.info_outline,
                            themeProvider.primaryColor,
                            showDivider: false,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AboutScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _logout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeProvider.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Monivo NP v1.0.8',
                          style: TextStyle(
                            fontSize: 12,
                            color: themeProvider.primaryColor.withOpacity(0.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Menu Item Builder
  Widget _buildMenuItem(String title,
      IconData icon,
      Color color, {
        String? value,
        required bool showDivider,
        VoidCallback? onTap,
      }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (value != null)
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: color.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required ThemeProvider themeProvider,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: themeProvider.primaryColor, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggleItem(String title,
      String subtitle,
      IconData icon,
      Color color,
      bool value,
      Function(bool) onChanged, {
        required bool showDivider,
        required ThemeProvider themeProvider,
      }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: themeProvider.primaryColor,
          ),
        ],
      ),
    );
  }
}