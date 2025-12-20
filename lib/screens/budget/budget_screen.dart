import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/budget_model.dart';
import '../../utils/helpers.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import 'add_budget_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  Widget build(BuildContext context) {
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
              _buildHeader(budgetProvider, transactionProvider),
              _buildOverviewCard(budgetProvider, transactionProvider),
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
                        : _buildBudgetList(budgetProvider, transactionProvider),
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

  Widget _buildHeader(
      BudgetProvider budgetProvider, TransactionProvider transactionProvider) {
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
                  '${budgetProvider.budgets.length} budgets created',
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

  Widget _buildOverviewCard(
      BudgetProvider budgetProvider, TransactionProvider transactionProvider) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final totalBudget = budgetProvider.getTotalBudget();
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  Helpers.getMonthName(now.month),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            Helpers.formatCurrency(totalBudget, 'USD'),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Spent',
                  totalSpent,
                  Iconsax.arrow_up_3,
                  isOverBudget: isOverBudget,
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
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              isPercent
                  ? '${value.toStringAsFixed(0)}%'
                  : '${showNegative ? '-' : ''}${Helpers.formatCurrency(value, 'USD')}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetList(
      BudgetProvider budgetProvider, TransactionProvider transactionProvider) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final categorySpending =
        transactionProvider.getCategorySpending(startOfMonth, endOfMonth);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: budgetProvider.budgets.length,
      itemBuilder: (context, index) {
        final budget = budgetProvider.budgets[index];
        final spent = categorySpending[budget.category] ?? 0;
        return _buildBudgetCard(budget, spent, index)
            .animate()
            .fadeIn(delay: (100 * index).ms)
            .slideX(begin: -0.2, end: 0);
      },
    );
  }

  Widget _buildBudgetCard(BudgetModel budget, double spent, int index) {
    final percentageUsed = (spent / budget.monthlyLimit * 100);
    final progress =
        percentageUsed.clamp(0, 100); // For progress bar (clamped to 100%)
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
                    : Colors.transparent,
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
                        'Limit: ${Helpers.formatCurrency(budget.monthlyLimit, 'USD')}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey,
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
                          Helpers.formatCurrency(spent, 'USD'),
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
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isOverBudget ? 'Over Budget' : 'Remaining',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${isOverBudget ? '-' : ''}${Helpers.formatCurrency(remaining.abs(), 'USD')}',
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
              'Are you sure you want to delete the budget for "${budget.category}"?',
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
