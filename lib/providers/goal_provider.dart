import 'package:flutter/material.dart';
import 'dart:async';
import '../models/goal_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/cache_manager_service.dart';

/// ✅ FIXED GOAL PROVIDER
/// - All CRUD → Firebase immediately
/// - Cache loads first if available, syncs in background
/// - If no cache, loads from Firebase
class GoalProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final SmartCacheManager _cacheManager = SmartCacheManager();
  FirestoreService? _firestoreService;
  List<GoalModel> _goals = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<GoalModel>>? _goalSubscription;

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

  /// FIXED: Load cache first, but fallback to Firebase if empty
  Future<void> _loadWithCache() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('📦 Goal: Loading from cache...');
      final cachedGoals = await _cacheManager.getCachedGoals();

      if (cachedGoals != null && cachedGoals.isNotEmpty) {
        debugPrint(
            '✅ Goal CACHE HIT: ${cachedGoals.length} (will sync in background)');
        _goals = cachedGoals;
        _isLoading = false;
        notifyListeners();

        _syncWithFirebaseInBackground();
        return;
      }

      debugPrint('⚠️ Goal cache empty, loading from Firebase...');
      await _loadFromFirebase();
    } catch (e) {
      debugPrint('❌ Error in goal load: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromFirebase() async {
    if (_firestoreService == null) return;

    _isLoading = true;
    notifyListeners();

    debugPrint('🔥 Goal: Loading from Firebase...');

    _goalSubscription?.cancel();
    _goalSubscription = _firestoreService!.getGoals().listen(
      (goals) {
        _goals = goals;
        _isLoading = false;
        _error = null;

        _cacheManager.cacheGoals(goals);

        notifyListeners();
        debugPrint('✅ Loaded ${goals.length} goals from Firebase');
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
        debugPrint('❌ Error loading goals: $error');
      },
    );
  }

  Future<void> _syncWithFirebaseInBackground() async {
    if (_firestoreService == null) return;

    try {
      debugPrint('🔄 Goal: Background sync...');
      final freshGoals = await _firestoreService!.getGoals().first;

      if (!_isSameGoals(freshGoals, _goals)) {
        debugPrint('🔄 Goal: Data changed, updating...');
        _goals = freshGoals;
        await _cacheManager.cacheGoals(freshGoals);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Goal background sync error: $e');
    }
  }

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

  // ============================================
  // CRUD OPERATIONS - Firebase First
  // ============================================

  Future<void> addGoal(GoalModel goal) async {
    if (_firestoreService == null) return;

    try {
      debugPrint('➕ Adding goal to Firebase...');

      // ✅ Save to Firebase FIRST
      await _firestoreService!.addGoal(goal);
      debugPrint('✅ Goal saved to Firebase');

      // ✅ Update local state
      final tempGoal = GoalModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        name: goal.name,
        targetAmount: goal.targetAmount,
        currentAmount: goal.currentAmount,
        targetDate: goal.targetDate,
        color: goal.color,
      );
      _goals.add(tempGoal);
      notifyListeners();

      // ✅ Update cache
      await _cacheManager.addGoalToCache(tempGoal);
      debugPrint('✅ Goal added to UI and cache');

      // Sync to get real ID
      _syncWithFirebaseInBackground();

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
      debugPrint('✏️ Updating goal in Firebase...');

      // ✅ Update Firebase FIRST
      await _firestoreService!.updateGoal(id, goal);
      debugPrint('✅ Goal updated in Firebase');

      // ✅ Update local state
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

        await _cacheManager.updateGoalInCache(updatedGoal);
        debugPrint('✅ Goal updated in UI and cache');
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
      debugPrint('🗑️ Deleting goal from Firebase...');

      final index = _goals.indexWhere((g) => g.id == id);
      if (index == -1) return;

      final goalToDelete = _goals[index];

      // ✅ Delete from Firebase FIRST
      await _firestoreService!.deleteGoal(id);
      debugPrint('✅ Goal deleted from Firebase');

      // ✅ Update local state
      _goals.removeAt(index);
      notifyListeners();

      // ✅ Update cache
      await _cacheManager.deleteGoalFromCache(goalToDelete);
      debugPrint('✅ Goal deleted from UI and cache');

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
      debugPrint('➕ Adding contribution to Firebase...');

      final index = _goals.indexWhere((g) => g.id == id);
      if (index == -1) return;

      final currentGoal = _goals[index];

      // ✅ Update Firebase FIRST
      await _firestoreService!.addGoalContribution(id, amount);
      debugPrint('✅ Contribution saved to Firebase');

      // ✅ Update local state
      final updatedGoal = currentGoal.copyWith(
        currentAmount: currentGoal.currentAmount + amount,
      );
      _goals[index] = updatedGoal;
      notifyListeners();

      // ✅ Update cache
      await _cacheManager.updateGoalInCache(updatedGoal);
      debugPrint('✅ Contribution added to UI and cache');

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
