import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/recurring_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  FirestoreService(this.userId);

  // ============ TRANSACTIONS ============

  Future<void> addTransaction(TransactionModel transaction) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .add(transaction.toMap());
  }

  Future<void> updateTransaction(
      String transactionId, TransactionModel transaction) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId)
        .update(transaction.toMap());
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId)
        .delete();
  }

  Stream<List<TransactionModel>> getTransactions() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ============ BUDGETS ============

  Future<void> addBudget(BudgetModel budget) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .add(budget.toMap());
  }

  Future<void> updateBudget(String budgetId, BudgetModel budget) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(budgetId)
        .update(budget.toMap());
  }

  Future<void> deleteBudget(String budgetId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(budgetId)
        .delete();
  }

  Stream<List<BudgetModel>> getBudgets() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BudgetModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ============ GOALS ============

  Future<void> addGoal(GoalModel goal) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('goals')
        .add(goal.toMap());
  }

  Future<void> updateGoal(String goalId, GoalModel goal) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc(goalId)
        .update(goal.toMap());
  }

  Future<void> deleteGoal(String goalId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc(goalId)
        .delete();
  }

  Stream<List<GoalModel>> getGoals() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('goals')
        .orderBy('targetDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GoalModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Add contribution to goal
  Future<void> addGoalContribution(String goalId, double amount) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc(goalId)
        .get();

    if (doc.exists) {
      final goal = GoalModel.fromMap(doc.data()!, doc.id);
      final updatedGoal = goal.copyWith(
        currentAmount: goal.currentAmount + amount,
      );
      await updateGoal(goalId, updatedGoal);
    }
  }

  // ============ RECURRING TRANSACTIONS ============

  Future<void> addRecurring(RecurringModel recurring) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('recurring')
        .add(recurring.toMap());
  }

  Future<void> updateRecurring(
      String recurringId, RecurringModel recurring) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('recurring')
        .doc(recurringId)
        .update(recurring.toMap());
  }

  Future<void> deleteRecurring(String recurringId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('recurring')
        .doc(recurringId)
        .delete();
  }

  Stream<List<RecurringModel>> getRecurring() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('recurring')
        .orderBy('nextDueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RecurringModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ============ ANALYTICS ============

  Future<Map<String, double>> getCategorySpending(
      DateTime startDate, DateTime endDate) async {
    final transactions = await getTransactionsByDateRange(startDate, endDate);
    final Map<String, double> categoryTotals = {};

    for (var transaction in transactions) {
      if (transaction.type == 'expense') {
        categoryTotals[transaction.category] =
            (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      }
    }

    return categoryTotals;
  }

  Future<double> getTotalIncome(DateTime startDate, DateTime endDate) async {
    final transactions = await getTransactionsByDateRange(startDate, endDate);
    return transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Future<double> getTotalExpenses(DateTime startDate, DateTime endDate) async {
    final transactions = await getTransactionsByDateRange(startDate, endDate);
    return transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }
}
