import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/transaction_model.dart';
import '../../utils/helpers.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedType = 'all';
  String _selectedCategory = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currency = authProvider.selectedCurrency;

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
              _buildHeader(currency),
              _buildSearchBar(),
              _buildFilters(),
              _buildTabBar(),
              Expanded(child: _buildTransactionList(currency)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddTransaction(),
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Iconsax.add, color: Colors.white),
        label: Text(
          'Add',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String currency) {
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
                  'Transactions',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.displayLarge?.color,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0),
                Text(
                  'Manage your income and expenses',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ).animate().fadeIn(delay: 200.ms),
              ],
            ),
          ),
          _buildSummaryCard(currency),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String currency) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final income = transactionProvider.getTotalIncome(startOfMonth, endOfMonth);
    final expenses =
        transactionProvider.getTotalExpenses(startOfMonth, endOfMonth);
    final balance = income - expenses;

    final isNegative = balance < 0;
    final cardGradient = isNegative
        ? const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFF97316)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : AppTheme.primaryGradient;

    return Container(
      constraints: const BoxConstraints(
        minWidth: 110,
        maxWidth: 140,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isNegative
                ? Colors.red.withValues(alpha: 0.3)
                : AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isNegative ? Iconsax.danger : Iconsax.tick_circle,
                color: Colors.white,
                size: 12,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'This Month',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${isNegative ? '-' : ''}${Helpers.formatCurrency(balance.abs(), currency)}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
            ),
          ),
          if (isNegative)
            Text(
              'Deficit',
              style: GoogleFonts.inter(
                fontSize: 8,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).scale(delay: 300.ms);
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search transactions...',
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey,
            ),
            prefixIcon: const Icon(Iconsax.search_normal_1, color: Colors.grey),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Iconsax.close_circle, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
          style: GoogleFonts.inter(fontSize: 14),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildFilters() {
    final hasActiveFilters =
        _selectedCategory != 'all' || _startDate != null || _endDate != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip(
              'All',
              _selectedType == 'all',
              () => setState(() => _selectedType = 'all'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterChip(
              'Income',
              _selectedType == 'income',
              () => setState(() => _selectedType = 'income'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterChip(
              'Expense',
              _selectedType == 'expense',
              () => setState(() => _selectedType = 'expense'),
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            children: [
              IconButton(
                onPressed: _showFilterDialog,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient:
                        hasActiveFilters ? AppTheme.primaryGradient : null,
                    color: hasActiveFilters
                        ? null
                        : AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: hasActiveFilters
                        ? [
                            BoxShadow(
                              color:
                                  AppTheme.primaryGreen.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Iconsax.filter,
                    color:
                        hasActiveFilters ? Colors.white : AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
              ),
              if (hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .scale(
                          duration: 1000.ms,
                          begin: const Offset(1, 1),
                          end: const Offset(1.2, 1.2))
                      .then()
                      .scale(
                          duration: 1000.ms,
                          begin: const Offset(1.2, 1.2),
                          end: const Offset(1, 1)),
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (index) {
          setState(() {
            _startDate = null;
            _endDate = null;
          });
        },
        indicator: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Today'),
          Tab(text: 'This Week'),
          Tab(text: 'This Month'),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildTransactionList(String currency) {
    final transactionProvider = Provider.of<TransactionProvider>(context);

    if (transactionProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    var transactions = _getFilteredTransactions(transactionProvider);

    if (transactions.isEmpty) {
      return EmptyState(
        icon: Iconsax.empty_wallet,
        title: 'No Transactions',
        message:
            'Start tracking your finances by adding your first transaction',
        actionText: 'Add Transaction',
        onAction: _navigateToAddTransaction,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionItem(transaction, index, currency)
            .animate()
            .fadeIn(delay: (100 * index).ms)
            .slideX(begin: -0.2, end: 0);
      },
    );
  }

  Widget _buildTransactionItem(
      TransactionModel transaction, int index, String currency) {
    final isIncome = transaction.type == 'income';

    return Dismissible(
      key: Key(transaction.id ?? ''),
      background: _buildDismissBackground(
          Alignment.centerLeft, Colors.blue, Iconsax.edit),
      secondaryBackground: _buildDismissBackground(
          Alignment.centerRight, Colors.red, Iconsax.trash),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await _showDeleteConfirmation(transaction);
        } else {
          _navigateToEditTransaction(transaction);
          return false;
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: isIncome
                        ? AppTheme.incomeGradient
                        : AppTheme.expenseGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isIncome ? Iconsax.arrow_down_1 : Iconsax.arrow_up_3,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  Helpers.getCategoryColor(transaction.category)
                                      .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              transaction.category,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Helpers.getCategoryColor(
                                    transaction.category),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Iconsax.calendar,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            _getSmartDateFormat(transaction.date),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'}${Helpers.formatCurrency(transaction.amount, currency)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isIncome
                            ? AppTheme.incomeColor
                            : AppTheme.expenseColor,
                      ),
                    ),
                    Text(
                      Helpers.formatDate(transaction.date, format: 'hh:mm a'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (transaction.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: transaction.tags.map((tag) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.tag,
                          size: 10,
                          color: AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tag,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Iconsax.note,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        transaction.notes!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }

  List<TransactionModel> _getFilteredTransactions(
      TransactionProvider provider) {
    var transactions = provider.transactions;

    if (_searchController.text.isNotEmpty) {
      transactions = transactions
          .where((t) =>
              t.description
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()) ||
              t.category
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()))
          .toList();
    }

    if (_selectedType != 'all') {
      transactions =
          transactions.where((t) => t.type == _selectedType).toList();
    }

    if (_selectedCategory != 'all') {
      transactions =
          transactions.where((t) => t.category == _selectedCategory).toList();
    }

    if (_startDate != null && _endDate != null) {
      transactions = transactions
          .where((t) =>
              t.date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
              t.date.isBefore(_endDate!.add(const Duration(days: 1))))
          .toList();
    } else {
      final now = DateTime.now();
      switch (_tabController.index) {
        case 0:
          break;
        case 1:
          transactions = transactions
              .where((t) =>
                  t.date.year == now.year &&
                  t.date.month == now.month &&
                  t.date.day == now.day)
              .toList();
          break;
        case 2:
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          transactions = transactions
              .where((t) =>
                  t.date.isAfter(weekStart.subtract(const Duration(days: 1))))
              .toList();
          break;
        case 3:
          transactions = transactions
              .where(
                  (t) => t.date.year == now.year && t.date.month == now.month)
              .toList();
          break;
      }
    }

    return transactions;
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(
        selectedCategory: _selectedCategory,
        startDate: _startDate,
        endDate: _endDate,
        onApply: (category, start, end) {
          setState(() {
            _selectedCategory = category;
            _startDate = start;
            _endDate = end;
          });
        },
        onReset: () {
          setState(() {
            _selectedCategory = 'all';
            _startDate = null;
            _endDate = null;
          });
        },
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(TransactionModel transaction) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Delete Transaction',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Are you sure you want to delete "${transaction.description}"?',
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
                  await Provider.of<TransactionProvider>(context, listen: false)
                      .deleteTransaction(transaction.id!);
                  if (mounted) {
                    Helpers.showSnackBar(context, 'Transaction deleted');
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

  void _navigateToAddTransaction() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
  }

  void _navigateToEditTransaction(TransactionModel transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(transaction: transaction),
      ),
    );
  }

  String _getSmartDateFormat(DateTime date) {
    final now = DateTime.now();
    final currentYear = now.year;
    final transactionYear = date.year;

    if (transactionYear == currentYear) {
      return Helpers.formatDate(date, format: 'MMM d');
    } else {
      return Helpers.formatDate(date, format: 'MMM d, yyyy');
    }
  }
}

// Filter Sheet Widget (remains the same - no changes needed)
class _FilterSheet extends StatefulWidget {
  final String selectedCategory;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(String category, DateTime? start, DateTime? end) onApply;
  final VoidCallback onReset;

  const _FilterSheet({
    required this.selectedCategory,
    required this.startDate,
    required this.endDate,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _tempSelectedCategory;
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;

  @override
  void initState() {
    super.initState();
    _tempSelectedCategory = widget.selectedCategory;
    _tempStartDate = widget.startDate;
    _tempEndDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                Text(
                  'Filters',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_tempStartDate != null ||
                    _tempEndDate != null ||
                    _tempSelectedCategory != 'all')
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _tempSelectedCategory = 'all';
                        _tempStartDate = null;
                        _tempEndDate = null;
                      });
                    },
                    child: Text(
                      'Clear All',
                      style: GoogleFonts.inter(
                        color: Colors.red,
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
                Text(
                  'Category',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'all',
                    ...AppConstants.expenseCategories,
                    ...AppConstants.incomeCategories
                  ].map((category) => _buildCategoryChip(category)).toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Date Range',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateButton(
                        'Start Date',
                        _tempStartDate,
                        true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateButton(
                        'End Date',
                        _tempEndDate,
                        false,
                      ),
                    ),
                  ],
                ),
                if (_tempStartDate != null || _tempEndDate != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.info_circle,
                          color: AppTheme.primaryGreen,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _tempStartDate != null && _tempEndDate != null
                                ? 'From ${Helpers.formatDate(_tempStartDate!)} to ${Helpers.formatDate(_tempEndDate!)}'
                                : _tempStartDate != null
                                    ? 'From ${Helpers.formatDate(_tempStartDate!)}'
                                    : 'Until ${Helpers.formatDate(_tempEndDate!)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onReset();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      side: const BorderSide(
                          color: AppTheme.primaryGreen, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(
                        _tempSelectedCategory,
                        _tempStartDate,
                        _tempEndDate,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Apply',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _tempSelectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _tempSelectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          category == 'all' ? 'All Categories' : category,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, bool isStart) {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? now,
          firstDate: DateTime(2000),
          lastDate: now,
        );
        if (picked != null) {
          if (isStart &&
              _tempEndDate != null &&
              picked.isAfter(_tempEndDate!)) {
            Helpers.showSnackBar(
              context,
              'Start date cannot be after end date',
              isError: true,
            );
            return;
          }
          if (!isStart &&
              _tempStartDate != null &&
              picked.isBefore(_tempStartDate!)) {
            Helpers.showSnackBar(
              context,
              'End date cannot be before start date',
              isError: true,
            );
            return;
          }

          setState(() {
            if (isStart) {
              _tempStartDate = picked;
            } else {
              _tempEndDate = picked;
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null ? AppTheme.primaryGreen : Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Iconsax.calendar,
                  size: 16,
                  color: date != null
                      ? AppTheme.primaryGreen
                      : Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              date != null ? Helpers.formatDate(date) : 'Not selected',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: date != null ? null : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
