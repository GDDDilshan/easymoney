import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================
// HELPER: Convert Timestamp or DateTime to DateTime
// ============================================
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

class GoalModel {
  final String? id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String color;
  final DateTime createdAt;

  GoalModel({
    this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    required this.targetDate,
    this.color = '#10B981',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress => (currentAmount / targetAmount * 100).clamp(0, 100);
  bool get isCompleted => currentAmount >= targetAmount;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': Timestamp.fromDate(targetDate),
      'color': color,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map, String id) {
    return GoalModel(
      id: id,
      name: map['name'] ?? '',
      targetAmount: (map['targetAmount'] ?? 0).toDouble(),
      currentAmount: (map['currentAmount'] ?? 0).toDouble(),
      targetDate: _toDateTime(map['targetDate']),
      color: map['color'] ?? '#10B981',
      createdAt: _toDateTime(map['createdAt']),
    );
  }

  GoalModel copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? color,
  }) {
    return GoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      color: color ?? this.color,
      createdAt: createdAt,
    );
  }
}
