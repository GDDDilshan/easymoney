import 'package:flutter/material.dart';
import 'dart:async';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/cache_manager_service.dart';

/// ✅ ULTIMATE OPTIMIZED TRANSACTION PROVIDER
/// - All changes (add/edit/delete) go to Firebase immediately
/// - On-demand loading (only load what user views)
/// - Smart caching (cache only what's loaded)
/// - Dashboard optimization (count-only queries)
class TransactionProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final SmartCacheManager _cacheManager = SmartCacheManager();
  FirestoreService? _firestoreService;

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;
  LoadingLevel _currentLoadingLevel = LoadingLevel.none;
  StreamSubscription<List<TransactionModel>>? _transactionSubscription;

  // 🔥 NEW: Dashboard stats (lightweight, no full transaction data)
  int _currentMonthCount = 0;
  double _currentMonthIncome = 0;
  double _currentMonthExpense = 0;
  bool _statsLoaded = false;

  // Getters
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  LoadingLevel get currentLoadingLevel => _currentLoadingLevel;
  bool get isMonthLoaded =>
      _currentLoadingLevel.index >= LoadingLevel.month.index;
  bool get isAllLoaded => _currentLoadingLevel == LoadingLevel.all;

  // 🔥 NEW: Dashboard getters (no Firebase reads needed)
  int get currentMonthTransactionCount => _currentMonthCount;
  double get currentMonthIncome => _currentMonthIncome;
  double get currentMonthExpense => _currentMonthExpense;
  bool get dashboardStatsLoaded => _statsLoaded;

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
      _loadDashboardStats(); // Load stats first (lightweight)
    }
  }

  // ============================================
  // 🔥 DASHBOARD OPTIMIZATION - Count Only
  // ============================================

  /// Load ONLY count and totals for dashboard (NO transaction data)
  /// Cost: 1-3 Firebase reads (aggregation query)
  Future<void> _loadDashboardStats() async {
    try {
      debugPrint('📊 Loading dashboard stats (count only, no data)...');

      // Try cache first
      final cachedStats = await _cacheManager.getCachedDashboardStats();
      if (cachedStats != null) {
        _currentMonthCount = cachedStats['count'] ?? 0;
        _currentMonthIncome = cachedStats['income'] ?? 0.0;
        _currentMonthExpense = cachedStats['expense'] ?? 0.0;
        _statsLoaded = true;
        notifyListeners();
        debugPrint('✅ Dashboard stats loaded from cache');

        // Background refresh
        _refreshDashboardStatsInBackground();
        return;
      }

      // Load from Firebase (lightweight aggregation)
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      final stats = await _firestoreService!.getDashboardStats(monthStart, now);

      _currentMonthCount = stats['count'] ?? 0;
      _currentMonthIncome = stats['income'] ?? 0.0;
      _currentMonthExpense = stats['expense'] ?? 0.0;
      _statsLoaded = true;

      // Cache stats
      await _cacheManager.cacheDashboardStats({
        'count': _currentMonthCount,
        'income': _currentMonthIncome,
        'expense': _currentMonthExpense,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      notifyListeners();
      debugPrint(
          '✅ Dashboard stats loaded from Firebase: $_currentMonthCount transactions');
    } catch (e) {
      debugPrint('❌ Error loading dashboard stats: $e');
    }
  }

  Future<void> _refreshDashboardStatsInBackground() async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      final stats = await _firestoreService!.getDashboardStats(monthStart, now);

      if (stats['count'] != _currentMonthCount ||
          stats['income'] != _currentMonthIncome ||
          stats['expense'] != _currentMonthExpense) {
        _currentMonthCount = stats['count'] ?? 0;
        _currentMonthIncome = stats['income'] ?? 0.0;
        _currentMonthExpense = stats['expense'] ?? 0.0;

        await _cacheManager.cacheDashboardStats({
          'count': _currentMonthCount,
          'income': _currentMonthIncome,
          'expense': _currentMonthExpense,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        notifyListeners();
        debugPrint('✅ Dashboard stats refreshed in background');
      }
    } catch (e) {
      debugPrint('⚠️ Background stats refresh error: $e');
    }
  }

  // ============================================
  // 🔥 ON-DEMAND LOADING (Load only when user views)
  // ============================================

  /// Load ONLY current month transactions (when user navigates to Transactions tab)
  Future<void> loadCurrentMonth({bool forceRefresh = false}) async {
    if (_firestoreService == null) return;

    if (_currentLoadingLevel.index >= LoadingLevel.month.index &&
        !forceRefresh) {
      debugPrint('⏭️ Current month data already loaded');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      debugPrint('📊 Loading CURRENT MONTH transactions on-demand...');
      debugPrint('   Expected reads: ~100-200 (only when user views)');

      // Try cache first
      final cachedTransactions = await _cacheManager.getCachedTransactions();
      if (cachedTransactions != null && !forceRefresh) {
        _transactions = cachedTransactions;
        _currentLoadingLevel = LoadingLevel.month;
        _isLoading = false;
        notifyListeners();
        debugPrint('✅ Loaded ${cachedTransactions.length} from cache');

        // Background sync
        _syncWithFirebaseInBackground();
        return;
      }

      // Load from Firebase
      _transactionSubscription?.cancel();
      _transactionSubscription =
          _firestoreService!.getTransactions(startDate: monthStart).listen(
        (transactions) {
          _transactions = transactions;
          _isLoading = false;
          _error = null;
          _currentLoadingLevel = LoadingLevel.month;

          _cacheManager.cacheTransactions(transactions);

          notifyListeners();
          debugPrint(
              '✅ Loaded ${transactions.length} transactions from Firebase');
        },
        onError: (error) {
          _error = error.toString();
          _isLoading = false;
          notifyListeners();
          debugPrint('❌ Error loading transactions: $error');
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Error loading current month: $e');
    }
  }

  Future<void> _syncWithFirebaseInBackground() async {
    if (_firestoreService == null) return;

    try {
      debugPrint('🔄 Background sync started...');
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      final freshData =
          await _firestoreService!.getTransactionsByDateRange(monthStart, now);

      if (freshData.length != _transactions.length ||
          !_isSameTransactions(freshData, _transactions)) {
        debugPrint(
            '🔄 Data changed: ${freshData.length} vs ${_transactions.length}');
        _transactions = freshData;
        await _cacheManager.cacheTransactions(freshData);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Background sync error: $e');
    }
  }

  bool _isSameTransactions(
      List<TransactionModel> list1, List<TransactionModel> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  /// Load full history (only when user explicitly requests it)
  Future<void> loadFullHistory() async {
    if (_firestoreService == null) return;
    if (_currentLoadingLevel == LoadingLevel.all) {
      debugPrint('⏭️ Full history already loaded');
      return;
    }

    _isLoading = true;
    notifyListeners();

    debugPrint('📊 Loading FULL HISTORY (user requested)...');
    debugPrint('   ⚠️ WARNING: This may cost 200-500+ reads');

    _transactionSubscription?.cancel();
    _transactionSubscription = _firestoreService!.getTransactions().listen(
      (transactions) {
        _transactions = transactions;
        _isLoading = false;
        _error = null;
        _currentLoadingLevel = LoadingLevel.all;

        _cacheManager.cacheTransactions(transactions);

        notifyListeners();
        debugPrint(
            '✅ Loaded ${transactions.length} transactions (FULL HISTORY)');
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ============================================
  // 🔥 CRUD OPERATIONS - ALL GO TO FIREBASE IMMEDIATELY
  // ============================================

  Future<void> addTransaction(TransactionModel transaction) async {
    if (_firestoreService == null) return;

    try {
      debugPrint('➕ Adding transaction to Firebase immediately...');

      // ✅ STEP 1: Save to Firebase IMMEDIATELY (no await for UI)
      final firestoreFuture = _firestoreService!.addTransaction(transaction);

      // ✅ STEP 2: Update local state for instant UI
      final tempTransaction = transaction.copyWith(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      );
      _transactions.insert(0, tempTransaction);

      // ✅ STEP 3: Update dashboard stats
      if (transaction.type == 'income') {
        _currentMonthIncome += transaction.amount;
      } else {
        _currentMonthExpense += transaction.amount;
      }
      _currentMonthCount++;

      notifyListeners();

      // ✅ STEP 4: Update cache
      await _cacheManager.addTransactionToCache(tempTransaction);
      await _cacheManager.cacheDashboardStats({
        'count': _currentMonthCount,
        'income': _currentMonthIncome,
        'expense': _currentMonthExpense,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('✅ Transaction added to UI and cache instantly');

      // ✅ STEP 5: Wait for Firebase and sync
      await firestoreFuture;
      debugPrint('✅ Transaction saved to Firebase');

      // Background sync to get real ID
      _syncWithFirebaseInBackground();

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error adding transaction: $e');
      rethrow;
    }
  }

  Future<void> updateTransaction(
      String id, TransactionModel transaction) async {
    if (_firestoreService == null) return;

    try {
      debugPrint('✏️ Updating transaction in Firebase immediately...');

      // ✅ Find old transaction to adjust stats
      final index = _transactions.indexWhere((t) => t.id == id);
      if (index == -1) return;

      final oldTransaction = _transactions[index];

      // ✅ STEP 1: Update Firebase IMMEDIATELY
      final firestoreFuture =
          _firestoreService!.updateTransaction(id, transaction);

      // ✅ STEP 2: Update local state
      final updatedTransaction = transaction.copyWith(id: id);
      _transactions[index] = updatedTransaction;

      // ✅ STEP 3: Adjust dashboard stats
      if (oldTransaction.type == 'income') {
        _currentMonthIncome -= oldTransaction.amount;
      } else {
        _currentMonthExpense -= oldTransaction.amount;
      }

      if (updatedTransaction.type == 'income') {
        _currentMonthIncome += updatedTransaction.amount;
      } else {
        _currentMonthExpense += updatedTransaction.amount;
      }

      notifyListeners();

      // ✅ STEP 4: Update cache
      await _cacheManager.updateTransactionInCache(updatedTransaction);
      await _cacheManager.cacheDashboardStats({
        'count': _currentMonthCount,
        'income': _currentMonthIncome,
        'expense': _currentMonthExpense,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('✅ Transaction updated in UI and cache instantly');

      // ✅ STEP 5: Wait for Firebase
      await firestoreFuture;
      debugPrint('✅ Transaction updated in Firebase');

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error updating transaction: $e');
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    if (_firestoreService == null) return;

    try {
      debugPrint('🗑️ Deleting transaction from Firebase immediately...');

      // ✅ Find transaction
      final index = _transactions.indexWhere((t) => t.id == id);
      if (index == -1) return;

      final transactionToDelete = _transactions[index];

      // ✅ STEP 1: Delete from Firebase IMMEDIATELY
      final firestoreFuture = _firestoreService!.deleteTransaction(id);

      // ✅ STEP 2: Update local state
      _transactions.removeAt(index);

      // ✅ STEP 3: Adjust dashboard stats
      if (transactionToDelete.type == 'income') {
        _currentMonthIncome -= transactionToDelete.amount;
      } else {
        _currentMonthExpense -= transactionToDelete.amount;
      }
      _currentMonthCount--;

      notifyListeners();

      // ✅ STEP 4: Update cache
      await _cacheManager.deleteTransactionFromCache(transactionToDelete);
      await _cacheManager.cacheDashboardStats({
        'count': _currentMonthCount,
        'income': _currentMonthIncome,
        'expense': _currentMonthExpense,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('✅ Transaction deleted from UI and cache instantly');

      // ✅ STEP 5: Wait for Firebase
      await firestoreFuture;
      debugPrint('✅ Transaction deleted from Firebase');

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error deleting transaction: $e');
      rethrow;
    }
  }

  // ============================================
  // QUERY HELPERS
  // ============================================

  List<TransactionModel> getTransactionsByDateRange(
      DateTime start, DateTime end) {
    return _transactions.where((t) {
      return t.date.isAfter(start.subtract(const Duration(days: 1))) &&
          t.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  double getTotalIncome([DateTime? start, DateTime? end]) {
    if (start == null && end == null && _statsLoaded) {
      return _currentMonthIncome; // Use cached stats
    }

    var txns = _transactions;
    if (start != null && end != null) {
      txns = getTransactionsByDateRange(start, end);
    }
    return txns
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalExpenses([DateTime? start, DateTime? end]) {
    if (start == null && end == null && _statsLoaded) {
      return _currentMonthExpense; // Use cached stats
    }

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

  // Dashboard helpers (use cached stats when possible)
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

  double getTodayIncome() => getTodayTransactions()
      .where((t) => t.type == 'income')
      .fold(0.0, (sum, t) => sum + t.amount);
  double getTodayExpenses() => getTodayTransactions()
      .where((t) => t.type == 'expense')
      .fold(0.0, (sum, t) => sum + t.amount);
  double getWeekIncome() => getThisWeekTransactions()
      .where((t) => t.type == 'income')
      .fold(0.0, (sum, t) => sum + t.amount);
  double getWeekExpenses() => getThisWeekTransactions()
      .where((t) => t.type == 'expense')
      .fold(0.0, (sum, t) => sum + t.amount);
  double getMonthIncome() => _statsLoaded
      ? _currentMonthIncome
      : getCurrentMonthTransactions()
          .where((t) => t.type == 'income')
          .fold(0.0, (sum, t) => sum + t.amount);
  double getMonthExpenses() => _statsLoaded
      ? _currentMonthExpense
      : getCurrentMonthTransactions()
          .where((t) => t.type == 'expense')
          .fold(0.0, (sum, t) => sum + t.amount);
}

enum LoadingLevel {
  none,
  month,
  all,
}
