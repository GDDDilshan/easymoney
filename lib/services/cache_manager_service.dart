import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';

/// 🔒 ENCRYPTED CACHE MANAGER
/// Manages encrypted local caching of Firebase data
/// Reduces Firebase reads and provides offline support
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final SecureStorageService _storage = SecureStorageService();

  // Cache expiry durations
  static const Duration _transactionCacheExpiry = Duration(hours: 6);
  static const Duration _budgetCacheExpiry = Duration(hours: 12);
  static const Duration _goalCacheExpiry = Duration(hours: 12);
  static const Duration _userCacheExpiry = Duration(days: 7);

  // ============================================
  // TRANSACTIONS CACHE (Encrypted)
  // ============================================

  /// Cache transactions (encrypted)
  Future<void> cacheTransactions(List<TransactionModel> transactions) async {
    try {
      final data = {
        'transactions': transactions.map((t) => t.toMap()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await _storage.writeJson(
        key: 'cached_transactions',
        json: data,
      );

      debugPrint('✅ Cached ${transactions.length} transactions (encrypted)');
    } catch (e) {
      debugPrint('❌ Error caching transactions: $e');
    }
  }

  /// Get cached transactions (decrypted)
  Future<List<TransactionModel>?> getCachedTransactions() async {
    try {
      final data = await _storage.readJson(key: 'cached_transactions');
      if (data == null) return null;

      // Check if cache is expired
      final timestamp = data['timestamp'] as int;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _transactionCacheExpiry.inMilliseconds) {
        debugPrint('⏰ Transaction cache expired');
        await clearTransactionCache();
        return null;
      }

      final transactionsData = data['transactions'] as List;
      final transactions = transactionsData
          .map((t) => TransactionModel.fromMap(
                t as Map<String, dynamic>,
                t['id'] ?? '',
              ))
          .toList();

      debugPrint('✅ Loaded ${transactions.length} cached transactions');
      return transactions;
    } catch (e) {
      debugPrint('❌ Error loading cached transactions: $e');
      return null;
    }
  }

  /// Clear transaction cache
  Future<void> clearTransactionCache() async {
    await _storage.delete(key: 'cached_transactions');
    debugPrint('🗑️ Transaction cache cleared');
  }

  // ============================================
  // BUDGETS CACHE (Encrypted)
  // ============================================

  /// Cache budgets (encrypted)
  Future<void> cacheBudgets(List<BudgetModel> budgets) async {
    try {
      final data = {
        'budgets': budgets.map((b) => b.toMap()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await _storage.writeJson(
        key: 'cached_budgets',
        json: data,
      );

      debugPrint('✅ Cached ${budgets.length} budgets (encrypted)');
    } catch (e) {
      debugPrint('❌ Error caching budgets: $e');
    }
  }

  /// Get cached budgets (decrypted)
  Future<List<BudgetModel>?> getCachedBudgets() async {
    try {
      final data = await _storage.readJson(key: 'cached_budgets');
      if (data == null) return null;

      // Check if cache is expired
      final timestamp = data['timestamp'] as int;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _budgetCacheExpiry.inMilliseconds) {
        debugPrint('⏰ Budget cache expired');
        await clearBudgetCache();
        return null;
      }

      final budgetsData = data['budgets'] as List;
      final budgets = budgetsData
          .map((b) => BudgetModel.fromMap(
                b as Map<String, dynamic>,
                b['id'] ?? '',
              ))
          .toList();

      debugPrint('✅ Loaded ${budgets.length} cached budgets');
      return budgets;
    } catch (e) {
      debugPrint('❌ Error loading cached budgets: $e');
      return null;
    }
  }

  /// Clear budget cache
  Future<void> clearBudgetCache() async {
    await _storage.delete(key: 'cached_budgets');
    debugPrint('🗑️ Budget cache cleared');
  }

  // ============================================
  // GOALS CACHE (Encrypted)
  // ============================================

  /// Cache goals (encrypted)
  Future<void> cacheGoals(List<GoalModel> goals) async {
    try {
      final data = {
        'goals': goals.map((g) => g.toMap()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await _storage.writeJson(
        key: 'cached_goals',
        json: data,
      );

      debugPrint('✅ Cached ${goals.length} goals (encrypted)');
    } catch (e) {
      debugPrint('❌ Error caching goals: $e');
    }
  }

  /// Get cached goals (decrypted)
  Future<List<GoalModel>?> getCachedGoals() async {
    try {
      final data = await _storage.readJson(key: 'cached_goals');
      if (data == null) return null;

      // Check if cache is expired
      final timestamp = data['timestamp'] as int;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _goalCacheExpiry.inMilliseconds) {
        debugPrint('⏰ Goal cache expired');
        await clearGoalCache();
        return null;
      }

      final goalsData = data['goals'] as List;
      final goals = goalsData
          .map((g) => GoalModel.fromMap(
                g as Map<String, dynamic>,
                g['id'] ?? '',
              ))
          .toList();

      debugPrint('✅ Loaded ${goals.length} cached goals');
      return goals;
    } catch (e) {
      debugPrint('❌ Error loading cached goals: $e');
      return null;
    }
  }

  /// Clear goal cache
  Future<void> clearGoalCache() async {
    await _storage.delete(key: 'cached_goals');
    debugPrint('🗑️ Goal cache cleared');
  }

  // ============================================
  // USER DATA CACHE (Encrypted)
  // ============================================

  /// Cache user data (encrypted)
  Future<void> cacheUserData(Map<String, dynamic> userData) async {
    try {
      final data = {
        'user': userData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await _storage.writeJson(
        key: 'cached_user_data',
        json: data,
      );

      debugPrint('✅ User data cached (encrypted)');
    } catch (e) {
      debugPrint('❌ Error caching user data: $e');
    }
  }

  /// Get cached user data (decrypted)
  Future<Map<String, dynamic>?> getCachedUserData() async {
    try {
      final data = await _storage.readJson(key: 'cached_user_data');
      if (data == null) return null;

      // Check if cache is expired
      final timestamp = data['timestamp'] as int;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _userCacheExpiry.inMilliseconds) {
        debugPrint('⏰ User data cache expired');
        await clearUserCache();
        return null;
      }

      debugPrint('✅ Loaded cached user data');
      return data['user'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Error loading cached user data: $e');
      return null;
    }
  }

  /// Clear user cache
  Future<void> clearUserCache() async {
    await _storage.delete(key: 'cached_user_data');
    debugPrint('🗑️ User cache cleared');
  }

  // ============================================
  // CACHE MANAGEMENT
  // ============================================

  /// Clear all caches
  Future<void> clearAllCaches() async {
    await clearTransactionCache();
    await clearBudgetCache();
    await clearGoalCache();
    await clearUserCache();
    debugPrint('🗑️ All caches cleared');
  }

  /// Get cache size info
  Future<Map<String, bool>> getCacheStatus() async {
    return {
      'transactions': await _storage.containsKey(key: 'cached_transactions'),
      'budgets': await _storage.containsKey(key: 'cached_budgets'),
      'goals': await _storage.containsKey(key: 'cached_goals'),
      'user': await _storage.containsKey(key: 'cached_user_data'),
    };
  }
}
