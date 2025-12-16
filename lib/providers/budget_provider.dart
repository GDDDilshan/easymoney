import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class BudgetProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  FirestoreService? _firestoreService;
  List<BudgetModel> _budgets = [];
  bool _isLoading = false;
  String? _error;

  List<BudgetModel> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BudgetProvider() {
    _initService();
  }

  void _initService() {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      _firestoreService = FirestoreService(userId);
      loadBudgets();
    }
  }

  void loadBudgets() {
    if (_firestoreService == null) return;

    _firestoreService!.getBudgets().listen(
      (budgets) {
        _budgets = budgets;
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

  Future<void> addBudget(BudgetModel budget) async {
    if (_firestoreService == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService!.addBudget(budget);
      _error = null;
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
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
}
