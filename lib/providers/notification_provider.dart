import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

class NotificationProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  NotificationService? _notificationService;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.length;
  bool get hasUnread => _notifications.isNotEmpty;
  bool get isLoading => _isLoading;

  NotificationProvider() {
    _initService();
  }

  void _initService() {
    final userId = _authService.currentUser?.uid;
    debugPrint('🔧 Initializing NotificationService for user: $userId');

    if (userId != null) {
      _notificationService = NotificationService(userId);
      loadNotifications();
      debugPrint('✅ NotificationService initialized');
    } else {
      debugPrint('❌ No user logged in, NotificationService not initialized');
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
      for (var notification in _notifications) {
        if (notification.id != null) {
          await _notificationService!.deleteNotification(notification.id!);
        }
      }
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
    }
  }

  // ONLY METHOD FOR BUDGET NOTIFICATIONS - NO GOALS
  Future<void> checkAndCreateNotifications({
    required double spent,
    required double limit,
    required String category,
    required int threshold,
    required String budgetId,
    required int budgetMonth,
    required int budgetYear,
  }) async {
    if (_notificationService == null) {
      debugPrint('❌ NotificationService is null');
      return;
    }

    final now = DateTime.now();

    // ONLY create notifications for CURRENT month budgets
    if (budgetMonth != now.month || budgetYear != now.year) {
      debugPrint('⏭️ Skipping notification - Budget is not for current month');
      return;
    }

    final percentage = (spent / limit * 100);

    debugPrint('🔍 Checking budget notifications:');
    debugPrint('   Category: $category');
    debugPrint('   Spent: \$${spent.toStringAsFixed(2)}');
    debugPrint('   Limit: \$${limit.toStringAsFixed(2)}');
    debugPrint('   Percentage: ${percentage.toStringAsFixed(1)}%');
    debugPrint('   Threshold: $threshold%');

    // Check if already exceeded
    if (spent > limit) {
      debugPrint('🚨 BUDGET EXCEEDED! Creating notification...');

      final hasExceededNotif = _notifications.any((n) =>
          n.type == NotificationType.budgetExceeded && n.relatedId == budgetId);

      if (!hasExceededNotif) {
        debugPrint('✅ Creating budget exceeded notification');
        try {
          await _notificationService!.createBudgetExceeded(
            category: category,
            spent: spent,
            limit: limit,
            budgetId: budgetId,
          );
          debugPrint('✅ Budget exceeded notification created successfully');
        } catch (e) {
          debugPrint('❌ Error creating notification: $e');
        }
      } else {
        debugPrint('⚠️ Budget exceeded notification already exists');
      }
    } else if (percentage >= threshold) {
      debugPrint('⚠️ BUDGET WARNING! Creating notification...');

      final hasWarningNotif = _notifications.any((n) =>
          n.type == NotificationType.budgetWarning && n.relatedId == budgetId);

      if (!hasWarningNotif) {
        debugPrint('✅ Creating budget warning notification');
        try {
          await _notificationService!.createBudgetWarning(
            category: category,
            spent: spent,
            limit: limit,
            threshold: threshold,
            budgetId: budgetId,
          );
          debugPrint('✅ Budget warning notification created successfully');
        } catch (e) {
          debugPrint('❌ Error creating notification: $e');
        }
      } else {
        debugPrint('⚠️ Budget warning notification already exists');
      }
    } else {
      debugPrint(
          '✅ Budget is within safe limits (${percentage.toStringAsFixed(1)}%)');
    }
  }
}
