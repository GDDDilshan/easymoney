import 'package:flutter/material.dart';
import 'dart:async';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class TransactionProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  FirestoreService? _firestoreService;
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;

  // ✅ NEW: Track loading state
  bool _isFullHistoryLoaded = false;
  StreamSubscription<List<TransactionModel>>? _transactionSubscription;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isFullHistoryLoaded => _isFullHistoryLoaded;

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
      // ✅ OPTIMIZED: Load smart (current month + recent data)
      loadTransactionsSmart();
    }
  }

  /// ✅ SMART LOADING: Load last 3 months by default (balances UX and cost)
  void loadTransactionsSmart() {
    if (_firestoreService == null) return;
    if (_isFullHistoryLoaded) return; // Don't reload if we have full history

    _isLoading = true;
    notifyListeners();

    // Load last 3 months (good balance between cost and UX)
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);

    debugPrint('📊 Loading transactions from last 3 months...');
    debugPrint('   Start date: ${threeMonthsAgo.toString()}');

    _transactionSubscription?.cancel();
    _transactionSubscription =
        _firestoreService!.getTransactions(startDate: threeMonthsAgo).listen(
      (transactions) {
        _transactions = transactions;
        _isLoading = false;
        _error = null;
        notifyListeners();

        debugPrint(
            '✅ Loaded ${transactions.length} transactions (last 3 months)');

        // Auto-expand if very few transactions
        if (transactions.length < 20 && !_isFullHistoryLoaded) {
          debugPrint('⚡ Auto-loading full history (< 20 transactions found)');
          loadFullHistory();
        }
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
        debugPrint('❌ Error loading transactions: $error');
      },
    );
  }

  /// ✅ FULL HISTORY: Load all transactions (called on-demand)
  void loadFullHistory() {
    if (_firestoreService == null) return;
    if (_isFullHistoryLoaded) {
      debugPrint('✅ Full history already loaded');
      return;
    }

    _isLoading = true;
    _isFullHistoryLoaded = true;
    notifyListeners();

    debugPrint('📊 Loading FULL transaction history...');

    _transactionSubscription?.cancel();
    _transactionSubscription = _firestoreService!
        .getTransactions() // No date filter = all transactions
        .listen(
      (transactions) {
        _transactions = transactions;
        _isLoading = false;
        _error = null;
        notifyListeners();
        debugPrint(
            '✅ Loaded ${transactions.length} transactions (FULL HISTORY)');
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        _isFullHistoryLoaded = false; // Reset flag on error
        notifyListeners();
        debugPrint('❌ Error loading full history: $error');
      },
    );
  }

  /// Legacy method for backward compatibility
  void loadTransactions() {
    loadTransactionsSmart();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    if (_firestoreService == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService!.addTransaction(transaction);
      _error = null;
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
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
}
