import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/theme.dart';
import '../../widgets/empty_state.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedPeriod = 0; // 0: Week, 1: Month, 2: Year

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              _buildHeader(),
              _buildPeriodSelector(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildSummaryCards(),
                      const SizedBox(height: 20),
                      _buildCategoryPieChart(),
                      const SizedBox(height: 20),
                      _buildIncomeExpenseTrend(),
                      const SizedBox(height: 20),
                      _buildTopCategories(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.displayLarge?.color,
                ),
              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0),
              Text(
                'Track your spending patterns',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ).animate().fadeIn(delay: 200.ms),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Iconsax.chart_1, color: Colors.white),
          ).animate().fadeIn(delay: 300.ms).scale(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildPeriodOption('Week', 0),
          _buildPeriodOption('Month', 1),
          _buildPeriodOption('Year', 2),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildPeriodOption(String label, int index) {
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.primaryGradient : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final (startDate, endDate) = _getDateRange();

    final income = transactionProvider.getTotalIncome(startDate, endDate);
    final expenses = transactionProvider.getTotalExpenses(startDate, endDate);
    final savings = income - expenses;
    final savingsRate = income > 0 ? (savings / income * 100) : 0;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Income',
            income,
            Iconsax.arrow_down_1,
            AppTheme.incomeColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Expenses',
            expenses,
            Iconsax.arrow_up_3,
            AppTheme.expenseColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Savings',
            savings,
            Iconsax.wallet,
            savings >= 0 ? AppTheme.primaryGreen : Colors.red,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildSummaryCard(
      String title, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Helpers.formatCurrency(amount, 'USD'),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPieChart() {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final (startDate, endDate) = _getDateRange();
    final categorySpending =
        transactionProvider.getCategorySpending(startDate, endDate);

    if (categorySpending.isEmpty) {
      return EmptyState(
        icon: Iconsax.chart_21,
        title: 'No Data',
        message: 'No expenses found for this period',
      );
    }

    final total =
        categorySpending.values.fold(0.0, (sum, value) => sum + value);
    final sortedEntries = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Category',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: sortedEntries.take(5).map((entry) {
                  final percent = (entry.value / total * 100);
                  return PieChartSectionData(
                    value: entry.value,
                    title: '${percent.toStringAsFixed(0)}%',
                    color: Helpers.getCategoryColor(entry.key),
                    radius: 50,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...sortedEntries.take(5).map((entry) {
            final percent = (entry.value / total * 100);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Helpers.getCategoryColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                  ),
                  Text(
                    Helpers.formatCurrency(entry.value, 'USD'),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${percent.toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildIncomeExpenseTrend() {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final (startDate, endDate) = _getDateRange();

    // Generate data points based on selected period
    final dataPoints =
        _generateTrendData(transactionProvider, startDate, endDate);

    if (dataPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Income vs Expense Trend',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 500,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < dataPoints.length) {
                          return Text(
                            dataPoints[value.toInt()]['label'],
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: dataPoints.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value['income']);
                    }).toList(),
                    isCurved: true,
                    color: AppTheme.incomeColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.incomeColor.withOpacity(0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: dataPoints.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value['expense']);
                    }).toList(),
                    isCurved: true,
                    color: AppTheme.expenseColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.expenseColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Income', AppTheme.incomeColor),
              const SizedBox(width: 24),
              _buildLegendItem('Expense', AppTheme.expenseColor),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTopCategories() {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final (startDate, endDate) = _getDateRange();
    final categorySpending =
        transactionProvider.getCategorySpending(startDate, endDate);

    if (categorySpending.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = sortedEntries.first.value;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Spending Categories',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...sortedEntries.take(5).map((entry) {
            final percent = (entry.value / maxValue);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        Helpers.formatCurrency(entry.value, 'USD'),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.expenseColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        Helpers.getCategoryColor(entry.key),
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0);
  }

  (DateTime, DateTime) _getDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 0: // Week
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return (weekStart, now);
      case 1: // Month
        return (DateTime(now.year, now.month, 1), now);
      case 2: // Year
        return (DateTime(now.year, 1, 1), now);
      default:
        return (DateTime(now.year, now.month, 1), now);
    }
  }

  List<Map<String, dynamic>> _generateTrendData(
    TransactionProvider provider,
    DateTime start,
    DateTime end,
  ) {
    final List<Map<String, dynamic>> data = [];

    if (_selectedPeriod == 0) {
      // Week - daily data
      for (int i = 0; i < 7; i++) {
        final date = start.add(Duration(days: i));
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(const Duration(days: 1));

        data.add({
          'label': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
          'income': provider.getTotalIncome(dayStart, dayEnd),
          'expense': provider.getTotalExpenses(dayStart, dayEnd),
        });
      }
    } else if (_selectedPeriod == 1) {
      // Month - weekly data
      for (int i = 0; i < 4; i++) {
        final weekStart = start.add(Duration(days: i * 7));
        final weekEnd = weekStart.add(const Duration(days: 7));

        data.add({
          'label': 'W${i + 1}',
          'income': provider.getTotalIncome(weekStart, weekEnd),
          'expense': provider.getTotalExpenses(weekStart, weekEnd),
        });
      }
    } else {
      // Year - monthly data
      for (int i = 1; i <= 12; i++) {
        final monthStart = DateTime(start.year, i, 1);
        final monthEnd = DateTime(start.year, i + 1, 0);

        data.add({
          'label': [
            'J',
            'F',
            'M',
            'A',
            'M',
            'J',
            'J',
            'A',
            'S',
            'O',
            'N',
            'D'
          ][i - 1],
          'income': provider.getTotalIncome(monthStart, monthEnd),
          'expense': provider.getTotalExpenses(monthStart, monthEnd),
        });
      }
    }

    return data;
  }
}
