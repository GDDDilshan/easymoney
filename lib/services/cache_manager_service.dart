import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';

/// 🔒 OPTIMIZED CACHE MANAGER - FULL COST REDUCTION
/// Aggressively caches Firebase data and reduces read frequency
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final SecureStorageService _storage = SecureStorageService();

  // AGGRESSIVE CACHE EXPIRY - longer cache times = fewer reads
  static const Duration _transactionCacheExpiry = Duration(hours: 24);
  static const Duration _budgetCacheExpiry = Duration(days: 7);
  static const Duration _goalCacheExpiry = Duration(days: 7);
  static const Duration _userCacheExpiry = Duration(days: 30);

  // ============================================
  // CACHE METADATA - Track cache status
  // ============================================

  /// Get detailed cache status with expiry times
  Future<Map<String, dynamic>> getCacheDetailedStatus() async {
    try {
      final transactions = await _getCacheMetadata('cached_transactions');
      final budgets = await _getCacheMetadata('cached_budgets');
      final goals = await _getCacheMetadata('cached_goals');
      final user = await _getCacheMetadata('cached_user_data');

      return {
        'transactions': transactions,
        'budgets': budgets,
        'goals': goals,
        'user': user,
      };
    } catch (e) {
      debugPrint('❌ Error getting cache status: $e');
      return {};
    }
  }

  /// Get individual cache metadata
  Future<Map<String, dynamic>?> _getCacheMetadata(String key) async {
    try {
      final data = await _storage.readJson(key: key);
      if (data == null) {
        return {'exists': false, 'expiresAt': null};
      }

      final timestamp = data['timestamp'] as int?;
      if (timestamp == null) return {'exists': false};

      final expiresAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final isExpired = DateTime.now().isAfter(expiresAt);

      return {
        'exists': true,
        'cachedAt': expiresAt.toString(),
        'expiresAt': expiresAt.add(_getCacheDuration(key)).toString(),
        'isExpired': isExpired,
      };
    } catch (e) {
      return {'exists': false, 'error': e.toString()};
    }
  }

  /// Get cache duration for specific key
  Duration _getCacheDuration(String key) {
    if (key.contains('transaction')) return _transactionCacheExpiry;
    if (key.contains('budget')) return _budgetCacheExpiry;
    if (key.contains('goal')) return _goalCacheExpiry;
    return _userCacheExpiry;
  }

  // ============================================
  // TRANSACTIONS CACHE (Encrypted & Aggressive)
  // ============================================

  /// Cache transactions (encrypted) - Called after Firebase fetch
  Future<void> cacheTransactions(List<TransactionModel> transactions) async {
    try {
      final data = {
        'transactions': transactions.map((t) => t.toMap()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'count': transactions.length,
      };

      await _storage.writeJson(
        key: 'cached_transactions',
        json: data,
      );

      debugPrint(
          '✅ CACHED: ${transactions.length} transactions (24 hour expiry)');
    } catch (e) {
      debugPrint('❌ Error caching transactions: $e');
    }
  }

  /// Get cached transactions BEFORE Firestore
  /// Returns null if cache expired - then fetch from Firebase
  Future<List<TransactionModel>?> getCachedTransactions() async {
    try {
      final data = await _storage.readJson(key: 'cached_transactions');
      if (data == null) {
        debugPrint('📭 No cached transactions');
        return null;
      }

      // Check if cache is expired
      final timestamp = data['timestamp'] as int;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _transactionCacheExpiry.inMilliseconds) {
        debugPrint(
            '⏰ Transaction cache EXPIRED (${(cacheAge / 3600000).toStringAsFixed(1)}h old)');
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

      debugPrint(
          '✅ LOADED FROM CACHE: ${transactions.length} transactions (${(cacheAge / 60000).toStringAsFixed(0)}m old)');
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
  // BUDGETS CACHE (Encrypted & Aggressive)
  // ============================================

  /// Cache budgets - separated by month/year for smart loading
  Future<void> cacheBudgets(List<BudgetModel> budgets) async {
    try {
      final data = {
        'budgets': budgets.map((b) => b.toMap()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'count': budgets.length,
      };

      await _storage.writeJson(
        key: 'cached_budgets',
        json: data,
      );

      debugPrint('✅ CACHED: ${budgets.length} budgets (7 day expiry)');
    } catch (e) {
      debugPrint('❌ Error caching budgets: $e');
    }
  }

  /// Get cached budgets BEFORE Firestore
  Future<List<BudgetModel>?> getCachedBudgets() async {
    try {
      final data = await _storage.readJson(key: 'cached_budgets');
      if (data == null) {
        debugPrint('📭 No cached budgets');
        return null;
      }

      // Check if cache is expired
      final timestamp = data['timestamp'] as int;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _budgetCacheExpiry.inMilliseconds) {
        debugPrint(
            '⏰ Budget cache EXPIRED (${(cacheAge / 86400000).toStringAsFixed(1)} days old)');
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

      debugPrint(
          '✅ LOADED FROM CACHE: ${budgets.length} budgets (${(cacheAge / 3600000).toStringAsFixed(1)}h old)');
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
  // GOALS CACHE (Encrypted & Aggressive)
  // ============================================

  /// Cache goals
  Future<void> cacheGoals(List<GoalModel> goals) async {
    try {
      final data = {
        'goals': goals.map((g) => g.toMap()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'count': goals.length,
      };

      await _storage.writeJson(
        key: 'cached_goals',
        json: data,
      );

      debugPrint('✅ CACHED: ${goals.length} goals (7 day expiry)');
    } catch (e) {
      debugPrint('❌ Error caching goals: $e');
    }
  }

  /// Get cached goals BEFORE Firestore
  Future<List<GoalModel>?> getCachedGoals() async {
    try {
      final data = await _storage.readJson(key: 'cached_goals');
      if (data == null) {
        debugPrint('📭 No cached goals');
        return null;
      }

      // Check if cache is expired
      final timestamp = data['timestamp'] as int;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _goalCacheExpiry.inMilliseconds) {
        debugPrint(
            '⏰ Goal cache EXPIRED (${(cacheAge / 86400000).toStringAsFixed(1)} days old)');
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

      debugPrint(
          '✅ LOADED FROM CACHE: ${goals.length} goals (${(cacheAge / 3600000).toStringAsFixed(1)}h old)');
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
  // USER DATA CACHE
  // ============================================

  /// Cache user data
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

      debugPrint('✅ CACHED: User data (30 day expiry)');
    } catch (e) {
      debugPrint('❌ Error caching user data: $e');
    }
  }

  /// Get cached user data BEFORE Firestore
  Future<Map<String, dynamic>?> getCachedUserData() async {
    try {
      final data = await _storage.readJson(key: 'cached_user_data');
      if (data == null) {
        debugPrint('📭 No cached user data');
        return null;
      }

      // Check if cache is expired
      final timestamp = data['timestamp'] as int;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _userCacheExpiry.inMilliseconds) {
        debugPrint('⏰ User cache EXPIRED');
        await clearUserCache();
        return null;
      }

      debugPrint(
          '✅ LOADED USER DATA FROM CACHE (${(cacheAge / 3600000).toStringAsFixed(1)}h old)');
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
  // BULK CACHE MANAGEMENT
  // ============================================

  /// Clear all caches (manual refresh)
  Future<void> clearAllCaches() async {
    await clearTransactionCache();
    await clearBudgetCache();
    await clearGoalCache();
    await clearUserCache();
    debugPrint('🗑️ ALL CACHES CLEARED - Next load will use Firebase');
  }

  /// Check if ANY cache exists
  Future<bool> hasAnyCachedData() async {
    final transactions = await _storage.containsKey(key: 'cached_transactions');
    final budgets = await _storage.containsKey(key: 'cached_budgets');
    final goals = await _storage.containsKey(key: 'cached_goals');
    final user = await _storage.containsKey(key: 'cached_user_data');

    return transactions || budgets || goals || user;
  }

  /// Force refresh specific data type
  Future<void> invalidateCache(String type) async {
    switch (type) {
      case 'transactions':
        await clearTransactionCache();
        break;
      case 'budgets':
        await clearBudgetCache();
        break;
      case 'goals':
        await clearGoalCache();
        break;
      case 'user':
        await clearUserCache();
        break;
      case 'all':
        await clearAllCaches();
        break;
    }
    debugPrint('🔄 Cache invalidated: $type');
  }
}
