import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  NotificationService(this.userId);

  // Get all notifications stream
  Stream<List<NotificationModel>> getNotifications() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Add notification
  Future<void> addNotification(NotificationModel notification) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add(notification.toMap());
  }

  // Mark as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  // Delete all read notifications
  Future<void> deleteAllRead() async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: true)
        .get();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Create budget warning notification
  Future<void> createBudgetWarning({
    required String category,
    required double spent,
    required double limit,
    required int threshold,
    required String budgetId,
  }) async {
    final notification = NotificationModel(
      title: '⚠️ Budget Alert: $category',
      message:
          'You\'ve spent ${(spent / limit * 100).toStringAsFixed(0)}% of your $category budget. Current: \$${spent.toStringAsFixed(2)} / \$${limit.toStringAsFixed(2)}',
      type: NotificationType.budgetWarning,
      relatedId: budgetId,
      relatedScreen: 'budget',
    );
    await addNotification(notification);
  }

  // Create budget exceeded notification
  Future<void> createBudgetExceeded({
    required String category,
    required double spent,
    required double limit,
    required String budgetId,
  }) async {
    final notification = NotificationModel(
      title: '🚨 Budget Exceeded: $category',
      message:
          'You\'ve exceeded your $category budget! Spent: \$${spent.toStringAsFixed(2)} / Limit: \$${limit.toStringAsFixed(2)}',
      type: NotificationType.budgetExceeded,
      relatedId: budgetId,
      relatedScreen: 'budget',
    );
    await addNotification(notification);
  }

  // Create goal completed notification
  Future<void> createGoalCompleted({
    required String goalName,
    required double targetAmount,
    required String goalId,
  }) async {
    final notification = NotificationModel(
      title: '🎉 Goal Achieved!',
      message:
          'Congratulations! You\'ve completed your goal "$goalName" (\$${targetAmount.toStringAsFixed(2)})',
      type: NotificationType.goalCompleted,
      relatedId: goalId,
      relatedScreen: 'goals',
    );
    await addNotification(notification);
  }

  // Create goal near target notification
  Future<void> createGoalNearTarget({
    required String goalName,
    required double currentAmount,
    required double targetAmount,
    required String goalId,
  }) async {
    final notification = NotificationModel(
      title: '🎯 Almost There!',
      message:
          'You\'re ${(currentAmount / targetAmount * 100).toStringAsFixed(0)}% towards your "$goalName" goal. Keep it up!',
      type: NotificationType.goalNearTarget,
      relatedId: goalId,
      relatedScreen: 'goals',
    );
    await addNotification(notification);
  }
}
