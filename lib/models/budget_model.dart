import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String? id;
  final String category;
  final double monthlyLimit;
  final String period;
  final int alertThreshold;
  final int month; // NEW: Month (1-12)
  final int year; // NEW: Year (e.g., 2024, 2025)
  final DateTime createdAt;

  BudgetModel({
    this.id,
    required this.category,
    required this.monthlyLimit,
    this.period = 'monthly',
    this.alertThreshold = 80,
    int? month, // NEW: Optional month parameter
    int? year, // NEW: Optional year parameter
    DateTime? createdAt,
  })  : month = month ?? DateTime.now().month,
        year = year ?? DateTime.now().year,
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'monthlyLimit': monthlyLimit,
      'period': period,
      'alertThreshold': alertThreshold,
      'month': month, // NEW: Save month
      'year': year, // NEW: Save year
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map, String id) {
    return BudgetModel(
      id: id,
      category: map['category'] ?? '',
      monthlyLimit: (map['monthlyLimit'] ?? 0).toDouble(),
      period: map['period'] ?? 'monthly',
      alertThreshold: map['alertThreshold'] ?? 80,
      month: map['month'] ?? DateTime.now().month, // NEW: Load month
      year: map['year'] ?? DateTime.now().year, // NEW: Load year
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // NEW: Helper to check if budget is for current month
  bool get isCurrentMonth {
    final now = DateTime.now();
    return month == now.month && year == now.year;
  }

  // NEW: Helper to check if budget is in the future
  bool get isFutureMonth {
    final now = DateTime.now();
    final budgetDate = DateTime(year, month);
    final currentDate = DateTime(now.year, now.month);
    return budgetDate.isAfter(currentDate);
  }

  // NEW: Helper to check if budget is in the past
  bool get isPastMonth {
    final now = DateTime.now();
    final budgetDate = DateTime(year, month);
    final currentDate = DateTime(now.year, now.month);
    return budgetDate.isBefore(currentDate);
  }

  // NEW: Get formatted month/year string
  String get monthYearString {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[month - 1]} $year';
  }
}
