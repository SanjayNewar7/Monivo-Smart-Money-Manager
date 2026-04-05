import 'package:flutter/material.dart';

class UserProfile {
  final String id; // This will be the phone number
  String name;
  String? email;
  String phone; // Phone is required (non-nullable)
  String? profileImagePath;
  String? bio;
  String? location;
  String? occupation;
  Currency preferredCurrency;
  AppTheme theme;
  bool notificationsEnabled;
  bool budgetAlertsEnabled;
  bool dailyRemindersEnabled;
  bool aiAssistantEnabled; // NEW: AI consent field
  DateTime createdAt;
  DateTime? lastLogin;
  String? securityQuestion; // For password recovery
  String? securityAnswer; // Store hashed answer

  UserProfile({
    required this.id,
    required this.name,
    this.email,
    required this.phone,
    this.profileImagePath,
    this.bio,
    this.location,
    this.occupation,
    this.preferredCurrency = Currency.npr,
    this.theme = AppTheme.blue,
    this.notificationsEnabled = true,
    this.budgetAlertsEnabled = true,
    this.dailyRemindersEnabled = true,
    this.aiAssistantEnabled = false, // NEW: Default to false
    DateTime? createdAt,
    this.lastLogin,
    this.securityQuestion,
    this.securityAnswer,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImagePath': profileImagePath,
      'bio': bio,
      'location': location,
      'occupation': occupation,
      'preferredCurrency': preferredCurrency.toString().split('.').last,
      'theme': theme.toString().split('.').last,
      'notificationsEnabled': notificationsEnabled,
      'budgetAlertsEnabled': budgetAlertsEnabled,
      'dailyRemindersEnabled': dailyRemindersEnabled,
      'aiAssistantEnabled': aiAssistantEnabled, // NEW
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'securityQuestion': securityQuestion,
      'securityAnswer': securityAnswer,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'] ?? '',
      profileImagePath: json['profileImagePath'],
      bio: json['bio'],
      location: json['location'],
      occupation: json['occupation'],
      preferredCurrency: Currency.values.firstWhere(
            (e) => e.toString().split('.').last == json['preferredCurrency'],
        orElse: () => Currency.npr,
      ),
      theme: AppTheme.values.firstWhere(
            (e) => e.toString().split('.').last == json['theme'],
        orElse: () => AppTheme.blue,
      ),
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      budgetAlertsEnabled: json['budgetAlertsEnabled'] ?? true,
      dailyRemindersEnabled: json['dailyRemindersEnabled'] ?? true,
      aiAssistantEnabled: json['aiAssistantEnabled'] ?? false, // NEW
      createdAt: DateTime.parse(json['createdAt']),
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      securityQuestion: json['securityQuestion'],
      securityAnswer: json['securityAnswer'],
    );
  }

// Helper method to check if profile is complete for logout
  bool get isProfileCompleteForLogout {
    return phone.isNotEmpty &&
        phone.length == 10 &&
        securityQuestion != null &&
        securityAnswer != null &&
        securityQuestion!.isNotEmpty &&
        securityAnswer!.isNotEmpty;
  }

// Helper method to get display phone (formatted)
  String get formattedPhone {
    if (phone.length == 10) {
      return '${phone.substring(0, 3)}-${phone.substring(3, 6)}-${phone.substring(6)}';
    }
    return phone;
  }

// Helper method to mask phone for display
  String get maskedPhone {
    if (phone.length == 10) {
      return '${phone.substring(0, 2)}****${phone.substring(6)}';
    }
    return '****' + phone.substring(phone.length - 4);
  }

// Create a copy of UserProfile with updated fields
  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? profileImagePath,
    String? bio,
    String? location,
    String? occupation,
    Currency? preferredCurrency,
    AppTheme? theme,
    bool? notificationsEnabled,
    bool? budgetAlertsEnabled,
    bool? dailyRemindersEnabled,
    bool? aiAssistantEnabled, // NEW
    DateTime? lastLogin,
    String? securityQuestion,
    String? securityAnswer,
  }) {
    return UserProfile(
      id: this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      occupation: occupation ?? this.occupation,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      dailyRemindersEnabled: dailyRemindersEnabled ?? this.dailyRemindersEnabled,
      aiAssistantEnabled: aiAssistantEnabled ?? this.aiAssistantEnabled, // NEW
      createdAt: this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      securityQuestion: securityQuestion ?? this.securityQuestion,
      securityAnswer: securityAnswer ?? this.securityAnswer,
    );
  }
}

// Rest of your enums remain the same...
enum Currency {
  npr('रू', 'NPR', 'Nepal', '🇳🇵'),
  inr('₹', 'INR', 'India', '🇮🇳'),
  usd('\$', 'USD', 'United States', '🇺🇸'),
  eur('€', 'EUR', 'Europe', '🇪🇺'),
  gbp('£', 'GBP', 'United Kingdom', '🇬🇧'),
  jpy('¥', 'JPY', 'Japan', '🇯🇵'),
  cad('C\$', 'CAD', 'Canada', '🇨🇦'),
  aud('A\$', 'AUD', 'Australia', '🇦🇺'),
  chf('Fr', 'CHF', 'Switzerland', '🇨🇭'),
  cny('¥', 'CNY', 'China', '🇨🇳'),
  krw('₩', 'KRW', 'South Korea', '🇰🇷'),
  kpw('₩', 'KPW', 'North Korea', '🇰🇵'),
  bdt('৳', 'BDT', 'Bangladesh', '🇧🇩'),
  btn('Nu.', 'BTN', 'Bhutan', '🇧🇹'),
  lkr('රු', 'LKR', 'Sri Lanka', '🇱🇰'),
  mvr('Rf', 'MVR', 'Maldives', '🇲🇻'),
  aed('د.إ', 'AED', 'UAE', '🇦🇪'),
  qar('ر.ق', 'QAR', 'Qatar', '🇶🇦'),
  pkr('₨', 'PKR', 'Pakistan', '🇵🇰');

  const Currency(this.symbol, this.code, this.country, this.flag);
  final String symbol;
  final String code;
  final String country;
  final String flag;
}

enum AppTheme {
  blue('Blue', Color(0xFF007AFF)),
  green('Green', Color(0xFF34C759)),
  purple('Purple', Color(0xFFAF52DE)),
  dark('Dark', Color(0xFF1C1C1E));

  const AppTheme(this.displayName, this.primaryColor);
  final String displayName;
  final Color primaryColor;
}