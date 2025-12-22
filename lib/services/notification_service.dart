import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'package:flutter/foundation.dart';

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
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notification.toMap());
      debugPrint('✅ Notification added to Firestore');
    } catch (e) {
      debugPrint('❌ Error adding notification: $e');
      rethrow;
    }
  }

  // Mark as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
      debugPrint('✅ Notification marked as read: $notificationId');
    } catch (e) {
      debugPrint('❌ Error marking as read: $e');
      rethrow;
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    try {
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
      debugPrint('✅ All notifications marked as read');
    } catch (e) {
      debugPrint('❌ Error marking all as read: $e');
      rethrow;
    }
  }

  // Delete notification - FIXED VERSION
  Future<void> deleteNotification(String notificationId) async {
    try {
      debugPrint('🗑️ Attempting to delete notification: $notificationId');
      debugPrint('   User ID: $userId');

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId);

      // Check if document exists first
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        debugPrint('⚠️ Notification document does not exist: $notificationId');
        return;
      }

      // Delete the document
      await docRef.delete();
      debugPrint(
          '✅ Notification deleted successfully from Firestore: $notificationId');
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
      debugPrint('   Notification ID: $notificationId');
      debugPrint('   User ID: $userId');
      rethrow;
    }
  }

  // Delete all read notifications
  Future<void> deleteAllRead() async {
    try {
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
      debugPrint('✅ All read notifications deleted');
    } catch (e) {
      debugPrint('❌ Error deleting all read: $e');
      rethrow;
    }
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
}
