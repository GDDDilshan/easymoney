import 'package:flutter/material.dart';
import 'dart:async';
import '../models/budget_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/cache_manager_service.dart';

/// ✅ FIXED BUDGET PROVIDER
/// - All CRUD → Firebase immediately
/// - Cache loads first if available, syncs in background
/// - If no cache, loads from Firebase
class BudgetProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final SmartCacheManager _cacheManager = SmartCacheManager();
  FirestoreService? _firestoreService;
  List<BudgetModel> _budgets = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<BudgetModel>>? _budgetSubscription;

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

  /// FIXED: Load cache first, but fallback to Firebase if empty
  Future<void> _loadWithCache() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('📦 Budget: Loading from cache...');
      final cachedBudgets = await _cacheManager.getCachedBudgets();

      if (cachedBudgets != null && cachedBudgets.isNotEmpty) {
        final currentMonthBudgets = _filterCurrentMonth(cachedBudgets);
        debugPrint(
            '✅ Budget CACHE HIT: ${currentMonthBudgets.length} (will sync in background)');
        _budgets = currentMonthBudgets;
        _isLoading = false;
        notifyListeners();

        _syncWithFirebaseInBackground();
        return;
      }

      debugPrint('⚠️ Budget cache empty, loading from Firebase...');
      await _loadFromFirebase();
    } catch (e) {
      debugPrint('❌ Error in budget load: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromFirebase() async {
    if (_firestoreService == null) return;

    _isLoading = true;
    notifyListeners();

    debugPrint('🔥 Budget: Loading from Firebase...');

    _budgetSubscription?.cancel();
    _budgetSubscription = _firestoreService!.getBudgets().listen(
      (allBudgets) {
        final currentMonthBudgets = _filterCurrentMonth(allBudgets);
        _budgets = currentMonthBudgets;
        _isLoading = false;
        _error = null;

        _cacheManager.cacheBudgets(allBudgets);

        notifyListeners();
        debugPrint(
            '✅ Loaded ${currentMonthBudgets.length} budgets from Firebase');
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
        debugPrint('❌ Error loading budgets: $error');
      },
    );
  }

  Future<void> _syncWithFirebaseInBackground() async {
    if (_firestoreService == null) return;

    try {
      debugPrint('🔄 Budget: Background sync...');
      final allBudgets = await _firestoreService!.getBudgets().first;
      final currentMonthBudgets = _filterCurrentMonth(allBudgets);

      if (!_isSameBudgets(currentMonthBudgets, _budgets)) {
        debugPrint('🔄 Budget: Data changed, updating...');
        _budgets = currentMonthBudgets;
        await _cacheManager.cacheBudgets(allBudgets);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Budget background sync error: $e');
    }
  }

  List<BudgetModel> _filterCurrentMonth(List<BudgetModel> allBudgets) {
    final now = DateTime.now();
    return allBudgets
        .where((b) => b.month == now.month && b.year == now.year)
        .toList();
  }

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

  // ============================================
  // CRUD OPERATIONS - Firebase First
  // ============================================

  Future<void> addBudget(BudgetModel budget) async {
    if (_firestoreService == null) return;

    try {
      debugPrint('➕ Adding budget to Firebase...');

      // ✅ Save to Firebase FIRST
      await _firestoreService!.addBudget(budget);
      debugPrint('✅ Budget saved to Firebase');

      // ✅ Update local state
      final tempBudget = BudgetModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        category: budget.category,
        monthlyLimit: budget.monthlyLimit,
        period: budget.period,
        alertThreshold: budget.alertThreshold,
        month: budget.month,
        year: budget.year,
      );
      _budgets.add(tempBudget);
      notifyListeners();

      // ✅ Update cache
      await _cacheManager.addBudgetToCache(tempBudget);
      debugPrint('✅ Budget added to UI and cache');

      // Sync to get real ID
      _syncWithFirebaseInBackground();

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
      debugPrint('✏️ Updating budget in Firebase...');

      // ✅ Update Firebase FIRST
      await _firestoreService!.updateBudget(id, budget);
      debugPrint('✅ Budget updated in Firebase');

      // ✅ Update local state
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

        await _cacheManager.updateBudgetInCache(updatedBudget);
        debugPrint('✅ Budget updated in UI and cache');
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
      debugPrint('🗑️ Deleting budget from Firebase...');

      final index = _budgets.indexWhere((b) => b.id == id);
      if (index == -1) return;

      final budgetToDelete = _budgets[index];

      // ✅ Delete from Firebase FIRST
      await _firestoreService!.deleteBudget(id);
      debugPrint('✅ Budget deleted from Firebase');

      // ✅ Update local state
      _budgets.removeAt(index);
      notifyListeners();

      // ✅ Update cache
      await _cacheManager.deleteBudgetFromCache(budgetToDelete);
      debugPrint('✅ Budget deleted from UI and cache');

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

  List<BudgetModel> getBudgetsForMonth(int month, int year) {
    return _budgets.where((b) => b.month == month && b.year == year).toList();
  }

  Future<List<BudgetModel>> getAllHistoricalBudgets() async {
    final cached = await _cacheManager.getCachedBudgets();
    return cached ?? [];
  }
}
