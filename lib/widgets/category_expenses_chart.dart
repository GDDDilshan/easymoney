// FIXED VERSION - Default shows CURRENT WEEK (Monday-Sunday), not past 7 days

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/helpers.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class CategoryExpensesChart extends StatefulWidget {
  const CategoryExpensesChart({super.key});

  @override
  State<CategoryExpensesChart> createState() => _CategoryExpensesChartState();
}

class _CategoryExpensesChartState extends State<CategoryExpensesChart> {
  late DateTime _startDate;
  late DateTime _endDate;
  int _selectedPeriod =
      0; // 0: This Week, 1: 30 days, 2: 3 months, 3: 6 months, 4: Custom

  @override
  void initState() {
    super.initState();
    _initializeDates();
  }

  // ✅ FIXED: Initialize to CURRENT WEEK (Monday to Sunday)
  void _initializeDates() {
    final now = DateTime.now();

    // Calculate current week: Monday to Sunday
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday
    final mondayOffset = weekday - 1; // Days since Monday

    // Start of current week (Monday at 00:00:00)
    _startDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: mondayOffset));

    // End of current week (Sunday at 23:59:59)
    final sundayOffset = 7 - weekday; // Days until Sunday
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59)
        .add(Duration(days: sundayOffset));

    debugPrint('📅 Initialized Current Week:');
    debugPrint('   Start (Monday): ${_startDate.toString()}');
    debugPrint('   End (Sunday): ${_endDate.toString()}');
  }

  void _updatePeriod(int period) {
    final now = DateTime.now();
    setState(() {
      _selectedPeriod = period;

      switch (period) {
        case 0: // This Week (Monday to Sunday)
          final weekday = now.weekday;
          final mondayOffset = weekday - 1;
          _startDate = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: mondayOffset));

          final sundayOffset = 7 - weekday;
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59)
              .add(Duration(days: sundayOffset));

          debugPrint('📅 Selected: This Week');
          debugPrint('   Start: ${_startDate.toString()}');
          debugPrint('   End: ${_endDate.toString()}');
          break;

        case 1: // Last 30 days
          _endDate = now;
          _startDate = now.subtract(const Duration(days: 30));
          debugPrint('📅 Selected: Last 30 Days');
          break;

        case 2: // Last 3 months
          _endDate = now;
          _startDate = DateTime(now.year, now.month - 3, now.day);
          debugPrint('📅 Selected: Last 3 Months');
          break;

        case 3: // Last 6 months
          _endDate = now;
          _startDate = DateTime(now.year, now.month - 6, now.day);
          debugPrint('📅 Selected: Last 6 Months');
          break;

        case 4: // Custom (keep current selection)
          debugPrint('📅 Selected: Custom Range');
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
        _selectedPeriod = 4; // Set to custom
      });
    }
  }

  // Calendar with orange theme for dark mode, green for light mode
  Future<DateTimeRange?> showDateRangeDialog({
    required BuildContext context,
    required DateTimeRange initialDateRange,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: const Color(0xFFF97316),
                    onPrimary: const Color(0xFF0F172A),
                    primaryContainer:
                        const Color(0xFFF97316).withValues(alpha: 0.3),
                    onPrimaryContainer: const Color(0xFF0F172A),
                    surface: const Color(0xFF1E293B),
                    onSurface: Colors.white,
                    background: const Color(0xFF0F172A),
                    onBackground: Colors.white,
                    surfaceVariant: const Color(0xFF334155),
                    onSurfaceVariant: Colors.white,
                    secondary: const Color(0xFFFB923C),
                    onSecondary: const Color(0xFF0F172A),
                    outline: const Color(0xFF475569),
                  )
                : ColorScheme.light(
                    primary: AppTheme.primaryGreen,
                    onPrimary: Colors.white,
                    primaryContainer:
                        AppTheme.primaryGreen.withValues(alpha: 0.2),
                    onPrimaryContainer: const Color(0xFF0F172A),
                    surface: Colors.white,
                    onSurface: const Color(0xFF0F172A),
                    background: const Color(0xFFF1F5F9),
                    onBackground: const Color(0xFF0F172A),
                    surfaceVariant: const Color(0xFFF8FAFC),
                    onSurfaceVariant: const Color(0xFF0F172A),
                    secondary: AppTheme.primaryTeal,
                    onSecondary: Colors.white,
                    outline: Colors.grey.shade300,
                  ),
            textTheme: isDark
                ? GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
                    .copyWith(
                    displayLarge: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32),
                    displayMedium: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 28),
                    displaySmall: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24),
                    headlineLarge: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 28),
                    headlineMedium: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 20),
                    headlineSmall: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18),
                    titleLarge: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16),
                    titleMedium: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14),
                    titleSmall: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12),
                    bodyLarge: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                    bodyMedium: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                    bodySmall:
                        GoogleFonts.inter(color: Colors.white, fontSize: 12),
                    labelLarge: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    labelMedium: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12),
                    labelSmall:
                        GoogleFonts.inter(color: Colors.white, fontSize: 10),
                  )
                : GoogleFonts.interTextTheme(ThemeData.light().textTheme)
                    .copyWith(
                    displayLarge: GoogleFonts.poppins(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 32),
                    displayMedium: GoogleFonts.poppins(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 28),
                    displaySmall: GoogleFonts.poppins(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 24),
                    headlineLarge: GoogleFonts.poppins(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 28),
                    headlineMedium: GoogleFonts.poppins(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                        fontSize: 20),
                    headlineSmall: GoogleFonts.poppins(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                        fontSize: 18),
                    titleLarge: GoogleFonts.inter(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                        fontSize: 16),
                    titleMedium: GoogleFonts.inter(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                        fontSize: 14),
                    titleSmall: GoogleFonts.inter(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                        fontSize: 12),
                    bodyLarge: GoogleFonts.inter(
                        color: const Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                    bodyMedium: GoogleFonts.inter(
                        color: const Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                    bodySmall: GoogleFonts.inter(
                        color: const Color(0xFF0F172A), fontSize: 12),
                    labelLarge: GoogleFonts.inter(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    labelMedium: GoogleFonts.inter(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                        fontSize: 12),
                    labelSmall: GoogleFonts.inter(
                        color: const Color(0xFF0F172A), fontSize: 10),
                  ),
            dialogBackgroundColor:
                isDark ? const Color(0xFF1E293B) : Colors.white,
            dividerColor:
                isDark ? const Color(0xFF475569) : Colors.grey.shade300,
            cardTheme: CardThemeData(
                color: isDark ? const Color(0xFF334155) : Colors.white,
                elevation: 0),
            iconTheme: IconThemeData(
                color:
                    isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                size: 24),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor:
                    isDark ? const Color(0xFFF97316) : AppTheme.primaryGreen,
                textStyle: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
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

    final categorySpending =
        transactionProvider.getCategorySpending(_startDate, _endDate);

    if (categorySpending.isEmpty) {
      return _buildEmptyState();
    }

    final totalExpenses =
        categorySpending.values.fold<double>(0, (sum, value) => sum + value);
    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
          _buildHeader(currency, totalExpenses)
              .animate()
              .fadeIn(delay: 100.ms)
              .slideX(begin: -0.2, end: 0),
          const SizedBox(height: 24),
          _buildPeriodSelector()
              .animate()
              .fadeIn(delay: 200.ms)
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: 24),
          _buildDonutChart(sortedCategories, totalExpenses)
              .animate()
              .fadeIn(delay: 300.ms)
              .scale(delay: 300.ms),
          const SizedBox(height: 28),
          _buildCategoryLegend(sortedCategories, currency, totalExpenses)
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
              _getPeriodLabel(),
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
          _buildPeriodButton('This Week', 0),
          const SizedBox(width: 10),
          _buildPeriodButton('30 Days', 1),
          const SizedBox(width: 10),
          _buildPeriodButton('3 Months', 2),
          const SizedBox(width: 10),
          _buildPeriodButton('6 Months', 3),
          const SizedBox(width: 10),
          _buildPeriodButton('Custom', 4, onTap: _showCustomDatePicker),
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
              ? Border.all(color: Colors.grey.shade300, width: 1)
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

  Widget _buildDonutChart(
      List<MapEntry<String, double>> sortedCategories, double totalExpenses) {
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
                    final color = Helpers.getCategoryColor(entry.key);

                    return PieChartSectionData(
                      value: entry.value,
                      title: '${percent.toStringAsFixed(0)}%',
                      color: color,
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
    String currency,
    double totalExpenses,
  ) {
    return Column(
      children: sortedCategories.map((entry) {
        final percent = (entry.value / totalExpenses * 100);
        final color = Helpers.getCategoryColor(entry.key);

        return _buildCategoryRow(
          category: entry.key,
          amount: entry.value,
          percentage: percent,
          color: color,
          currency: currency,
        );
      }).toList(),
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
            'No expenses recorded for ${_getPeriodLabel()}',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 0:
        return 'This Week (${_formatDateShort(_startDate)} - ${_formatDateShort(_endDate)})';
      case 1:
        return 'Last 30 Days';
      case 2:
        return 'Last 3 Months';
      case 3:
        return 'Last 6 Months';
      case 4:
        return 'Custom (${_formatDateShort(_startDate)} - ${_formatDateShort(_endDate)})';
      default:
        return 'This Week';
    }
  }

  String _formatDateShort(DateTime date) {
    return '${date.day}/${date.month}';
  }
}
