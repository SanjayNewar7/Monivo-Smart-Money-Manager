import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  static const String _usersKey = 'registered_users';
  static const String _currentUserPhoneKey = 'current_user_phone';
  static const String _userPasswordsKey = 'user_passwords';

  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Hash security answer
  String _hashAnswer(String answer) {
    final bytes = utf8.encode(answer.toLowerCase().trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Set user as logged in (used after onboarding)
  Future<void> setLoggedIn(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserPhoneKey, phone);
  }

  // Register a new user with password and security question
  Future<bool> registerUser(
      String phone,
      String password,
      String securityQuestion,
      String securityAnswer
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing users map or create new
      Map<String, dynamic> userData = {};
      final String? storedUsers = prefs.getString(_usersKey);

      if (storedUsers != null && storedUsers.isNotEmpty) {
        try {
          userData = Map<String, dynamic>.from(jsonDecode(storedUsers));
        } catch (e) {
          print('Error decoding user data: $e');
          userData = {};
        }
      }

      // Check if user exists and already has a password
      if (userData.containsKey(phone)) {
        final existingUser = userData[phone];
        if (existingUser is Map) {
          final existingPassword = existingUser['password'];
          // If user already has a password, don't allow overwriting
          if (existingPassword != null && existingPassword.toString().isNotEmpty) {
            print('User already has a password set');
            return false;
          }
        }
      }

      // Store or update user auth data
      userData[phone] = {
        'password': _hashPassword(password),
        'securityQuestion': securityQuestion,
        'securityAnswer': _hashAnswer(securityAnswer),
      };

      await prefs.setString(_usersKey, jsonEncode(userData));

      // Also ensure the user is marked as logged in
      await setLoggedIn(phone);

      return true;
    } catch (e) {
      print('Error registering user: $e');
      return false;
    }
  }

  // Check if user has password set
  static Future<bool> userHasPassword(String phone) async {
    if (phone.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final String? storedUsers = prefs.getString(_usersKey);

    if (storedUsers == null || storedUsers.isEmpty) return false;

    try {
      final Map<String, dynamic> userData = Map<String, dynamic>.from(jsonDecode(storedUsers));
      if (!userData.containsKey(phone)) return false;

      final userAuth = userData[phone];
      if (userAuth == null) return false;

      // Handle both Map<String, dynamic> and Map<String, String> cases
      if (userAuth is Map) {
        final password = userAuth['password'];
        return password != null && password.toString().isNotEmpty;
      }
      return false;
    } catch (e) {
      print('Error checking user has password: $e');
      return false;
    }
  }

  // Verify user password
  Future<bool> verifyPassword(String phone, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final String? storedUsers = prefs.getString(_usersKey);
      if (storedUsers == null || storedUsers.isEmpty) return false;

      final userData = Map<String, dynamic>.from(jsonDecode(storedUsers));
      if (!userData.containsKey(phone)) return false;

      final userAuth = userData[phone];
      if (userAuth == null) return false;

      // Safely extract password
      String? storedHash;
      if (userAuth is Map) {
        storedHash = userAuth['password']?.toString();
      }

      if (storedHash == null || storedHash.isEmpty) return false;

      return storedHash == _hashPassword(password);
    } catch (e) {
      print('Error verifying password: $e');
      return false;
    }
  }

  // Get security question for password recovery
  Future<String?> getSecurityQuestion(String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final String? storedUsers = prefs.getString(_usersKey);
      if (storedUsers == null || storedUsers.isEmpty) return null;

      final userData = Map<String, dynamic>.from(jsonDecode(storedUsers));
      if (!userData.containsKey(phone)) return null;

      final userAuth = userData[phone];
      if (userAuth == null) return null;

      // Safely extract security question
      if (userAuth is Map) {
        return userAuth['securityQuestion']?.toString();
      }
      return null;
    } catch (e) {
      print('Error getting security question: $e');
      return null;
    }
  }

  // Verify security answer
  Future<bool> verifySecurityAnswer(String phone, String answer) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final String? storedUsers = prefs.getString(_usersKey);
      if (storedUsers == null || storedUsers.isEmpty) return false;

      final userData = Map<String, dynamic>.from(jsonDecode(storedUsers));
      if (!userData.containsKey(phone)) return false;

      final userAuth = userData[phone];
      if (userAuth == null) return false;

      // Safely extract security answer
      String? storedAnswer;
      if (userAuth is Map) {
        storedAnswer = userAuth['securityAnswer']?.toString();
      }

      if (storedAnswer == null || storedAnswer.isEmpty) return false;

      return storedAnswer == _hashAnswer(answer);
    } catch (e) {
      print('Error verifying answer: $e');
      return false;
    }
  }

  // Reset password (after security question verification)
  Future<bool> resetPassword(String phone, String newPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final String? storedUsers = prefs.getString(_usersKey);
      if (storedUsers == null || storedUsers.isEmpty) return false;

      final userData = Map<String, dynamic>.from(jsonDecode(storedUsers));
      if (!userData.containsKey(phone)) return false;

      // Get existing user data
      final existingUser = userData[phone];
      if (existingUser == null) return false;

      // Create updated user data preserving security question and answer
      Map<String, dynamic> updatedUserData;
      if (existingUser is Map) {
        updatedUserData = Map<String, dynamic>.from(existingUser);
      } else {
        updatedUserData = {};
      }

      // Update password only
      updatedUserData['password'] = _hashPassword(newPassword);

      // Ensure security question and answer are preserved
      if (!updatedUserData.containsKey('securityQuestion')) {
        updatedUserData['securityQuestion'] = '';
      }
      if (!updatedUserData.containsKey('securityAnswer')) {
        updatedUserData['securityAnswer'] = '';
      }

      userData[phone] = updatedUserData;

      await prefs.setString(_usersKey, jsonEncode(userData));
      return true;
    } catch (e) {
      print('Error resetting password: $e');
      return false;
    }
  }

  // Change password
  Future<bool> changePassword(String phone, String oldPassword, String newPassword) async {
    try {
      // Verify old password first
      final isValid = await verifyPassword(phone, oldPassword);
      if (!isValid) return false;

      final prefs = await SharedPreferences.getInstance();

      final String? storedUsers = prefs.getString(_usersKey);
      if (storedUsers == null || storedUsers.isEmpty) return false;

      final userData = Map<String, dynamic>.from(jsonDecode(storedUsers));
      if (!userData.containsKey(phone)) return false;

      // Get existing user data
      final existingUser = userData[phone];
      if (existingUser == null) return false;

      // Create updated user data preserving security info
      Map<String, dynamic> updatedUserData;
      if (existingUser is Map) {
        updatedUserData = Map<String, dynamic>.from(existingUser);
      } else {
        updatedUserData = {};
      }

      // Update password
      updatedUserData['password'] = _hashPassword(newPassword);

      userData[phone] = updatedUserData;

      await prefs.setString(_usersKey, jsonEncode(userData));
      return true;
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }

  // Login user
  Future<bool> login(String phone, String password) async {
    final isValid = await verifyPassword(phone, password);

    if (isValid) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserPhoneKey, phone);

      // Update last login time
      final user = await StorageService.getUser(phone);
      if (user != null) {
        final updatedUser = UserProfile(
          id: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          profileImagePath: user.profileImagePath,
          bio: user.bio,
          location: user.location,
          occupation: user.occupation,
          preferredCurrency: user.preferredCurrency,
          theme: user.theme,
          notificationsEnabled: user.notificationsEnabled,
          budgetAlertsEnabled: user.budgetAlertsEnabled,
          dailyRemindersEnabled: user.dailyRemindersEnabled,
          createdAt: user.createdAt,
          lastLogin: DateTime.now(),
          securityQuestion: user.securityQuestion,
          securityAnswer: user.securityAnswer,
        );
        await StorageService.saveUser(updatedUser);
      }
    }

    return isValid;
  }

  // Logout current user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserPhoneKey);
  }

  // Get current logged in user phone
  static Future<String?> getCurrentUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserPhoneKey);
  }

  // Check if any user is logged in
  static Future<bool> isLoggedIn() async {
    final phone = await getCurrentUserPhone();
    return phone != null && phone.isNotEmpty;
  }

  // Check if user exists in the auth system
  static Future<bool> userExists(String phone) async {
    if (phone.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final String? storedUsers = prefs.getString(_usersKey);

    if (storedUsers == null || storedUsers.isEmpty) return false;

    try {
      final Map<String, dynamic> userData = Map<String, dynamic>.from(jsonDecode(storedUsers));
      return userData.containsKey(phone);
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }

  // Get user auth data (for debugging)
  static Future<Map<String, dynamic>?> getUserAuthData(String phone) async {
    if (phone.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final String? storedUsers = prefs.getString(_usersKey);

    if (storedUsers == null || storedUsers.isEmpty) return null;

    try {
      final Map<String, dynamic> userData = Map<String, dynamic>.from(jsonDecode(storedUsers));
      if (!userData.containsKey(phone)) return null;

      final userAuth = userData[phone];
      if (userAuth is Map) {
        return Map<String, dynamic>.from(userAuth);
      }
      return null;
    } catch (e) {
      print('Error getting user auth data: $e');
      return null;
    }
  }

  // Clear all auth data (for testing/debugging)
  static Future<void> clearAllAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usersKey);
    await prefs.remove(_currentUserPhoneKey);
  }
}