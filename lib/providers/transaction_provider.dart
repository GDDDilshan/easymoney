import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class TransactionProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  FirestoreService? _firestoreService;
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  TransactionProvider() {
    _initService();
  }

  void _initService() {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      _firestoreService = FirestoreService(userId);
      loadTransactions();
    }
  }

  void loadTransactions() {
    if (_firestoreService == null) return;

    _firestoreService!.getTransactions().listen(
      (transactions) {
        _transactions = transactions;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
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
