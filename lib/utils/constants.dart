import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'EasyMoney';
  static const String appVersion = '1.0.0';

  // Categories
  static const List<String> expenseCategories = [
    'Food',
    'Rent',
    'Utilities',
    'Entertainment',
    'Transport',
    'Groceries',
    'Health',
    'Education',
    'Other',
  ];

  static const List<String> incomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Gift',
    'Other',
  ];

  // Frequencies
  static const List<String> frequencies = [
    'daily',
    'weekly',
    'monthly',
    'quarterly',
    'annually',
  ];

  // CORRECTED: Currencies with Symbols - All symbols verified and corrected
  static const Map<String, String> currencies = {
    'USD': '\$', // US Dollar
    'EUR': '€', // Euro
    'GBP': '£', // British Pound
    'JPY': '¥', // Japanese Yen (CORRECTED - different from Yuan)
    'CHF': 'Fr', // Swiss Franc
    'CAD': 'C\$', // Canadian Dollar
    'AUD': 'A\$', // Australian Dollar
    'NZD': 'NZ\$', // New Zealand Dollar
    'CNY': '¥', // Chinese Yuan (same symbol as JPY but different context)
    'INR': '₹', // Indian Rupee
    'RUB': '₽', // Russian Ruble
    'MXN': '\$', // Mexican Peso (uses $ like USD)
    'BRL': 'R\$', // Brazilian Real
    'ZAR': 'R', // South African Rand
    'SGD': 'S\$', // Singapore Dollar
    'HKD': 'HK\$', // Hong Kong Dollar
    'SEK': 'kr', // Swedish Krona
    'NOK': 'kr', // Norwegian Krone
    'DKK': 'kr', // Danish Krone
    'NTD': 'NT\$', // New Taiwan Dollar
    'KRW': '₩', // South Korean Won
    'THB': '฿', // Thai Baht
    'MYR': 'RM', // Malaysian Ringgit
    'PHP': '₱', // Philippine Peso
    'VND': '₫', // Vietnamese Dong
    'PKR': '₨', // Pakistani Rupee
    'IDR': 'Rp', // Indonesian Rupiah
    'TRY': '₺', // Turkish Lira
    'AED': 'د.إ', // UAE Dirham
    'SAR': 'ر.س', // Saudi Riyal
  };

  // Category Colors
  static const Map<String, Color> categoryColors = {
    'Food': Color(0xFFF97316),
    'Rent': Color(0xFF3B82F6),
    'Utilities': Color(0xFFEAB308),
    'Entertainment': Color(0xFFA855F7),
    'Transport': Color(0xFF22C55E),
    'Groceries': Color(0xFF10B981),
    'Health': Color(0xFFEF4444),
    'Education': Color(0xFF6366F1),
    'Savings': Color(0xFF14B8A6),
    'Salary': Color(0xFF10B981),
    'Freelance': Color(0xFF06B6D4),
    'Investment': Color(0xFFA855F7),
    'Gift': Color(0xFFEC4899),
    'Other': Color(0xFF6B7280),
  };

  // Goal Colors
  static const List<Color> goalColors = [
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFF97316),
    Color(0xFFEF4444),
    Color(0xFFEC4899),
  ];

  // Default Currency
  static const String defaultCurrency = 'USD';
}
