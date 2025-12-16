import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String? id;
  final double amount;
  final String type; // 'income' or 'expense'
  final String category;
  final String description;
  final DateTime date;
  final List<String> tags;
  final String currency;
  final DateTime createdAt;

  TransactionModel({
    this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
    this.tags = const [],
    this.currency = 'USD',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'type': type,
      'category': category,
      'description': description,
      'date': Timestamp.fromDate(date),
      'tags': tags,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      amount: (map['amount'] ?? 0).toDouble(),
      type: map['type'] ?? 'expense',
      category: map['category'] ?? 'Other',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      tags: List<String>.from(map['tags'] ?? []),
      currency: map['currency'] ?? 'USD',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  TransactionModel copyWith({
    String? id,
    double? amount,
    String? type,
    String? category,
    String? description,
    DateTime? date,
    List<String>? tags,
    String? currency,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      tags: tags ?? this.tags,
      currency: currency ?? this.currency,
      createdAt: createdAt,
    );
  }
}
