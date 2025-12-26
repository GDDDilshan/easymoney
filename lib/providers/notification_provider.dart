import 'package:flutter/material.dart';
import 'dart:async';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/cache_manager_service.dart';

/// ✅ FULLY FIXED NOTIFICATION PROVIDER
/// - Immediate UI updates from cache
/// - Background Firebase sync
/// - No unnecessary reads
class NotificationProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final SmartCacheManager _cacheManager = SmartCacheManager();
  NotificationService? _notificationService;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  StreamSubscription<List<NotificationModel>>? _notificationSubscription;

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
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _initService() {
    final userId = _authService.currentUser?.uid;
    debugPrint('🔧 Initializing NotificationService for user: $userId');

    if (userId != null) {
      _notificationService = NotificationService(userId);
      _loadWithCache();
      debugPrint('✅ NotificationService initialized');
    } else {
      debugPrint('❌ No user logged in, NotificationService not initialized');
    }
  }

  /// 🔥 CACHE-FIRST: Try cache before Firebase
  Future<void> _loadWithCache() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('📦 Notification: Attempting to load from cache...');
      final cachedNotifications = await _cacheManager.getCachedNotifications();

      if (cachedNotifications != null) {
        debugPrint(
            '✅ Notification CACHE HIT: ${cachedNotifications.length} notifications');
        _notifications = cachedNotifications;
        _isLoading = false;
        notifyListeners();

        _syncWithFirebaseInBackground();
        return;
      }

      debugPrint('❌ Notification CACHE MISS: Loading from Firebase...');
      await _loadNotificationsFromFirebase();
    } catch (e) {
      debugPrint('❌ Error in notification cache-first load: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔄 Background sync
  Future<void> _syncWithFirebaseInBackground() async {
    if (_notificationService == null) return;

    try {
      debugPrint('🔄 Notification: Background sync started...');
      final freshNotifications =
          await _notificationService!.getNotifications().first;

      if (!_isSameNotifications(freshNotifications, _notifications)) {
        debugPrint('🔄 Notification: Data changed, updating...');
        _notifications = freshNotifications;
        await _cacheManager.cacheNotifications(freshNotifications);
        notifyListeners();
      } else {
        debugPrint('✅ Notification: Data up-to-date');
      }
    } catch (e) {
      debugPrint('⚠️ Notification background sync error: $e');
    }
  }

  /// Check if notification lists are same
  bool _isSameNotifications(
      List<NotificationModel> list1, List<NotificationModel> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  /// Load notifications from Firestore (stream listener)
  Future<void> _loadNotificationsFromFirebase() async {
    if (_notificationService == null) return;

    _isLoading = true;
    notifyListeners();

    debugPrint('📊 Notification: Loading from Firebase');

    _notificationSubscription?.cancel();
    _notificationSubscription = _notificationService!.getNotifications().listen(
      (notifications) {
        _notifications = notifications;
        _isLoading = false;

        _cacheManager.cacheNotifications(notifications);

        notifyListeners();
        debugPrint('✅ Loaded ${_notifications.length} notifications');
      },
      onError: (error) {
        debugPrint('❌ Error loading notifications: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ============================================
  // 🔥 FIXED NOTIFICATION MANAGEMENT
  // ============================================

  Future<void> markAsRead(String notificationId) async {
    if (_notificationService == null) return;

    try {
      // ✅ STEP 1: Update local state IMMEDIATELY
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final updatedNotification =
            _notifications[index].copyWith(isRead: true);
        _notifications[index] = updatedNotification;
        notifyListeners();

        // ✅ STEP 2: Update cache IMMEDIATELY
        await _cacheManager.updateNotificationInCache(updatedNotification);
        debugPrint('✅ Notification marked as read in UI and cache immediately');

        // ✅ STEP 3: Update Firebase in background (no await)
        _notificationService!.markAsRead(notificationId).then((_) {
          debugPrint('✅ Mark as read synced to Firebase');
        }).catchError((error) {
          debugPrint('❌ Firebase sync error: $error');
        });
      }
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (_notificationService == null) return;

    try {
      // ✅ STEP 1: Update local state IMMEDIATELY
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
      notifyListeners();

      // ✅ STEP 2: Update cache IMMEDIATELY
      for (var notification in _notifications) {
        await _cacheManager.updateNotificationInCache(notification);
      }
      debugPrint(
          '✅ All notifications marked as read in UI and cache immediately');

      // ✅ STEP 3: Update Firebase in background (no await)
      _notificationService!.markAllAsRead().then((_) {
        debugPrint('✅ Mark all as read synced to Firebase');
      }).catchError((error) {
        debugPrint('❌ Firebase sync error: $error');
      });
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
      // ✅ STEP 1: Find notification
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index == -1) return;

      final notificationToDelete = _notifications[index];

      // ✅ STEP 2: Remove from local state IMMEDIATELY
      _notifications.removeAt(index);
      notifyListeners();

      // ✅ STEP 3: Remove from cache IMMEDIATELY
      await _cacheManager.deleteNotificationFromCache(notificationToDelete);
      debugPrint('✅ Notification deleted from UI and cache immediately');

      // ✅ STEP 4: Delete from Firebase in background (no await)
      _notificationService!.deleteNotification(notificationId).then((_) {
        debugPrint('✅ Notification deletion synced to Firebase');
      }).catchError((error) {
        debugPrint('❌ Firebase sync error: $error');
      });
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

      // ✅ STEP 1: Clear local state IMMEDIATELY
      _notifications.clear();
      notifyListeners();

      // ✅ STEP 2: Clear cache IMMEDIATELY
      await _cacheManager.clearNotificationCache();
      debugPrint('✅ All notifications deleted from UI and cache immediately');

      // ✅ STEP 3: Delete from Firebase in background (no await)
      for (var notificationId in notificationIds) {
        _notificationService!.deleteNotification(notificationId);
      }
      debugPrint(
          '✅ Started background deletion of ${notificationIds.length} notifications from Firebase');
    } catch (e) {
      debugPrint('❌ Provider: Error deleting all notifications: $e');
      rethrow;
    }
  }

  // ============================================
  // BATCH NOTIFICATION CHECKING (Unchanged)
  // ============================================

  Future<void> checkBudgetsAndCreateNotifications({
    required Map<String, dynamic> budgetData,
    required Map<String, dynamic> spendingData,
  }) async {
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

    for (final entry in budgetData.entries) {
      final budgetId = entry.key;
      final budget = entry.value;

      if (budget['month'] != now.month || budget['year'] != now.year) {
        continue;
      }

      budgetsChecked++;
      final spent = spendingData[budget['category']] ?? 0;
      final limit = budget['limit'];
      final threshold = budget['threshold'] ?? 80;
      final category = budget['category'];

      final notificationKey = '$budgetId:${budget['month']}:${budget['year']}';

      if (_pendingNotificationKeys.contains(notificationKey)) {
        debugPrint('   ⏭️ Already processed: $category');
        continue;
      }

      final percentage = (spent / limit * 100);

      if (spent > limit) {
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

    _hasCheckedNotificationsThisSession = true;

    debugPrint('✅ BATCH CHECK COMPLETE:');
    debugPrint('   Budgets checked: $budgetsChecked');
    debugPrint('   Warnings created: $warningsCreated');
    debugPrint('   Exceeded created: $exceedersCreated');
    debugPrint('   🔒 Will NOT check again this session');
  }

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

    if (budgetMonth != now.month || budgetYear != now.year) {
      debugPrint('⏭️ Skipping notification - Budget is NOT for current month');
      return;
    }

    final notificationKey = '$budgetId:$budgetMonth:$budgetYear';

    if (_pendingNotificationKeys.contains(notificationKey)) {
      debugPrint('⏭️ Notification already created this session for $category');
      return;
    }

    final percentage = (spent / limit * 100);

    debugPrint('🔍 Checking single budget: $category');
    debugPrint(
        '   Spent: \$${spent.toStringAsFixed(2)} / \$${limit.toStringAsFixed(2)}');
    debugPrint('   Percentage: ${percentage.toStringAsFixed(1)}%');

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

  bool _notificationExists(String budgetId, NotificationType type) {
    return _notifications.any((n) => n.type == type && n.relatedId == budgetId);
  }

  // ============================================
  // SESSION MANAGEMENT
  // ============================================

  void resetSessionChecks() {
    _hasCheckedNotificationsThisSession = false;
    _pendingNotificationKeys.clear();
    debugPrint('🔄 Session checks reset');
  }

  bool get hasCheckedThisSession => _hasCheckedNotificationsThisSession;
}
