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

enum NotificationType {
  budgetWarning,
  budgetExceeded,
  recurringDue,
}

class NotificationModel {
  final String? id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedId;
  final String? relatedScreen;

  NotificationModel({
    this.id,
    required this.title,
    required this.message,
    required this.type,
    DateTime? createdAt,
    this.isRead = false,
    this.relatedId,
    this.relatedScreen,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type.toString(),
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'relatedId': relatedId,
      'relatedScreen': relatedScreen,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: _parseNotificationType(map['type']),
      createdAt: _toDateTime(map['createdAt']),
      isRead: map['isRead'] ?? false,
      relatedId: map['relatedId'],
      relatedScreen: map['relatedScreen'],
    );
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'NotificationType.budgetWarning':
        return NotificationType.budgetWarning;
      case 'NotificationType.budgetExceeded':
        return NotificationType.budgetExceeded;
      case 'NotificationType.recurringDue':
        return NotificationType.recurringDue;
      default:
        return NotificationType.budgetWarning;
    }
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId,
      relatedScreen: relatedScreen,
    );
  }
}
