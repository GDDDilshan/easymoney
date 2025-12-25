import 'package:flutter/material.dart';
import 'dart:async';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/cache_manager_service.dart';

/// ✅ FULLY OPTIMIZED TRANSACTION PROVIDER
/// - Caching layer BEFORE Firebase
/// - Smart loading strategy
/// - Batch updates to reduce reads
class TransactionProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final CacheManager _cacheManager = CacheManager();
  FirestoreService? _firestoreService;
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;
  LoadingLevel _currentLoadingLevel = LoadingLevel.none;
  StreamSubscription<List<TransactionModel>>? _transactionSubscription;

  // Getters
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  LoadingLevel get currentLoadingLevel => _currentLoadingLevel;
  bool get isMonthLoaded =>
      _currentLoadingLevel.index >= LoadingLevel.month.index;
  bool get isAllLoaded => _currentLoadingLevel == LoadingLevel.all;

  TransactionProvider() {
    _initService();
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }

  void _initService() {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      _firestoreService = FirestoreService(userId);
      // TRY CACHE FIRST, then Firebase
      _loadWithCache();
    }
  }

  /// 🔥 CACHE-FIRST APPROACH: Try cache before Firebase
  Future<void> _loadWithCache() async {
    _isLoading = true;
    notifyListeners();

    try {
      // STEP 1: Try to load from cache
      debugPrint('📦 STEP 1: Attempting to load from cache...');
      final cachedTransactions = await _cacheManager.getCachedTransactions();

      if (cachedTransactions != null) {
        // ✅ Cache HIT - Use cached data
        debugPrint(
            '✅ CACHE HIT: Loaded ${cachedTransactions.length} from cache');
        _transactions = cachedTransactions;
        _currentLoadingLevel = LoadingLevel.month;
        _isLoading = false;
        notifyListeners();

        // STEP 2: Sync with Firebase in background (don't block UI)
        _syncWithFirebaseInBackground();
        return;
      }

      // STEP 2: Cache miss or expired - Load from Firebase
      debugPrint('❌ CACHE MISS: Loading from Firebase...');
      await loadCurrentMonth();
    } catch (e) {
      debugPrint('❌ Error in cache-first load: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔄 Sync with Firebase in background without blocking UI
  /// ✅ FIXED: Using proper Stream handling with .listen() instead of .first
  Future<void> _syncWithFirebaseInBackground() async {
    if (_firestoreService == null) return;

    try {
      debugPrint('🔄 Background sync started...');
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      // ✅ FIXED: Use getTransactionsByDateRange which returns Future<List>
      final freshData =
          await _firestoreService!.getTransactionsByDateRange(monthStart, now);

      // Check if data changed
      if (freshData.length != _transactions.length ||
          !_isSameTransactions(freshData, _transactions)) {
        debugPrint(
            '🔄 Data changed: ${freshData.length} vs ${_transactions.length}');
        _transactions = freshData;

        // Update cache with fresh data
        await _cacheManager.cacheTransactions(freshData);
        notifyListeners();
      } else {
        debugPrint('✅ Data up-to-date, no update needed');
      }
    } catch (e) {
      debugPrint('⚠️ Background sync error (non-critical): $e');
    }
  }

  /// Check if transactions list is the same (to avoid unnecessary updates)
  bool _isSameTransactions(
      List<TransactionModel> list1, List<TransactionModel> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  /// Load current month (only if not already loaded)
  Future<void> loadCurrentMonth() async {
    if (_firestoreService == null) return;
    if (_currentLoadingLevel.index >= LoadingLevel.month.index) {
      debugPrint('⏭️ Current month data already loaded');
      return;
    }

    _isLoading = true;
    notifyListeners();

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    debugPrint('📊 Loading CURRENT MONTH from Firebase...');
    debugPrint('   Month: ${now.year}-${now.month.toString().padLeft(2, '0')}');
    debugPrint('   Expected reads: ~100-200');

    _transactionSubscription?.cancel();
    _transactionSubscription =
        _firestoreService!.getTransactions(startDate: monthStart).listen(
      (transactions) {
        _transactions = transactions;
        _isLoading = false;
        _error = null;
        _currentLoadingLevel = LoadingLevel.month;

        // Cache the loaded data
        _cacheManager.cacheTransactions(transactions);

        notifyListeners();
        debugPrint(
            '✅ Loaded ${transactions.length} transactions (CURRENT MONTH)');
        debugPrint('   Cached for offline use');
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
        debugPrint('❌ Error loading current month: $error');
      },
    );
  }

  /// Load full history (on-demand only)
  Future<void> loadFullHistory() async {
    if (_firestoreService == null) return;
    if (_currentLoadingLevel == LoadingLevel.all) {
      debugPrint('⏭️ Full history already loaded');
      return;
    }

    _isLoading = true;
    notifyListeners();

    debugPrint('📊 Loading FULL HISTORY from Firebase...');
    debugPrint('   ⚠️ WARNING: This may cost 200-500+ reads');

    _transactionSubscription?.cancel();
    _transactionSubscription = _firestoreService!
        .getTransactions() // No date filter = all transactions
        .listen(
      (transactions) {
        _transactions = transactions;
        _isLoading = false;
        _error = null;
        _currentLoadingLevel = LoadingLevel.all;

        // Cache full history
        _cacheManager.cacheTransactions(transactions);

        notifyListeners();
        debugPrint(
            '✅ Loaded ${transactions.length} transactions (FULL HISTORY)');
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
        debugPrint('❌ Error loading full history: $error');
      },
    );
  }

  /// Ensure minimum data level is loaded
  void ensureDataLoaded(LoadingLevel requiredLevel) {
    if (_currentLoadingLevel.index >= requiredLevel.index) {
      debugPrint('⏭️ Required level already loaded');
      return;
    }

    switch (requiredLevel) {
      case LoadingLevel.month:
        loadCurrentMonth();
        break;
      case LoadingLevel.all:
        loadFullHistory();
        break;
      case LoadingLevel.none:
        break;
    }
  }

  // ============ CRUD OPERATIONS ============

  Future<void> addTransaction(TransactionModel transaction) async {
    if (_firestoreService == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService!.addTransaction(transaction);
      _error = null;

      // Invalidate cache so next load is fresh
      await _cacheManager.clearTransactionCache();
      debugPrint('💾 Transaction added - Cache invalidated');
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTransaction(
      String id, TransactionModel transaction) async {
    if (_firestoreService == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService!.updateTransaction(id, transaction);
      _error = null;

      // Invalidate cache
      await _cacheManager.clearTransactionCache();
      debugPrint('📝 Transaction updated - Cache invalidated');
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    if (_firestoreService == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService!.deleteTransaction(id);
      _error = null;

      // Invalidate cache
      await _cacheManager.clearTransactionCache();
      debugPrint('🗑️ Transaction deleted - Cache invalidated');
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ QUERY HELPERS (OPTIMIZED) ============

  List<TransactionModel> getTransactionsByDateRange(
      DateTime start, DateTime end) {
    return _transactions.where((t) {
      return t.date.isAfter(start.subtract(const Duration(days: 1))) &&
          t.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  double getTotalIncome([DateTime? start, DateTime? end]) {
    var txns = _transactions;
    if (start != null && end != null) {
      txns = getTransactionsByDateRange(start, end);
    }
    return txns
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalExpenses([DateTime? start, DateTime? end]) {
    var txns = _transactions;
    if (start != null && end != null) {
      txns = getTransactionsByDateRange(start, end);
    }
    return txns
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> getCategorySpending([DateTime? start, DateTime? end]) {
    var txns = _transactions;
    if (start != null && end != null) {
      txns = getTransactionsByDateRange(start, end);
    }

    final Map<String, double> categoryTotals = {};
    for (var t in txns.where((t) => t.type == 'expense')) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }
    return categoryTotals;
  }

  // ============ DASHBOARD HELPERS ============

  List<TransactionModel> getTodayTransactions() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _transactions
        .where((t) =>
            t.date.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(todayEnd.add(const Duration(seconds: 1))))
        .toList();
  }

  List<TransactionModel> getThisWeekTransactions() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final mondayOffset = weekday - 1;
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: mondayOffset));
    final weekEnd = DateTime.now();

    return getTransactionsByDateRange(weekStart, weekEnd);
  }

  List<TransactionModel> getCurrentMonthTransactions() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime.now();

    return getTransactionsByDateRange(monthStart, monthEnd);
  }

  double getTodayIncome() {
    return getTodayTransactions()
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTodayExpenses() {
    return getTodayTransactions()
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getWeekIncome() {
    return getThisWeekTransactions()
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getWeekExpenses() {
    return getThisWeekTransactions()
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getMonthIncome() {
    return getCurrentMonthTransactions()
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getMonthExpenses() {
    return getCurrentMonthTransactions()
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }
}

enum LoadingLevel {
  none,
  month,
  all,
}
