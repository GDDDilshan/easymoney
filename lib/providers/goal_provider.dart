import 'package:flutter/material.dart';
import '../models/goal_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class GoalProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  FirestoreService? _firestoreService;
  List<GoalModel> _goals = [];
  bool _isLoading = false;
  String? _error;

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

  void _initService() {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      _firestoreService = FirestoreService(userId);
      loadGoals();
    }
  }

  void loadGoals() {
    if (_firestoreService == null) return;

    _firestoreService!.getGoals().listen(
      (goals) {
        _goals = goals;
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

  Future<void> addGoal(GoalModel goal) async {
    if (_firestoreService == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService!.addGoal(goal);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateGoal(String id, GoalModel goal) async {
    if (_firestoreService == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService!.updateGoal(id, goal);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteGoal(String id) async {
    if (_firestoreService == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService!.deleteGoal(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addContribution(String id, double amount) async {
    if (_firestoreService == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService!.addGoalContribution(id, amount);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
