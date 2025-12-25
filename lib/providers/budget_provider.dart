import 'package:flutter/material.dart';
import 'dart:async';
import '../models/budget_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/cache_manager_service.dart';

/// ✅ FULLY OPTIMIZED BUDGET PROVIDER
/// - Smart filtering by current month ONLY
/// - Caching before Firebase
/// - Reduced listener scope
class BudgetProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final CacheManager _cacheManager = CacheManager();
  FirestoreService? _firestoreService;
  List<BudgetModel> _budgets = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<BudgetModel>>? _budgetSubscription;

  // Track what's loaded
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
      // STEP 1: Try to load from cache
      debugPrint('📦 Budget: STEP 1 - Attempting to load from cache...');
      final cachedBudgets = await _cacheManager.getCachedBudgets();

      if (cachedBudgets != null) {
        // ✅ Cache HIT
        final currentMonthBudgets = _filterCurrentMonth(cachedBudgets);
        debugPrint(
            '✅ Budget CACHE HIT: ${currentMonthBudgets.length} this month (cached)');
        _budgets = currentMonthBudgets;
        _isLoading = false;
        _hasInitialized = true;
        notifyListeners();

        // STEP 2: Sync in background
        _syncWithFirebaseInBackground();
        return;
      }

      // STEP 2: Cache miss - Load from Firebase
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

      // Check if data changed
      if (!_isSameBudgets(currentMonthBudgets, _budgets)) {
        debugPrint('🔄 Budget: Data changed, updating...');
        _budgets = currentMonthBudgets;

        // Update cache with all budgets
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
        // Filter to current month only
        final currentMonthBudgets = _filterCurrentMonth(allBudgets);

        _budgets = currentMonthBudgets;
        _isLoading = false;
        _error = null;
        _hasInitialized = true;

        // Cache ALL budgets (for background sync)
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

  // ============ CRUD OPERATIONS ============

  Future<void> addBudget(BudgetModel budget) async {
    if (_firestoreService == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService!.addBudget(budget);
      _error = null;

      // Invalidate cache
      await _cacheManager.clearBudgetCache();
      debugPrint('💾 Budget added - Cache invalidated');
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBudget(String id, BudgetModel budget) async {
    if (_firestoreService == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService!.updateBudget(id, budget);
      _error = null;

      // Invalidate cache
      await _cacheManager.clearBudgetCache();
      debugPrint('📝 Budget updated - Cache invalidated');
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteBudget(String id) async {
    if (_firestoreService == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService!.deleteBudget(id);
      _error = null;

      // Invalidate cache
      await _cacheManager.clearBudgetCache();
      debugPrint('🗑️ Budget deleted - Cache invalidated');
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ QUERY HELPERS ============

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
