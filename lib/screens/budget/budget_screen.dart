import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/budget_model.dart';
import '../../utils/helpers.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import 'add_budget_screen.dart';
import '../../providers/notification_provider.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  // CRITICAL: Static variable to track if we've EVER checked notifications
  static bool _hasEverCheckedNotifications = false;

  // ✅ Filter state - defaults to current month
  int? _filterMonth;
  int? _filterYear;
  bool _isFilterActive = false;

  @override
  void initState() {
    super.initState();
    // Initialize filter to current month
    final now = DateTime.now();
    _filterMonth = now.month;
    _filterYear = now.year;

    // ONLY check notifications once on very first init for CURRENT MONTH ONLY
    if (!_hasEverCheckedNotifications) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _checkBudgetNotifications(context);
        }
      });
    }
  }

  void _checkBudgetNotifications(BuildContext context) {
    // FIXED: Only check ONCE per app session, never again
    if (_hasEverCheckedNotifications) {
      debugPrint(
          '⏭️ Skipping notification check - already checked this session');
      return;
    }

    debugPrint('🔍 Starting budget notification check...');

    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    final now = DateTime.now();

    for (var budget in budgetProvider.budgets) {
      // ✅ ONLY CHECK CURRENT MONTH BUDGETS
      if (budget.month == now.month && budget.year == now.year) {
        final budgetStart = DateTime(budget.year, budget.month, 1);
        final budgetEnd = DateTime(budget.year, budget.month + 1, 0);

        final budgetCategorySpending = transactionProvider.getCategorySpending(
          budgetStart,
          budgetEnd,
        );

        final spent = budgetCategorySpending[budget.category] ?? 0;

        // Check and create notifications
        notificationProvider.checkAndCreateNotifications(
          spent: spent,
          limit: budget.monthlyLimit,
          category: budget.category,
          threshold: budget.alertThreshold,
          budgetId: budget.id!,
          budgetMonth: budget.month,
          budgetYear: budget.year,
        );
      }
    }

    // Mark as checked FOREVER for this app session
    _hasEverCheckedNotifications = true;
    debugPrint(
        '✅ Budget notifications checked - will NOT check again this session');
  }

  // ✅ Get filtered budgets based on selected month/year
  List<BudgetModel> _getFilteredBudgets(List<BudgetModel> allBudgets) {
    if (_filterMonth == null || _filterYear == null) {
      return allBudgets;
    }

    return allBudgets
        .where((b) => b.month == _filterMonth && b.year == _filterYear)
        .toList();
  }

  // ✅ Check if current filter is for current month
  bool _isCurrentMonthFilter() {
    final now = DateTime.now();
    return _filterMonth == now.month && _filterYear == now.year;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currency = authProvider.selectedCurrency;
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);

    // ✅ Get filtered budgets
    final filteredBudgets = _getFilteredBudgets(budgetProvider.budgets);
    final isCurrentMonth = _isCurrentMonthFilter();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF1F5F9),
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFE0F2FE),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(filteredBudgets.length),
              _buildOverviewCard(
                filteredBudgets,
                transactionProvider,
                currency,
                isCurrentMonth,
              ),
              Expanded(
                child: budgetProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredBudgets.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 80),
                            child: EmptyState(
                              icon: Iconsax.chart_21,
                              title: isCurrentMonth
                                  ? 'No Budgets Set'
                                  : 'No Budgets for This Period',
                              message: isCurrentMonth
                                  ? 'Create your first budget to start tracking spending'
                                  : 'No budgets found for ${_getMonthName(_filterMonth!)} $_filterYear',
                            ),
                          )
                        : _buildBudgetList(
                            filteredBudgets,
                            transactionProvider,
                            currency,
                            isCurrentMonth,
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddBudget,
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Iconsax.add, color: Colors.white),
        label: Text(
          'Add Budget',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int budgetCount) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.displayLarge?.color,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0),
                Text(
                  '$budgetCount ${_isCurrentMonthFilter() ? "budgets this month" : "budgets for ${_getMonthName(_filterMonth!)}"}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ).animate().fadeIn(delay: 200.ms),
              ],
            ),
          ),
          // ✅ NEW: Premium Filter Button
          GestureDetector(
            onTap: _showFilterDialog,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: _isFilterActive ? AppTheme.primaryGradient : null,
                color: _isFilterActive
                    ? null
                    : AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: _isFilterActive
                    ? null
                    : Border.all(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        width: 2,
                      ),
                boxShadow: _isFilterActive
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Iconsax.filter,
                color: _isFilterActive ? Colors.white : AppTheme.primaryGreen,
                size: 24,
              ),
            ),
          ).animate().fadeIn(delay: 300.ms).scale(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
    List<BudgetModel> budgets,
    TransactionProvider transactionProvider,
    String currency,
    bool isCurrentMonth,
  ) {
    // Calculate totals for the filtered month
    final monthStart = DateTime(_filterYear!, _filterMonth!, 1);
    final monthEnd = DateTime(_filterYear!, _filterMonth! + 1, 0);

    final totalBudget =
        budgets.fold<double>(0.0, (sum, b) => sum + b.monthlyLimit);
    final totalSpent =
        transactionProvider.getTotalExpenses(monthStart, monthEnd);
    final remaining = totalBudget - totalSpent;
    final percentUsed =
        totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0.0;
    final isOverBudget = totalSpent > totalBudget;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isOverBudget
            ? const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isOverBudget
                ? Colors.red.withValues(alpha: 0.3)
                : AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isCurrentMonth
                          ? Iconsax.tick_circle
                          : Iconsax.archive_book,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Total Budget',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              // ✅ Premium Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOverBudget
                        ? Colors.red.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.calendar,
                      size: 14,
                      color: isDark
                          ? (isOverBudget
                              ? const Color(0xFFFF6B6B)
                              : const Color(0xFF34D399))
                          : (isOverBudget
                              ? const Color(0xFFEF4444)
                              : AppTheme.primaryGreen),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getMonthName(_filterMonth!),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark
                            ? (isOverBudget
                                ? const Color(0xFFFF6B6B)
                                : const Color(0xFF34D399))
                            : (isOverBudget
                                ? const Color(0xFFEF4444)
                                : AppTheme.primaryGreen),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            Helpers.formatCurrency(totalBudget, currency),
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          // ✅ Show status message for non-current months
          if (!isCurrentMonth) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getStatusMessage(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (percentUsed / 100).clamp(0, 1),
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget ? Colors.white : Colors.white,
              ),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Spent',
                  totalSpent,
                  Iconsax.arrow_up_3,
                  isOverBudget: isOverBudget,
                  currency: currency,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  isOverBudget ? 'Over Budget' : 'Remaining',
                  remaining.abs(),
                  isOverBudget ? Iconsax.danger : Iconsax.wallet,
                  isOverBudget: isOverBudget,
                  showNegative: isOverBudget,
                  currency: currency,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Used',
                  percentUsed.toDouble(),
                  Iconsax.percentage_circle,
                  isOverBudget: isOverBudget,
                  isPercent: true,
                  currency: currency,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildStatItem(
    String label,
    double value,
    IconData icon, {
    bool isPercent = false,
    bool isOverBudget = false,
    bool showNegative = false,
    required String currency,
    required bool isDark,
  }) {
    late Color iconBgColor;
    late Color iconColor;
    late Color valueColor;
    late Color labelColor;

    if (label == 'Spent') {
      iconBgColor = isDark
          ? const Color(0xFFEF4444).withValues(alpha: 0.25)
          : const Color(0xFFEF4444).withValues(alpha: 0.1);
      iconColor = isDark ? const Color(0xFFFF6B6B) : const Color(0xFFEF4444);
      valueColor = isDark ? const Color(0xFFFF6B6B) : const Color(0xFFEF4444);
      labelColor = isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade600;
    } else if (label == 'Over Budget' || label == 'Remaining') {
      if (isOverBudget) {
        iconBgColor = isDark
            ? const Color(0xFFEF4444).withValues(alpha: 0.25)
            : const Color(0xFFEF4444).withValues(alpha: 0.1);
        iconColor = isDark ? const Color(0xFFFF6B6B) : const Color(0xFFEF4444);
        valueColor = isDark ? const Color(0xFFFF6B6B) : const Color(0xFFEF4444);
        labelColor = isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade600;
      } else {
        iconBgColor = isDark
            ? const Color(0xFF3B82F6).withValues(alpha: 0.25)
            : const Color(0xFF3B82F6).withValues(alpha: 0.1);
        iconColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6);
        valueColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6);
        labelColor = isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade600;
      }
    } else {
      iconBgColor = isDark
          ? const Color(0xFF8B5CF6).withValues(alpha: 0.25)
          : const Color(0xFF8B5CF6).withValues(alpha: 0.1);
      iconColor = isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6);
      valueColor = isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6);
      labelColor = isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade600;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              isPercent
                  ? '${value.toStringAsFixed(0)}%'
                  : '${showNegative ? '-' : ''}${Helpers.formatCurrency(value, currency)}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: labelColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetList(
    List<BudgetModel> budgets,
    TransactionProvider transactionProvider,
    String currency,
    bool isCurrentMonth,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: budgets.length,
      itemBuilder: (context, index) {
        final budget = budgets[index];
        final budgetStart = DateTime(budget.year, budget.month, 1);
        final budgetEnd = DateTime(budget.year, budget.month + 1, 0);
        final budgetCategorySpending =
            transactionProvider.getCategorySpending(budgetStart, budgetEnd);
        final spent = budgetCategorySpending[budget.category] ?? 0;

        return _buildBudgetCard(budget, spent, index, currency, isCurrentMonth)
            .animate()
            .fadeIn(delay: (100 * index).ms)
            .slideX(begin: -0.2, end: 0);
      },
    );
  }

  Widget _buildBudgetCard(
    BudgetModel budget,
    double spent,
    int index,
    String currency,
    bool isCurrentMonth,
  ) {
    final percentageUsed = (spent / budget.monthlyLimit * 100);
    final progress = percentageUsed.clamp(0, 100);
    final remaining = budget.monthlyLimit - spent;
    final isOverBudget = spent > budget.monthlyLimit;
    final isNearLimit = progress >= budget.alertThreshold;

    return Dismissible(
      key: Key(budget.id ?? ''),
      background: _buildDismissBackground(
          Alignment.centerLeft, Colors.blue, Iconsax.edit),
      secondaryBackground: _buildDismissBackground(
          Alignment.centerRight, Colors.red, Iconsax.trash),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await _showDeleteConfirmation(budget);
        } else {
          _navigateToEditBudget(budget);
          return false;
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOverBudget
                ? Colors.red.withValues(alpha: 0.3)
                : isNearLimit
                    ? Colors.orange.withValues(alpha: 0.3)
                    : Helpers.getCategoryColor(budget.category)
                        .withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Helpers.getCategoryColor(budget.category)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(budget.category),
                    color: Helpers.getCategoryColor(budget.category),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        budget.category,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        budget.monthYearString,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOverBudget)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.danger, color: Colors.red, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Over',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isNearLimit && isCurrentMonth)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.warning_2,
                            color: Colors.orange, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Near',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Spent',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          Helpers.formatCurrency(spent, currency),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isOverBudget
                                ? Colors.red
                                : AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Limit',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          Helpers.formatCurrency(budget.monthlyLimit, currency),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isOverBudget ? 'Over' : 'Left',
                        style:
                            GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${isOverBudget ? '-' : ''}${Helpers.formatCurrency(remaining.abs(), currency)}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isOverBudget
                                ? Colors.red
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (progress / 100).clamp(0, 1),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget
                      ? Colors.red
                      : isNearLimit
                          ? Colors.orange
                          : AppTheme.primaryGreen,
                ),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${percentageUsed.toStringAsFixed(1)}% used',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isOverBudget
                        ? Colors.red
                        : isNearLimit
                            ? Colors.orange
                            : AppTheme.primaryGreen,
                  ),
                ),
                Text(
                  'Alert at ${budget.alertThreshold}%',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissBackground(
      Alignment alignment, Color color, IconData icon) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }

  IconData _getCategoryIcon(String category) {
    const icons = {
      'Food': Iconsax.shop,
      'Transport': Iconsax.car,
      'Shopping': Iconsax.bag,
      'Entertainment': Iconsax.video_play,
      'Health': Iconsax.heart,
      'Education': Iconsax.book,
      'Utilities': Iconsax.lamp_charge,
      'Rent': Iconsax.home,
      'Groceries': Iconsax.shopping_cart,
    };
    return icons[category] ?? Iconsax.category;
  }

  Future<bool> _showDeleteConfirmation(BudgetModel budget) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Delete Budget',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: Text(
              'Are you sure you want to delete the budget for "${budget.category}" (${budget.monthYearString})?',
              style: GoogleFonts.inter(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: GoogleFonts.inter()),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context, true);
                  await Provider.of<BudgetProvider>(context, listen: false)
                      .deleteBudget(budget.id!);
                  if (mounted) {
                    Helpers.showSnackBar(context, 'Budget deleted');
                  }
                },
                child:
                    Text('Delete', style: GoogleFonts.inter(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _navigateToAddBudget() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddBudgetScreen()),
    );
  }

  void _navigateToEditBudget(BudgetModel budget) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddBudgetScreen(budget: budget)),
    );
  }

  // ✅ NEW: Show premium filter dialog
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(
        currentMonth: _filterMonth!,
        currentYear: _filterYear!,
        onApply: (month, year) {
          setState(() {
            _filterMonth = month;
            _filterYear = year;
            final now = DateTime.now();
            _isFilterActive = !(month == now.month && year == now.year);
          });
        },
        onReset: () {
          final now = DateTime.now();
          setState(() {
            _filterMonth = now.month;
            _filterYear = now.year;
            _isFilterActive = false;
          });
        },
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  String _getStatusMessage() {
    final now = DateTime.now();
    final budgetDate = DateTime(_filterYear!, _filterMonth!);
    final currentDate = DateTime(now.year, now.month);

    if (budgetDate.isBefore(currentDate)) {
      return '❌ Expired - Not Active';
    } else if (budgetDate.isAfter(currentDate)) {
      return '⏰ Future - Not Active';
    }
    return '✅ Active';
  }
}

