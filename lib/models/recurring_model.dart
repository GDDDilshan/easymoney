import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _toDateTime(dynamic value) {
  if (value == null) {
    return DateTime.now();
  }

  // If it's already a DateTime, return it
  if (value is DateTime) {
    return value;
  }

  // If it's a Timestamp, convert to DateTime
  if (value is Timestamp) {
    return value.toDate();
  }

  // Fallback
  return DateTime.now();
}

class RecurringModel {
  final String? id;
  final double amount;
  final String type;
  final String category;
  final String description;
  final String frequency;
  final DateTime nextDueDate;
  final bool isActive;
  final String currency;
  final DateTime createdAt;

  RecurringModel({
    this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.frequency,
    required this.nextDueDate,
    this.isActive = true,
    this.currency = 'USD',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'type': type,
      'category': category,
      'description': description,
      'frequency': frequency,
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      'isActive': isActive,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory RecurringModel.fromMap(Map<String, dynamic> map, String id) {
    return RecurringModel(
      id: id,
      amount: (map['amount'] ?? 0).toDouble(),
      type: map['type'] ?? 'expense',
      category: map['category'] ?? 'Other',
      description: map['description'] ?? '',
      frequency: map['frequency'] ?? 'monthly',
      nextDueDate: _toDateTime(map['nextDueDate']),
      isActive: map['isActive'] ?? true,
      currency: map['currency'] ?? 'USD',
      createdAt: _toDateTime(map['createdAt']),
    );
  }
}
