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
        debugPrint('📬 Loaded ${_notifications.length} notifications');
      },
      onError: (error) {
        debugPrint('❌ Error loading notifications: $error');
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
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (_notificationService == null) return;
    try {
      await _notificationService!.markAllAsRead();
    } catch (e) {
      debugPrint('❌ Error marking all as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    if (_notificationService == null) {
      debugPrint('❌ NotificationService is null, cannot delete');
      return;
    }

    debugPrint('🗑️ Provider: Deleting notification $notificationId');

    try {
      await _notificationService!.deleteNotification(notificationId);
      debugPrint('✅ Provider: Notification deleted from Firestore');

      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
      debugPrint(
          '✅ Provider: Local list updated, ${_notifications.length} notifications remaining');
    } catch (e) {
      debugPrint('❌ Provider: Error deleting notification: $e');
      rethrow;
    }
  }

  Future<void> deleteAllNotifications() async {
    if (_notificationService == null) return;

    debugPrint(
        '🗑️ Provider: Deleting all notifications (${_notifications.length} total)');

    try {
      final notificationIds =
          _notifications.where((n) => n.id != null).map((n) => n.id!).toList();

      debugPrint('   Notification IDs to delete: $notificationIds');

      for (var notificationId in notificationIds) {
        await _notificationService!.deleteNotification(notificationId);
      }

      _notifications.clear();
      notifyListeners();
      debugPrint('✅ Provider: All notifications deleted');
    } catch (e) {
      debugPrint('❌ Provider: Error deleting all notifications: $e');
      rethrow;
    }
  }

  // ✅ FIXED: ONLY CREATE NOTIFICATIONS FOR CURRENT MONTH BUDGETS
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

    // ✅ CRITICAL: ONLY create notifications for CURRENT month budgets
    if (budgetMonth != now.month || budgetYear != now.year) {
      debugPrint('⏭️ Skipping notification - Budget is NOT for current month');
      debugPrint('   Budget: ${budgetMonth}/${budgetYear}');
      debugPrint('   Current: ${now.month}/${now.year}');
      return;
    }

    final percentage = (spent / limit * 100);

    debugPrint('🔍 Checking budget notifications for CURRENT MONTH:');
    debugPrint('   Category: $category');
    debugPrint('   Spent: \$${spent.toStringAsFixed(2)}');
    debugPrint('   Limit: \$${limit.toStringAsFixed(2)}');
    debugPrint('   Percentage: ${percentage.toStringAsFixed(1)}%');
    debugPrint('   Threshold: $threshold%');
    debugPrint('   Budget Month: $budgetMonth/$budgetYear ✅ CURRENT MONTH');

    // Check if already exceeded
    if (spent > limit) {
      debugPrint('🚨 BUDGET EXCEEDED! Checking for existing notification...');

      // Check by budgetId AND type to prevent duplicates
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
        debugPrint(
            '⏭️ Budget exceeded notification already exists for this budget');
      }
    } else if (percentage >= threshold) {
      debugPrint('⚠️ BUDGET WARNING! Checking for existing notification...');

      // Check by budgetId AND type to prevent duplicates
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
        debugPrint(
            '⏭️ Budget warning notification already exists for this budget');
      }
    } else {
      debugPrint(
          '✅ Budget is within safe limits (${percentage.toStringAsFixed(1)}%)');
    }
  }
}
