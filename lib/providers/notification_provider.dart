import 'package:flutter/material.dart';
import 'dart:async';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

/// ✅ FULLY OPTIMIZED NOTIFICATION PROVIDER
/// - Batch notification creation (prevents duplicates)
/// - Deduplicated by budgetId + type
/// - Only check ONCE per app session
/// - Smart notification cleanup
class NotificationProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  NotificationService? _notificationService;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  // 🔥 CRITICAL: Only check notifications ONCE per session
  static bool _hasCheckedNotificationsThisSession = false;

  // Track pending notifications to prevent duplicates
  final Set<String> _pendingNotificationKeys = {};

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.length;
  bool get hasUnread => _notifications.isNotEmpty;
  bool get isLoading => _isLoading;

  NotificationProvider() {
    _initService();
  }

  @override
  void dispose() {
    _pendingNotificationKeys.clear();
    super.dispose();
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

  /// Load notifications from Firestore (stream listener)
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

  // ============ NOTIFICATION MANAGEMENT ============

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
          '✅ Provider: Local list updated, ${_notifications.length} remaining');
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

  // ============ BATCH NOTIFICATION CHECKING ============
  // 🔥 CRITICAL: Only run ONCE per app session

  /// Check ALL budgets at once (batch operation)
  /// Only called ONCE when app launches
  Future<void> checkBudgetsAndCreateNotifications({
    required Map<String, dynamic> budgetData,
    required Map<String, dynamic> spendingData,
  }) async {
    // 🔥 ONLY CHECK ONCE PER SESSION
    if (_hasCheckedNotificationsThisSession) {
      debugPrint('⏭️ Notifications already checked this session, skipping...');
      return;
    }

    if (_notificationService == null) {
      debugPrint('❌ NotificationService is null');
      return;
    }

    debugPrint('🔍 BATCH CHECK: Checking all budgets for current month...');
    debugPrint('   Budgets to check: ${budgetData.length}');

    int budgetsChecked = 0;
    int warningsCreated = 0;
    int exceedersCreated = 0;

    final now = DateTime.now();

    // Batch check all budgets
    for (final entry in budgetData.entries) {
      final budgetId = entry.key;
      final budget = entry.value;

      // Only check current month budgets
      if (budget['month'] != now.month || budget['year'] != now.year) {
        continue;
      }

      budgetsChecked++;
      final spent = spendingData[budget['category']] ?? 0;
      final limit = budget['limit'];
      final threshold = budget['threshold'] ?? 80;
      final category = budget['category'];

      // Create deduplication key
      final notificationKey = '$budgetId:${budget['month']}:${budget['year']}';

      // Check if already processed
      if (_pendingNotificationKeys.contains(notificationKey)) {
        debugPrint('   ⏭️ Already processed: $category');
        continue;
      }

      final percentage = (spent / limit * 100);

      if (spent > limit) {
        // Budget exceeded
        if (!_notificationExists(budgetId, NotificationType.budgetExceeded)) {
          debugPrint('   🚨 CREATE: Budget Exceeded - $category');
          try {
            await _notificationService!.createBudgetExceeded(
              category: category,
              spent: spent,
              limit: limit,
              budgetId: budgetId,
            );
            exceedersCreated++;
            _pendingNotificationKeys.add(notificationKey);
          } catch (e) {
            debugPrint('   ❌ Error creating exceeded notification: $e');
          }
        }
      } else if (percentage >= threshold) {
        // Budget warning
        if (!_notificationExists(budgetId, NotificationType.budgetWarning)) {
          debugPrint(
              '   ⚠️ CREATE: Budget Warning - $category (${percentage.toStringAsFixed(0)}%)');
          try {
            await _notificationService!.createBudgetWarning(
              category: category,
              spent: spent,
              limit: limit,
              threshold: threshold,
              budgetId: budgetId,
            );
            warningsCreated++;
            _pendingNotificationKeys.add(notificationKey);
          } catch (e) {
            debugPrint('   ❌ Error creating warning notification: $e');
          }
        }
      }
    }

    // Mark as checked for this session
    _hasCheckedNotificationsThisSession = true;

    debugPrint('✅ BATCH CHECK COMPLETE:');
    debugPrint('   Budgets checked: $budgetsChecked');
    debugPrint('   Warnings created: $warningsCreated');
    debugPrint('   Exceeded created: $exceedersCreated');
    debugPrint('   🔒 Will NOT check again this session');
  }

  /// Check single budget (used after transaction added)
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

    // Only check current month budgets
    if (budgetMonth != now.month || budgetYear != now.year) {
      debugPrint('⏭️ Skipping notification - Budget is NOT for current month');
      return;
    }

    // Create deduplication key
    final notificationKey = '$budgetId:$budgetMonth:$budgetYear';

    // Skip if already processed in this session
    if (_pendingNotificationKeys.contains(notificationKey)) {
      debugPrint('⏭️ Notification already created this session for $category');
      return;
    }

    final percentage = (spent / limit * 100);

    debugPrint('🔍 Checking single budget: $category');
    debugPrint(
        '   Spent: \$${spent.toStringAsFixed(2)} / \$${limit.toStringAsFixed(2)}');
    debugPrint('   Percentage: ${percentage.toStringAsFixed(1)}%');

    // Check if already exceeded
    if (spent > limit) {
      if (!_notificationExists(budgetId, NotificationType.budgetExceeded)) {
        debugPrint('🚨 Creating budget exceeded notification');
        try {
          await _notificationService!.createBudgetExceeded(
            category: category,
            spent: spent,
            limit: limit,
            budgetId: budgetId,
          );
          _pendingNotificationKeys.add(notificationKey);
          debugPrint('✅ Budget exceeded notification created');
        } catch (e) {
          debugPrint('❌ Error creating notification: $e');
        }
      }
    } else if (percentage >= threshold) {
      if (!_notificationExists(budgetId, NotificationType.budgetWarning)) {
        debugPrint('⚠️ Creating budget warning notification');
        try {
          await _notificationService!.createBudgetWarning(
            category: category,
            spent: spent,
            limit: limit,
            threshold: threshold,
            budgetId: budgetId,
          );
          _pendingNotificationKeys.add(notificationKey);
          debugPrint('✅ Budget warning notification created');
        } catch (e) {
          debugPrint('❌ Error creating notification: $e');
        }
      }
    }
  }

  /// Check if notification already exists
  bool _notificationExists(String budgetId, NotificationType type) {
    return _notifications.any((n) => n.type == type && n.relatedId == budgetId);
  }

  // ============ SESSION MANAGEMENT ============

  /// Reset session checks (for testing or debugging)
  void resetSessionChecks() {
    _hasCheckedNotificationsThisSession = false;
    _pendingNotificationKeys.clear();
    debugPrint('🔄 Session checks reset');
  }

  /// Get notification check status
  bool get hasCheckedThisSession => _hasCheckedNotificationsThisSession;
}
