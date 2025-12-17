import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String? id;
  final String category;
  final double monthlyLimit;
  final String period;
  final int alertThreshold;
  final DateTime createdAt;

  BudgetModel({
    this.id,
    required this.category,
    required this.monthlyLimit,
    this.period = 'monthly',
    this.alertThreshold = 80,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'monthlyLimit': monthlyLimit,
      'period': period,
      'alertThreshold': alertThreshold,
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
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
