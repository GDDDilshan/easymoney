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
  void _checkBudgetNotifications(BuildContext context) {
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    final now = DateTime.now();

    for (var budget in budgetProvider.budgets) {
      // Only check current month budgets
      if (budget.month == now.month && budget.year == now.year) {
        final budgetStart = DateTime(budget.year, budget.month, 1);
        final budgetEnd = DateTime(budget.year, budget.month + 1, 0);

        final budgetCategorySpending = transactionProvider.getCategorySpending(
          budgetStart,
          budgetEnd,
        );

        final spent = budgetCategorySpending[budget.category] ?? 0;

        // Check and create notifications - WITH MONTH/YEAR PARAMS
        notificationProvider.checkAndCreateNotifications(
          spent: spent,
          limit: budget.monthlyLimit,
          category: budget.category,
          threshold: budget.alertThreshold,
          budgetId: budget.id!,
          budgetMonth: budget.month, // NEW
          budgetYear: budget.year, // NEW
        );
      }
    }
  }

  // REPLACE the existing initState with this:
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBudgetNotifications(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currency = authProvider.selectedCurrency;
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);

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
              _buildHeader(budgetProvider, transactionProvider, currency),
              _buildOverviewCard(budgetProvider, transactionProvider, currency),
              Expanded(
                child: budgetProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : budgetProvider.budgets.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 80),
                            child: EmptyState(
                              icon: Iconsax.chart_21,
                              title: 'No Budgets Set',
                              message:
                                  'Create your first budget to start tracking spending',
                            ),
                          )
                        : _buildBudgetList(
                            budgetProvider, transactionProvider, currency),
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

  Widget _buildHeader(BudgetProvider budgetProvider,
      TransactionProvider transactionProvider, String currency) {
    final now = DateTime.now();
    final currentMonthBudgets = budgetProvider.budgets
        .where((b) => b.month == now.month && b.year == now.year)
        .length;

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
                  '$currentMonthBudgets budgets this month',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ).animate().fadeIn(delay: 200.ms),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Iconsax.chart_21, color: Colors.white),
          ).animate().fadeIn(delay: 300.ms).scale(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(BudgetProvider budgetProvider,
      TransactionProvider transactionProvider, String currency) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final currentMonthBudgets = budgetProvider.budgets
        .where((b) => b.month == now.month && b.year == now.year)
        .toList();

    final totalBudget =
        currentMonthBudgets.fold<double>(0.0, (sum, b) => sum + b.monthlyLimit);

    final totalSpent =
        transactionProvider.getTotalExpenses(startOfMonth, endOfMonth);
    final remaining = totalBudget - totalSpent;
    final percentUsed =
        totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0.0;
    final isOverBudget = totalSpent > totalBudget;

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
              Text(
                'Total Budget',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  Helpers.getMonthName(now.month),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isOverBudget
                        ? const Color(0xFFEF4444)
                        : AppTheme.primaryGreen,
                    fontWeight: FontWeight.w700,
                  ),
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
  }) {
    late Color iconBgColor;
    late Color iconColor;
    late Color valueColor;

    if (label == 'Spent') {
      iconBgColor = const Color(0xFFEF4444).withValues(alpha: 0.1);
      iconColor = const Color(0xFFEF4444);
      valueColor = const Color(0xFFEF4444);
    } else if (label == 'Over Budget' || label == 'Remaining') {
      if (isOverBudget) {
        iconBgColor = const Color(0xFFEF4444).withValues(alpha: 0.1);
        iconColor = const Color(0xFFEF4444);
        valueColor = const Color(0xFFEF4444);
      } else {
        iconBgColor = const Color(0xFF3B82F6).withValues(alpha: 0.1);
        iconColor = const Color(0xFF3B82F6);
        valueColor = const Color(0xFF3B82F6);
      }
    } else {
      iconBgColor = const Color(0xFF8B5CF6).withValues(alpha: 0.1);
      iconColor = const Color(0xFF8B5CF6);
      valueColor = const Color(0xFF8B5CF6);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
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
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetList(BudgetProvider budgetProvider,
      TransactionProvider transactionProvider, String currency) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final sortedBudgets = budgetProvider.budgets.toList()
      ..sort((a, b) {
        if (a.isCurrentMonth && !b.isCurrentMonth) return -1;
        if (!a.isCurrentMonth && b.isCurrentMonth) return 1;

        if (a.isFutureMonth && !b.isFutureMonth) return -1;
        if (!a.isFutureMonth && b.isFutureMonth) return 1;

        final aDate = DateTime(a.year, a.month);
        final bDate = DateTime(b.year, b.month);
        return aDate.compareTo(bDate);
      });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: sortedBudgets.length,
      itemBuilder: (context, index) {
        final budget = sortedBudgets[index];

        final budgetStart = DateTime(budget.year, budget.month, 1);
        final budgetEnd = DateTime(budget.year, budget.month + 1, 0);
        final budgetCategorySpending =
            transactionProvider.getCategorySpending(budgetStart, budgetEnd);
        final spent = budgetCategorySpending[budget.category] ?? 0;

        return _buildBudgetCard(budget, spent, index, currency)
            .animate()
            .fadeIn(delay: (100 * index).ms)
            .slideX(begin: -0.2, end: 0);
      },
    );
  }

  Widget _buildBudgetCard(
      BudgetModel budget, double spent, int index, String currency) {
    final percentageUsed = (spent / budget.monthlyLimit * 100);
    final progress = percentageUsed.clamp(0, 100);
    final remaining = budget.monthlyLimit - spent;
    final isOverBudget = spent > budget.monthlyLimit;
    final isNearLimit = progress >= budget.alertThreshold;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (budget.isCurrentMonth) {
      statusColor = AppTheme.primaryGreen;
      statusLabel = 'Current';
      statusIcon = Iconsax.tick_circle;
    } else if (budget.isFutureMonth) {
      statusColor = Colors.blue;
      statusLabel = 'Future';
      statusIcon = Iconsax.clock;
    } else {
      statusColor = Colors.orange;
      statusLabel = 'Past';
      statusIcon = Iconsax.archive_book;
    }

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
                    : statusColor.withValues(alpha: 0.2),
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
                      Row(
                        children: [
                          Icon(
                            Iconsax.calendar,
                            size: 12,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            budget.monthYearString,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusLabel,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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
                else if (isNearLimit)
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
                      Text(
                        'Spent',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
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
                      Text(
                        'Limit',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
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
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
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
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
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
            title: Text(
              'Delete Budget',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
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
                child: Text(
                  'Delete',
                  style: GoogleFonts.inter(color: Colors.red),
                ),
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
}
