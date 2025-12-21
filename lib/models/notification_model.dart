import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  budgetWarning,
  budgetExceeded,
  goalCompleted,
  goalNearTarget,
  recurringDue,
}

class NotificationModel {
  final String? id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedId; // Budget ID, Goal ID, etc.
  final String? relatedScreen; // Screen to navigate to

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
      createdAt: (map['createdAt'] as Timestamp).toDate(),
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
      case 'NotificationType.goalCompleted':
        return NotificationType.goalCompleted;
      case 'NotificationType.goalNearTarget':
        return NotificationType.goalNearTarget;
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
