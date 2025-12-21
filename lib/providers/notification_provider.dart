import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

class NotificationProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  NotificationService? _notificationService;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount =>
      _notifications.length; // All notifications count as "unread"
  bool get hasUnread => _notifications.isNotEmpty;
  bool get isLoading => _isLoading;

  NotificationProvider() {
    _initService();
  }

  void _initService() {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      _notificationService = NotificationService(userId);
      loadNotifications();
    }
  }

  void loadNotifications() {
    if (_notificationService == null) return;

    _notificationService!.getNotifications().listen(
      (notifications) {
        _notifications = notifications;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error loading notifications: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    if (_notificationService == null) return;
    try {
      await _notificationService!.markAsRead(notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (_notificationService == null) return;
    try {
      await _notificationService!.markAllAsRead();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    if (_notificationService == null) return;
    try {
      await _notificationService!.deleteNotification(notificationId);
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> deleteAllNotifications() async {
    if (_notificationService == null) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (var notification in _notifications) {
        if (notification.id != null) {
          await _notificationService!.deleteNotification(notification.id!);
        }
      }
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
    }
  }

  // Helper method to create notifications - ONLY FOR CURRENT MONTH
  Future<void> checkAndCreateNotifications({
    required double spent,
    required double limit,
    required String category,
    required int threshold,
    required String budgetId,
    required int budgetMonth,
    required int budgetYear,
  }) async {
    if (_notificationService == null) return;

    final now = DateTime.now();

    // ONLY create notifications for CURRENT month budgets
    if (budgetMonth != now.month || budgetYear != now.year) {
      debugPrint('⏭️ Skipping notification - Budget is not for current month');
      return;
    }

    final percentage = (spent / limit * 100);

    // Check if already exceeded
    if (spent > limit) {
      // Check if we already sent this notification
      final hasExceededNotif = _notifications.any((n) =>
          n.type == NotificationType.budgetExceeded && n.relatedId == budgetId);

      if (!hasExceededNotif) {
        await _notificationService!.createBudgetExceeded(
          category: category,
          spent: spent,
          limit: limit,
          budgetId: budgetId,
        );
      }
    } else if (percentage >= threshold) {
      // Check if we already sent this notification
      final hasWarningNotif = _notifications.any((n) =>
          n.type == NotificationType.budgetWarning && n.relatedId == budgetId);

      if (!hasWarningNotif) {
        await _notificationService!.createBudgetWarning(
          category: category,
          spent: spent,
          limit: limit,
          threshold: threshold,
          budgetId: budgetId,
        );
      }
    }
  }

  Future<void> checkGoalNotifications({
    required String goalName,
    required double currentAmount,
    required double targetAmount,
    required String goalId,
    required DateTime targetDate,
  }) async {
    if (_notificationService == null) return;

    // ONLY create notifications for goals with future or current target dates
    if (targetDate.isBefore(DateTime.now())) {
      debugPrint('⏭️ Skipping notification - Goal target date has passed');
      return;
    }

    final percentage = (currentAmount / targetAmount * 100);

    // Goal completed
    if (currentAmount >= targetAmount) {
      final hasCompletedNotif = _notifications.any((n) =>
          n.type == NotificationType.goalCompleted && n.relatedId == goalId);

      if (!hasCompletedNotif) {
        await _notificationService!.createGoalCompleted(
          goalName: goalName,
          targetAmount: targetAmount,
          goalId: goalId,
        );
      }
    } else if (percentage >= 90) {
      // Near target (90%)
      final hasNearTargetNotif = _notifications.any((n) =>
          n.type == NotificationType.goalNearTarget && n.relatedId == goalId);

      if (!hasNearTargetNotif) {
        await _notificationService!.createGoalNearTarget(
          goalName: goalName,
          currentAmount: currentAmount,
          targetAmount: targetAmount,
          goalId: goalId,
        );
      }
    }
  }
}
