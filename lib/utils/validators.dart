class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }

    final phoneRegex = RegExp(r'^[0-9]{10}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid 10-digit phone number';
    }

    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid number';
    }

    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }

    if (amount > 10000000) { // 1 Crore limit
      return 'Amount exceeds maximum limit';
    }

    return null;
  }

  static String? validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a category';
    }

    return null;
  }

  static String? validateAccount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select an account';
    }

    return null;
  }

  static String? validateBudgetLimit(String? value) {
    if (value == null || value.isEmpty) {
      return 'Budget limit is required';
    }

    final limit = double.tryParse(value);
    if (limit == null) {
      return 'Please enter a valid number';
    }

    if (limit <= 0) {
      return 'Budget limit must be greater than 0';
    }

    if (limit > 1000000) { // 10 Lakh limit
      return 'Budget limit exceeds maximum';
    }

    return null;
  }

  static String? validateGoalTarget(String? value) {
    if (value == null || value.isEmpty) {
      return 'Goal target is required';
    }

    final target = double.tryParse(value);
    if (target == null) {
      return 'Please enter a valid number';
    }

    if (target <= 0) {
      return 'Goal target must be greater than 0';
    }

    return null;
  }

  static String? validateDate(DateTime? date) {
    if (date == null) {
      return 'Please select a date';
    }

    if (date.isAfter(DateTime.now())) {
      return 'Date cannot be in the future';
    }

    return null;
  }

  static String? validateFutureDate(DateTime? date) {
    if (date == null) {
      return 'Please select a date';
    }

    if (date.isBefore(DateTime.now())) {
      return 'Date must be in the future';
    }

    return null;
  }

  static String? validateNote(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Note is optional
    }

    if (value.length > 200) {
      return 'Note cannot exceed 200 characters';
    }

    return null;
  }

  static bool isValidAmount(String value) {
    final amount = double.tryParse(value);
    return amount != null && amount > 0;
  }

  static bool isValidPercentage(double value) {
    return value >= 0 && value <= 100;
  }

  static String? validateSearchQuery(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.length < 2) {
      return 'Search query must be at least 2 characters';
    }

    return null;
  }

  static String formatAmount(double amount) {
    if (amount >= 10000000) { // Crore
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) { // Lakh
      return '${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) { // Thousand
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}