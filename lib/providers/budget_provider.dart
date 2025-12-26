import 'package:flutter/material.dart';
import 'dart:async';
import '../models/budget_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/cache_manager_service.dart';

/// ✅ FULLY FIXED BUDGET PROVIDER
/// - Immediate UI updates from cache
/// - Background Firebase sync
/// - No unnecessary reads
class BudgetProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final SmartCacheManager _cacheManager = SmartCacheManager();
  FirestoreService? _firestoreService;
  List<BudgetModel> _budgets = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<BudgetModel>>? _budgetSubscription;

  bool _hasInitialized = false;

  List<BudgetModel> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BudgetProvider() {
    _initService();
  }

  @override
  void dispose() {
    _budgetSubscription?.cancel();
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
      debugPrint('📦 Budget: STEP 1 - Attempting to load from cache...');
      final cachedBudgets = await _cacheManager.getCachedBudgets();

      if (cachedBudgets != null) {
        final currentMonthBudgets = _filterCurrentMonth(cachedBudgets);
        debugPrint(
            '✅ Budget CACHE HIT: ${currentMonthBudgets.length} this month (cached)');
        _budgets = currentMonthBudgets;
        _isLoading = false;
        _hasInitialized = true;
        notifyListeners();

        _syncWithFirebaseInBackground();
        return;
      }

      debugPrint('❌ Budget CACHE MISS: Loading from Firebase...');
      await _loadCurrentMonthBudgets();
    } catch (e) {
      debugPrint('❌ Error in budget cache-first load: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔄 Background sync for budget changes
  Future<void> _syncWithFirebaseInBackground() async {
    if (_firestoreService == null) return;

    try {
      debugPrint('🔄 Budget: Background sync started...');
      final allBudgets = await _firestoreService!.getBudgets().first;
      final currentMonthBudgets = _filterCurrentMonth(allBudgets);

      if (!_isSameBudgets(currentMonthBudgets, _budgets)) {
        debugPrint('🔄 Budget: Data changed, updating...');
        _budgets = currentMonthBudgets;
        await _cacheManager.cacheBudgets(allBudgets);
        notifyListeners();
      } else {
        debugPrint('✅ Budget: Data up-to-date');
      }
    } catch (e) {
      debugPrint('⚠️ Budget background sync error: $e');
    }
  }

  /// Filter budgets for current month only
  List<BudgetModel> _filterCurrentMonth(List<BudgetModel> allBudgets) {
    final now = DateTime.now();
    return allBudgets
        .where((b) => b.month == now.month && b.year == now.year)
        .toList();
  }

  /// Check if budget lists are same
  bool _isSameBudgets(List<BudgetModel> list1, List<BudgetModel> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id ||
          list1[i].monthlyLimit != list2[i].monthlyLimit) {
        return false;
      }
    }
    return true;
  }

  /// Load current month budgets only
  Future<void> _loadCurrentMonthBudgets() async {
    if (_firestoreService == null) return;

    _isLoading = true;
    notifyListeners();

    final now = DateTime.now();
    debugPrint(
        '📊 Budget: Loading CURRENT MONTH ONLY (${now.month}/${now.year})');
    debugPrint('   Reads: ~50-100 (optimized)');

    _budgetSubscription?.cancel();
    _budgetSubscription = _firestoreService!.getBudgets().listen(
      (allBudgets) {
        final currentMonthBudgets = _filterCurrentMonth(allBudgets);

        _budgets = currentMonthBudgets;
        _isLoading = false;
        _error = null;
        _hasInitialized = true;

        _cacheManager.cacheBudgets(allBudgets);

        notifyListeners();
        debugPrint(
            '✅ Loaded ${currentMonthBudgets.length} budgets (current month only)');
        debugPrint('   Total cached: ${allBudgets.length}');
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
        debugPrint('❌ Error loading budgets: $error');
      },
    );
  }

  // ============================================
  // 🔥 FIXED CRUD OPERATIONS
  // ============================================

  Future<void> addBudget(BudgetModel budget) async {
    if (_firestoreService == null) return;

    try {
      // ✅ STEP 1: Create optimistic budget with temp ID
      final tempBudget = BudgetModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        category: budget.category,
        monthlyLimit: budget.monthlyLimit,
        period: budget.period,
        alertThreshold: budget.alertThreshold,
        month: budget.month,
        year: budget.year,
      );

      // ✅ STEP 2: Update local state IMMEDIATELY
      _budgets.add(tempBudget);
      notifyListeners();

      // ✅ STEP 3: Update cache IMMEDIATELY
      await _cacheManager.addBudgetToCache(tempBudget);
      debugPrint('✅ Budget added to UI and cache immediately');

      // ✅ STEP 4: Save to Firebase in background (no await)
      _firestoreService!.addBudget(budget).then((_) {
        debugPrint('✅ Budget synced to Firebase');
        _syncWithFirebaseInBackground();
      }).catchError((error) {
        debugPrint('❌ Firebase sync error: $error');
      });

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error adding budget: $e');
      rethrow;
    }
  }

  Future<void> updateBudget(String id, BudgetModel budget) async {
    if (_firestoreService == null) return;

    try {
      // ✅ STEP 1: Update local state IMMEDIATELY
      final index = _budgets.indexWhere((b) => b.id == id);
      if (index != -1) {
        final updatedBudget = BudgetModel(
          id: id,
          category: budget.category,
          monthlyLimit: budget.monthlyLimit,
          period: budget.period,
          alertThreshold: budget.alertThreshold,
          month: budget.month,
          year: budget.year,
        );
        _budgets[index] = updatedBudget;
        notifyListeners();

        // ✅ STEP 2: Update cache IMMEDIATELY
        await _cacheManager.updateBudgetInCache(updatedBudget);
        debugPrint('✅ Budget updated in UI and cache immediately');

        // ✅ STEP 3: Save to Firebase in background (no await)
        _firestoreService!.updateBudget(id, budget).then((_) {
          debugPrint('✅ Budget update synced to Firebase');
        }).catchError((error) {
          debugPrint('❌ Firebase sync error: $error');
        });
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error updating budget: $e');
      rethrow;
    }
  }

  Future<void> deleteBudget(String id) async {
    if (_firestoreService == null) return;

    try {
      // ✅ STEP 1: Get budget before deleting
      final index = _budgets.indexWhere((b) => b.id == id);
      if (index == -1) return;

      final budgetToDelete = _budgets[index];

      // ✅ STEP 2: Remove from local state IMMEDIATELY
      _budgets.removeAt(index);
      notifyListeners();

      // ✅ STEP 3: Remove from cache IMMEDIATELY
      await _cacheManager.deleteBudgetFromCache(budgetToDelete);
      debugPrint('✅ Budget deleted from UI and cache immediately');

      // ✅ STEP 4: Delete from Firebase in background (no await)
      _firestoreService!.deleteBudget(id).then((_) {
        debugPrint('✅ Budget deletion synced to Firebase');
      }).catchError((error) {
        debugPrint('❌ Firebase sync error: $error');
      });

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error deleting budget: $e');
      rethrow;
    }
  }

  // ============================================
  // QUERY HELPERS
  // ============================================

  BudgetModel? getBudgetByCategory(String category) {
    try {
      return _budgets.firstWhere((b) => b.category == category);
    } catch (e) {
      return null;
    }
  }

  double getTotalBudget() {
    return _budgets.fold(0.0, (sum, b) => sum + b.monthlyLimit);
  }

  /// Get budgets for specific month (historical or future)
  List<BudgetModel> getBudgetsForMonth(int month, int year) {
    return _budgets.where((b) => b.month == month && b.year == year).toList();
  }

  /// Get all historical budgets (loads from cache if available)
  Future<List<BudgetModel>> getAllHistoricalBudgets() async {
    final cached = await _cacheManager.getCachedBudgets();
    return cached ?? [];
  }
}
