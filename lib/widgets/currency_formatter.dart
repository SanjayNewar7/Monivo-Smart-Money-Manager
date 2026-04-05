import 'package:intl/intl.dart';
import '../models/user_model.dart';

class CurrencyFormatter {
  // For main balance display - always show full number with proper formatting
  static String format(double amount, Currency currency) {
    final symbol = currency.symbol;

    switch (currency) {
      case Currency.npr:
        return '$symbol ${_formatInternational(amount)}';
      case Currency.inr:
        return '$symbol ${_formatInternational(amount)}';
      case Currency.usd:
        return '$symbol${_formatInternational(amount)}';
      case Currency.eur:
        return '$symbol${_formatInternational(amount)}';
      case Currency.gbp:
        return '$symbol${_formatInternational(amount)}';
      case Currency.jpy:
        return '$symbol${_formatInternational(amount)}';
      case Currency.cad:
        return '$symbol${_formatInternational(amount)}';
      case Currency.aud:
        return '$symbol${_formatInternational(amount)}';
      case Currency.chf:
        return '$symbol${_formatInternational(amount)}';
      case Currency.cny:
        return '$symbol${_formatInternational(amount)}';
      case Currency.krw:
        return '$symbol${_formatInternational(amount)}';
      default:
        return '$symbol${_formatInternational(amount)}';
    }
  }

  // For chips and compact displays - abbreviate large numbers
  static String formatCompact(double amount, Currency currency) {
    final symbol = currency.symbol;

    // Handle large numbers with abbreviations based on currency region
    if (amount >= 10000000) { // 1 Crore or 10 Million
      if (currency == Currency.inr || currency == Currency.npr) {
        return '$symbol ${_formatLargeNumber(amount / 10000000, 'Cr')}';
      } else {
        return '$symbol${_formatLargeNumber(amount / 1000000, 'M')}'; // Million for Western
      }
    } else if (amount >= 100000) { // 1 Lakh or 100 Thousand
      if (currency == Currency.inr || currency == Currency.npr) {
        return '$symbol ${_formatLargeNumber(amount / 100000, 'L')}';
      } else {
        return '$symbol${_formatLargeNumber(amount / 1000, 'K')}'; // Thousand for Western
      }
    } else if (amount >= 1000) {
      if (currency == Currency.inr || currency == Currency.npr) {
        // Don't abbreviate thousands for INR/NPR, use full numbers
        return format(amount, currency);
      } else {
        return '$symbol${_formatLargeNumber(amount / 1000, 'K')}'; // Thousand for Western
      }
    }

    // For smaller numbers, use regular formatting
    return format(amount, currency);
  }

  // Helper method to format large numbers with suffixes (NO DECIMALS)
  static String _formatLargeNumber(double value, String suffix) {
    // Always show whole numbers, no decimals
    return '${value.toStringAsFixed(0)}$suffix';
  }

  // ==================== INTERNATIONAL FORMAT (USD-style) ====================
  // Format: 123,456 (comma every 3 digits, NO decimal points)
  // Used for ALL currencies for consistency
  static String _formatInternational(double amount) {
    // Round to nearest whole number
    int roundedAmount = amount.round();
    return _formatNumberWithCommas(roundedAmount);
  }

  // Helper method to add commas to numbers
  static String _formatNumberWithCommas(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
    );
  }

  // Optional: Method to get formatted number without symbol
  static String formatNumberOnly(double amount, Currency currency) {
    return _formatInternational(amount);
  }
}