import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

class CategoryExpensesChart extends StatefulWidget {
  const CategoryExpensesChart({super.key});

  @override
  State<CategoryExpensesChart> createState() => _CategoryExpensesChartState();
}

class _CategoryExpensesChartState extends State<CategoryExpensesChart> {
  late DateTime _startDate;
  late DateTime _endDate;
  int _selectedPeriod = 0; // 0: 30 days, 1: 3 months, 2: 6 months, 3: Custom

  @override
  void initState() {
    super.initState();
    _initializeDates();
  }

  void _initializeDates() {
    final now = DateTime.now();
    _endDate = now;
    _startDate = now.subtract(const Duration(days: 30));
  }

  void _updatePeriod(int period) {
    final now = DateTime.now();
    setState(() {
      _selectedPeriod = period;
      _endDate = now;
      switch (period) {
        case 0: // 30 days
          _startDate = now.subtract(const Duration(days: 30));
          break;
        case 1: // 3 months
          _startDate = DateTime(now.year, now.month - 3, now.day);
          break;
        case 2: // 6 months
          _startDate = DateTime(now.year, now.month - 6, now.day);
          break;
        case 3: // Custom (keep current selection)
          break;
      }
    });
  }

  Future<void> _showCustomDatePicker() async {
    final picked = await showDateRangeDialog(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<DateTimeRange?> showDateRangeDialog({
    required BuildContext context,
    required DateTimeRange initialDateRange,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    return showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.white,
              surface: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E293B)
                  : Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currency = authProvider.selectedCurrency;

    // Get category spending data
    final categorySpending =
        transactionProvider.getCategorySpending(_startDate, _endDate);

    if (categorySpending.isEmpty) {
      return _buildEmptyState();
    }

    final totalExpenses =
        categorySpending.values.fold<double>(0, (sum, value) => sum + value);

    // Sort by amount descending
    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Color mapping for chart
    final chartColors = _getChartColors(sortedCategories.length);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(currency, totalExpenses)
              .animate()
              .fadeIn(delay: 100.ms)
              .slideX(begin: -0.2, end: 0),

          const SizedBox(height: 24),

          // Period Selector
          _buildPeriodSelector()
              .animate()
              .fadeIn(delay: 200.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: 24),

          // Donut Chart
          _buildDonutChart(sortedCategories, chartColors, totalExpenses)
              .animate()
              .fadeIn(delay: 300.ms)
              .scale(delay: 300.ms),

          const SizedBox(height: 28),

          // Category Legend with Details
          _buildCategoryLegend(
                  sortedCategories, chartColors, currency, totalExpenses)
              .animate()
              .fadeIn(delay: 400.ms)
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildHeader(String currency, double totalExpenses) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending by Category',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.displayLarge?.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Last ${_getPeriodLabel()}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            Helpers.formatCurrency(totalExpenses, currency),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildPeriodButton('30 Days', 0),
          const SizedBox(width: 10),
          _buildPeriodButton('3 Months', 1),
          const SizedBox(width: 10),
          _buildPeriodButton('6 Months', 2),
          const SizedBox(width: 10),
          _buildPeriodButton('Custom', 3, onTap: _showCustomDatePicker),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, int index, {VoidCallback? onTap}) {
    final isSelected = _selectedPeriod == index;
    return GestureDetector(
      onTap: onTap ?? () => _updatePeriod(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected
              ? null
              : Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: !isSelected
              ? Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildDonutChart(List<MapEntry<String, double>> sortedCategories,
      List<Color> colors, double totalExpenses) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 65,
                sections: List.generate(
                  sortedCategories.length,
                  (index) {
                    final entry = sortedCategories[index];
                    final percent = (entry.value / totalExpenses * 100);
                    return PieChartSectionData(
                      value: entry.value,
                      title: '${percent.toStringAsFixed(0)}%',
                      color: colors[index % colors.length],
                      radius: 60,
                      titleStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Center text
          Column(
            children: [
              Text(
                'Total Expenses',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                Helpers.formatCurrency(totalExpenses, 'USD'),
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.displayLarge?.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryLegend(
    List<MapEntry<String, double>> sortedCategories,
    List<Color> colors,
    String currency,
    double totalExpenses,
  ) {
    return Column(
      children: [
        // Show top 5 categories or all if less than 5
        ...List.generate(
          sortedCategories.length > 5 ? 5 : sortedCategories.length,
          (index) {
            final entry = sortedCategories[index];
            final percent = (entry.value / totalExpenses * 100);
            return _buildCategoryRow(
              category: entry.key,
              amount: entry.value,
              percentage: percent,
              color: colors[index % colors.length],
              currency: currency,
            );
          },
        ),
        // Show "Others" if there are more than 5 categories
        if (sortedCategories.length > 5) ...[
          const SizedBox(height: 12),
          _buildCategoryRow(
            category: 'Others',
            amount: sortedCategories
                .skip(5)
                .fold<double>(0, (sum, entry) => sum + entry.value),
            percentage: (sortedCategories
                    .skip(5)
                    .fold<double>(0, (sum, entry) => sum + entry.value) /
                totalExpenses *
                100),
            color: Colors.grey.shade400,
            currency: currency,
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryRow({
    required String category,
    required double amount,
    required double percentage,
    required Color color,
    required String currency,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              // Color indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Category name and percentage
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount
              Text(
                Helpers.formatCurrency(amount, currency),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.chart_21,
              size: 50,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Expenses Found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No expenses recorded for the selected period',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 0:
        return '30 Days';
      case 1:
        return '3 Months';
      case 2:
        return '6 Months';
      case 3:
        return '${_startDate.day}/${_startDate.month} - ${_endDate.day}/${_endDate.month}';
      default:
        return '30 Days';
    }
  }

  List<Color> _getChartColors(int count) {
    const colors = [
      Color(0xFFF97316), // Orange
      Color(0xFF3B82F6), // Blue
      Color(0xFF8B5CF6), // Purple
      Color(0xFF10B981), // Green
      Color(0xFFEF4444), // Red
      Color(0xFFEAB308), // Yellow
      Color(0xFF14B8A6), // Teal
      Color(0xFFEC4899), // Pink
      Color(0xFF06B6D4), // Cyan
      Color(0xFF6366F1), // Indigo
    ];

    if (count <= colors.length) {
      return colors.sublist(0, count);
    }

    // Generate additional colors by mixing
    final additionalColors = <Color>[];
    for (int i = colors.length; i < count; i++) {
      final baseColor = colors[i % colors.length];
      additionalColors.add(baseColor.withValues(
        alpha: 0.7 - ((i - colors.length) * 0.05),
      ));
    }

    return [...colors, ...additionalColors];
  }
}