// ✅ Premium Filter Sheet Widget
class _FilterSheet extends StatefulWidget {
  final int currentMonth;
  final int currentYear;
  final Function(int month, int year) onApply;
  final VoidCallback onReset;

  const _FilterSheet({
    required this.currentMonth,
    required this.currentYear,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late int _tempMonth;
  late int _tempYear;

  @override
  void initState() {
    super.initState();
    _tempMonth = widget.currentMonth;
    _tempYear = widget.currentYear;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = _tempMonth == now.month && _tempYear == now.year;
    final isFuture =
        DateTime(_tempYear, _tempMonth).isAfter(DateTime(now.year, now.month));
    final isPast =
        DateTime(_tempYear, _tempMonth).isBefore(DateTime(now.year, now.month));

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Iconsax.filter,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Filter Budget',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (!isCurrentMonth)
                  TextButton(
                    onPressed: () {
                      widget.onReset();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Reset',
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Status Indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCurrentMonth
                        ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                        : isFuture
                            ? Colors.blue.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrentMonth
                          ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                          : isFuture
                              ? Colors.blue.withValues(alpha: 0.3)
                              : Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCurrentMonth
                            ? Iconsax.tick_circle
                            : isFuture
                                ? Iconsax.clock
                                : Iconsax.archive_book,
                        color: isCurrentMonth
                            ? AppTheme.primaryGreen
                            : isFuture
                                ? Colors.blue
                                : Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCurrentMonth
                                  ? '✅ Active Budget'
                                  : isFuture
                                      ? '⏰ Future Budget'
                                      : '❌ Expired Budget',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isCurrentMonth
                                    ? AppTheme.primaryGreen
                                    : isFuture
                                        ? Colors.blue
                                        : Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isCurrentMonth
                                  ? 'This budget is currently active'
                                  : isFuture
                                      ? 'This budget will activate in the future'
                                      : 'This budget has expired',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Select Year',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildYearSelector(),
                const SizedBox(height: 24),
                Text(
                  'Select Month',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMonthSelector(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_tempMonth, _tempYear);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Apply Filter',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (index) => currentYear + index);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: years.map((year) {
        final isSelected = year == _tempYear;
        return GestureDetector(
          onTap: () => setState(() => _tempYear = year),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected ? AppTheme.primaryGradient : null,
              color: isSelected ? null : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$year',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthSelector() {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(12, (index) {
        final month = index + 1;
        final isSelected = month == _tempMonth;
        return GestureDetector(
          onTap: () => setState(() => _tempMonth = month),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected ? AppTheme.primaryGradient : null,
              color: isSelected ? null : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              months[index],
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
