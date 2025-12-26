import 'package:flutter/material.dart';
import 'dart:async';
import '../models/goal_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/cache_manager_service.dart';

/// ✅ FULLY FIXED GOAL PROVIDER
/// - Immediate UI updates from cache
/// - Background Firebase sync
/// - No unnecessary reads
class GoalProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final SmartCacheManager _cacheManager = SmartCacheManager();
  FirestoreService? _firestoreService;
  List<GoalModel> _goals = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<GoalModel>>? _goalSubscription;

  bool _hasInitialized = false;

  List<GoalModel> get goals => _goals;
  List<GoalModel> get activeGoals =>
      _goals.where((g) => !g.isCompleted).toList();
  List<GoalModel> get completedGoals =>
      _goals.where((g) => g.isCompleted).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  GoalProvider() {
    _initService();
  }

  @override
  void dispose() {
    _goalSubscription?.cancel();
    super.dispose();
  }

  void _initService() {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      _firestoreService = FirestoreService(userId);
      _loadWithCache();
    }
  }

  /// 🔥 CACHE-FIRST: Try cache before Firebase
  Future<void> _loadWithCache() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('📦 Goal: STEP 1 - Attempting to load from cache...');
      final cachedGoals = await _cacheManager.getCachedGoals();

      if (cachedGoals != null) {
        debugPrint('✅ Goal CACHE HIT: ${cachedGoals.length} goals (cached)');
        _goals = cachedGoals;
        _isLoading = false;
        _hasInitialized = true;
        notifyListeners();

        _syncWithFirebaseInBackground();
        return;
      }

      debugPrint('❌ Goal CACHE MISS: Loading from Firebase...');
      await _loadGoalsFromFirebase();
    } catch (e) {
      debugPrint('❌ Error in goal cache-first load: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔄 Background sync for goal changes
  Future<void> _syncWithFirebaseInBackground() async {
    if (_firestoreService == null) return;

    try {
      debugPrint('🔄 Goal: Background sync started...');
      final freshGoals = await _firestoreService!.getGoals().first;

      if (!_isSameGoals(freshGoals, _goals)) {
        debugPrint('🔄 Goal: Data changed, updating...');
        _goals = freshGoals;
        await _cacheManager.cacheGoals(freshGoals);
        notifyListeners();
      } else {
        debugPrint('✅ Goal: Data up-to-date');
      }
    } catch (e) {
      debugPrint('⚠️ Goal background sync error: $e');
    }
  }

  /// Check if goal lists are same
  bool _isSameGoals(List<GoalModel> list1, List<GoalModel> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id ||
          list1[i].currentAmount != list2[i].currentAmount) {
        return false;
      }
    }
    return true;
  }

  /// Load goals from Firebase
  Future<void> _loadGoalsFromFirebase() async {
    if (_firestoreService == null) return;

    _isLoading = true;
    notifyListeners();

    debugPrint('📊 Goal: Loading from Firebase');
    debugPrint('   Reads: ~50-100 (optimized)');

    _goalSubscription?.cancel();
    _goalSubscription = _firestoreService!.getGoals().listen(
      (goals) {
        _goals = goals;
        _isLoading = false;
        _error = null;
        _hasInitialized = true;

        _cacheManager.cacheGoals(goals);

        notifyListeners();
        debugPrint('✅ Loaded ${goals.length} goals');
        debugPrint(
            '   Active: ${activeGoals.length}, Completed: ${completedGoals.length}');
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
        debugPrint('❌ Error loading goals: $error');
      },
    );
  }

  // ============================================
  // 🔥 FIXED CRUD OPERATIONS
  // ============================================

  Future<void> addGoal(GoalModel goal) async {
    if (_firestoreService == null) return;

    try {
      // ✅ STEP 1: Create optimistic goal with temp ID
      final tempGoal = GoalModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        name: goal.name,
        targetAmount: goal.targetAmount,
        currentAmount: goal.currentAmount,
        targetDate: goal.targetDate,
        color: goal.color,
      );

      // ✅ STEP 2: Update local state IMMEDIATELY
      _goals.add(tempGoal);
      notifyListeners();

      // ✅ STEP 3: Update cache IMMEDIATELY
      await _cacheManager.addGoalToCache(tempGoal);
      debugPrint('✅ Goal added to UI and cache immediately');

      // ✅ STEP 4: Save to Firebase in background (no await)
      _firestoreService!.addGoal(goal).then((_) {
        debugPrint('✅ Goal synced to Firebase');
        _syncWithFirebaseInBackground();
      }).catchError((error) {
        debugPrint('❌ Firebase sync error: $error');
      });

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error adding goal: $e');
      rethrow;
    }
  }

  Future<void> updateGoal(String id, GoalModel goal) async {
    if (_firestoreService == null) return;

    try {
      // ✅ STEP 1: Update local state IMMEDIATELY
      final index = _goals.indexWhere((g) => g.id == id);
      if (index != -1) {
        final updatedGoal = GoalModel(
          id: id,
          name: goal.name,
          targetAmount: goal.targetAmount,
          currentAmount: goal.currentAmount,
          targetDate: goal.targetDate,
          color: goal.color,
        );
        _goals[index] = updatedGoal;
        notifyListeners();

        // ✅ STEP 2: Update cache IMMEDIATELY
        await _cacheManager.updateGoalInCache(updatedGoal);
        debugPrint('✅ Goal updated in UI and cache immediately');

        // ✅ STEP 3: Save to Firebase in background (no await)
        _firestoreService!.updateGoal(id, goal).then((_) {
          debugPrint('✅ Goal update synced to Firebase');
        }).catchError((error) {
          debugPrint('❌ Firebase sync error: $error');
        });
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error updating goal: $e');
      rethrow;
    }
  }

  Future<void> deleteGoal(String id) async {
    if (_firestoreService == null) return;

    try {
      // ✅ STEP 1: Get goal before deleting
      final index = _goals.indexWhere((g) => g.id == id);
      if (index == -1) return;

      final goalToDelete = _goals[index];

      // ✅ STEP 2: Remove from local state IMMEDIATELY
      _goals.removeAt(index);
      notifyListeners();

      // ✅ STEP 3: Remove from cache IMMEDIATELY
      await _cacheManager.deleteGoalFromCache(goalToDelete);
      debugPrint('✅ Goal deleted from UI and cache immediately');

      // ✅ STEP 4: Delete from Firebase in background (no await)
      _firestoreService!.deleteGoal(id).then((_) {
        debugPrint('✅ Goal deletion synced to Firebase');
      }).catchError((error) {
        debugPrint('❌ Firebase sync error: $error');
      });

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error deleting goal: $e');
      rethrow;
    }
  }

  Future<void> addContribution(String id, double amount) async {
    if (_firestoreService == null) return;

    try {
      // ✅ STEP 1: Update local state IMMEDIATELY
      final index = _goals.indexWhere((g) => g.id == id);
      if (index != -1) {
        final currentGoal = _goals[index];
        final updatedGoal = currentGoal.copyWith(
          currentAmount: currentGoal.currentAmount + amount,
        );
        _goals[index] = updatedGoal;
        notifyListeners();

        // ✅ STEP 2: Update cache IMMEDIATELY
        await _cacheManager.updateGoalInCache(updatedGoal);
        debugPrint('✅ Contribution added to UI and cache immediately');

        // ✅ STEP 3: Save to Firebase in background (no await)
        _firestoreService!.addGoalContribution(id, amount).then((_) {
          debugPrint('✅ Contribution synced to Firebase');
        }).catchError((error) {
          debugPrint('❌ Firebase sync error: $error');
        });
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error adding contribution: $e');
      rethrow;
    }
  }

  // ============================================
  // QUERY HELPERS
  // ============================================

  int getActiveGoalsCount() => activeGoals.length;
  int getCompletedGoalsCount() => completedGoals.length;
  double getTotalTargetAmount() =>
      _goals.fold(0.0, (sum, g) => sum + g.targetAmount);
  double getTotalCurrentAmount() =>
      _goals.fold(0.0, (sum, g) => sum + g.currentAmount);

  double getTotalProgress() {
    final total = getTotalTargetAmount();
    if (total == 0) return 0;
    return (getTotalCurrentAmount() / total * 100).clamp(0, 100);
  }

  GoalModel? getGoalById(String id) {
    try {
      return _goals.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }
}
