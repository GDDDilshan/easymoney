import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/theme.dart';

class ExportReportScreen extends StatefulWidget {
  const ExportReportScreen({super.key});

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endDate = now;
    _startDate = DateTime(now.year - 1, now.month, now.day);
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                _buildDateRangeSection(),
                _buildSummaryPreview(),
                _buildExportButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.arrow_left),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Generate Report',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: Text(
              'Create a professional financial report for your selected period',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0);
  }

  Widget _buildDateRangeSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
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
        children: [
          Text(
            'Select Report Period',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildDatePickerField(
                  'Start Date',
                  _startDate,
                  true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDatePickerField(
                  'End Date',
                  _endDate,
                  false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildQuickDateButtons(),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildDatePickerField(String label, DateTime? date, bool isStart) {
    return GestureDetector(
      onTap: () => _selectDate(isStart),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Iconsax.calendar, size: 18, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null
                        ? DateFormat('MMM d, yyyy').format(date)
                        : 'Not selected',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: date != null ? null : Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateButtons() {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Select',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickButton('This Month', () {
              setState(() {
                _startDate = DateTime(now.year, now.month, 1);
                _endDate = now;
              });
            }),
            _buildQuickButton('Last 3 Months', () {
              setState(() {
                _startDate = DateTime(now.year, now.month - 3, now.day);
                _endDate = now;
              });
            }),
            _buildQuickButton('This Year', () {
              setState(() {
                _startDate = DateTime(now.year, 1, 1);
                _endDate = now;
              });
            }),
            _buildQuickButton('Last Year', () {
              setState(() {
                _startDate = DateTime(now.year - 1, 1, 1);
                _endDate = DateTime(now.year - 1, 12, 31);
              });
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryGreen,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate ?? now : _endDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && picked.isAfter(_endDate!)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Widget _buildSummaryPreview() {
    if (_startDate == null || _endDate == null) {
      return const SizedBox.shrink();
    }

    final transactionProvider = Provider.of<TransactionProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final goalProvider = Provider.of<GoalProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currency = authProvider.selectedCurrency;

    final income = transactionProvider.getTotalIncome(_startDate!, _endDate!);
    final expenses =
        transactionProvider.getTotalExpenses(_startDate!, _endDate!);
    final balance = income - expenses;

    final transactionCount = transactionProvider.transactions
        .where((t) =>
            t.date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
            t.date.isBefore(_endDate!.add(const Duration(days: 1))))
        .length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
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
        children: [
          Text(
            'Report Summary',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Income',
                  Helpers.formatCurrency(income, currency),
                  Iconsax.arrow_down_1,
                  AppTheme.incomeColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'Total Expenses',
                  Helpers.formatCurrency(expenses, currency),
                  Iconsax.arrow_up_3,
                  AppTheme.expenseColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Net Balance',
                  Helpers.formatCurrency(balance, currency),
                  balance >= 0 ? Iconsax.tick_circle : Iconsax.danger,
                  balance >= 0 ? AppTheme.primaryGreen : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'Transactions',
                  '$transactionCount',
                  Iconsax.document_text,
                  AppTheme.primaryCyan,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
            onPressed: _startDate == null || _endDate == null || _isGenerating
                ? null
                : _generateAndExportReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isGenerating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.export, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Generate & Export PDF',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Future<void> _generateAndExportReport() async {
    if (_startDate == null || _endDate == null) return;

    setState(() => _isGenerating = true);

    try {
      final transactionProvider =
          Provider.of<TransactionProvider>(context, listen: false);
      final budgetProvider =
          Provider.of<BudgetProvider>(context, listen: false);
      final goalProvider = Provider.of<GoalProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final currency = authProvider.selectedCurrency;
      final user = authProvider.userModel;

      final pdf = pw.Document();

      // Generate PDF with all sections - NO DATA LIMITATION
      await _generatePdfReport(
        pdf,
        user?.displayName ?? 'User',
        currency,
        transactionProvider,
        budgetProvider,
        goalProvider,
      );

      // Display print dialog
      await Printing.layoutPdf(
        onLayout: (_) => pdf.save(),
        name:
            'FinancialReport_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
      );

      if (mounted) {
        Helpers.showSnackBar(
            context, 'Report generated and exported successfully');
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Error generating report: $e',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _generatePdfReport(
    pw.Document pdf,
    String userName,
    String currency,
    TransactionProvider transactionProvider,
    BudgetProvider budgetProvider,
    GoalProvider goalProvider,
  ) async {
    final income = transactionProvider.getTotalIncome(_startDate!, _endDate!);
    final expenses =
        transactionProvider.getTotalExpenses(_startDate!, _endDate!);
    final balance = income - expenses;

    final transactions = transactionProvider.transactions
        .where((t) =>
            t.date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
            t.date.isBefore(_endDate!.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final categorySpending =
        transactionProvider.getCategorySpending(_startDate!, _endDate!);
    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // PAGE 1: TITLE & SUMMARY
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Financial Report',
              style: pw.TextStyle(
                fontSize: 40,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Period: ${DateFormat('MMM d, yyyy').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}',
              style: pw.TextStyle(
                  fontSize: 14, color: PdfColor.fromHex('#666666')),
            ),
            pw.Text(
              'Generated on: ${DateFormat('MMM d, yyyy • hh:mm a').format(DateTime.now())}',
              style: pw.TextStyle(
                  fontSize: 12, color: PdfColor.fromHex('#999999')),
            ),
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 24),
            pw.Text(
              'Executive Summary',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildPdfSummaryBox('Total Income', income, currency),
                _buildPdfSummaryBox('Total Expenses', expenses, currency),
                _buildPdfSummaryBox('Net Balance', balance, currency),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Text(
              'Savings Rate: ${((balance / income * 100).clamp(0, 100)).toStringAsFixed(1)}%',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );

    // PAGE 2+: ALL TRANSACTIONS (NO LIMITATION - PAGINATED)
    final transactionsPerPage = 30;
    final totalPages = (transactions.length / transactionsPerPage).ceil();

    for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
      final startIndex = pageIndex * transactionsPerPage;
      final endIndex =
          ((pageIndex + 1) * transactionsPerPage).clamp(0, transactions.length);
      final pageTransactions = transactions.sublist(startIndex, endIndex);

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Transaction Details - Page ${pageIndex + 1} of $totalPages',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'Showing transactions ${startIndex + 1} - $endIndex of ${transactions.length}',
                style: pw.TextStyle(
                    fontSize: 10, color: PdfColor.fromHex('#999999')),
              ),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#10B981'),
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Date',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Description',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Category',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Amount',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...pageTransactions.map((tx) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            DateFormat('MMM d').format(tx.date),
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            tx.description.length > 20
                                ? '${tx.description.substring(0, 20)}...'
                                : tx.description,
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            tx.category,
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            '${Helpers.getCurrencySymbol(currency)}${tx.amount.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // PAGE N: CATEGORY BREAKDOWN
    if (sortedCategories.isNotEmpty)
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Spending by Category',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#10B981'),
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Category',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Amount',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Percentage',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...sortedCategories.map((entry) {
                    final percent = (entry.value / expenses * 100);
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            entry.key,
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${Helpers.getCurrencySymbol(currency)}${entry.value.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${percent.toStringAsFixed(1)}%',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ],
          ),
        ),
      );

    // PAGE N+1: BUDGETS & GOALS
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Budgets Overview',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 16),
            if (budgetProvider.budgets.isEmpty)
              pw.Text(
                'No budgets created for this period',
                style: pw.TextStyle(color: PdfColor.fromHex('#999999')),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.5),
                  1: const pw.FlexColumnWidth(1.2),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#10B981'),
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Category',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Budget Limit',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Spent',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Status',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...budgetProvider.budgets.map((budget) {
                    final budgetCategorySpending =
                        categorySpending[budget.category] ?? 0;
                    final isOverBudget =
                        budgetCategorySpending > budget.monthlyLimit;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            budget.category,
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${Helpers.getCurrencySymbol(currency)}${budget.monthlyLimit.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${Helpers.getCurrencySymbol(currency)}${budgetCategorySpending.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            isOverBudget ? 'Over Budget' : 'On Track',
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            pw.SizedBox(height: 32),
            pw.Text(
              'Savings Goals Progress',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 16),
            if (goalProvider.goals.isEmpty)
              pw.Text(
                'No savings goals created',
                style: pw.TextStyle(color: PdfColor.fromHex('#999999')),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.5),
                  1: const pw.FlexColumnWidth(1.2),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(0.8),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#10B981'),
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Goal Name',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Target',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Current',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Progress',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...goalProvider.goals.map((goal) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            goal.name.length > 15
                                ? '${goal.name.substring(0, 15)}...'
                                : goal.name,
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${Helpers.getCurrencySymbol(currency)}${goal.targetAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${Helpers.getCurrencySymbol(currency)}${goal.currentAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${goal.progress.toStringAsFixed(1)}%',
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
          ],
        ),
      ),
    );

    // PAGE N+2: FINANCIAL INSIGHTS
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Financial Insights',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Period Analysis',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Bullet(
              text:
                  'Report Period: ${DateFormat('MMMM d, yyyy').format(_startDate!)} to ${DateFormat('MMMM d, yyyy').format(_endDate!)} (${_endDate!.difference(_startDate!).inDays} days)',
            ),
            pw.Bullet(
              text: 'Total Transactions: ${transactions.length}',
            ),
            pw.Bullet(
              text: 'Total Income: ${Helpers.formatCurrency(income, currency)}',
            ),
            pw.Bullet(
              text:
                  'Total Expenses: ${Helpers.formatCurrency(expenses, currency)}',
            ),
            pw.Bullet(
              text: 'Net Balance: ${Helpers.formatCurrency(balance, currency)}',
            ),
            pw.Bullet(
              text:
                  'Average Daily Spending: ${Helpers.formatCurrency(expenses / (_endDate!.difference(_startDate!).inDays + 1), currency)}',
            ),
            pw.Bullet(
              text:
                  'Savings Rate: ${((balance / income * 100).clamp(0, 100)).toStringAsFixed(1)}%',
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Top Spending Categories',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            ...List.generate(
              sortedCategories.take(5).length,
              (index) {
                final entry = sortedCategories.toList()[index];
                final percent = (entry.value / expenses * 100);
                return pw.Bullet(
                  text:
                      '${index + 1}. ${entry.key}: ${Helpers.formatCurrency(entry.value, currency)} (${percent.toStringAsFixed(1)}%)',
                );
              },
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Summary',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    balance > 0
                        ? 'Great job! You achieved a positive balance of ${Helpers.formatCurrency(balance, currency)} during this period.'
                        : 'Your expenses exceeded income by ${Helpers.formatCurrency(balance.abs(), currency)}. Consider adjusting your spending habits.',
                    style: pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // PAGE N+3: FOOTER
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'End of Report',
                  style: pw.TextStyle(
                      fontSize: 28, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'This report was generated by Easy Money Manager - Your Smart Finance Manager',
                  style: pw.TextStyle(
                      fontSize: 12, color: PdfColor.fromHex('#666666')),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'For user: $userName',
                  style: pw.TextStyle(
                      fontSize: 11, color: PdfColor.fromHex('#999999')),
                ),
                pw.Text(
                  'Generated: ${DateFormat('MMMM d, yyyy • hh:mm a').format(DateTime.now())}',
                  style: pw.TextStyle(
                      fontSize: 11, color: PdfColor.fromHex('#999999')),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Keep track of your finances and reach your financial goals!',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColor.fromHex('#999999'),
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildPdfSummaryBox(String label, double value, String currency) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColor.fromHex('#666666'),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          Helpers.formatCurrency(value, currency),
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: value >= 0
                ? PdfColor.fromHex('#10B981')
                : PdfColor.fromHex('#EF4444'),
          ),
        ),
      ],
    );
  }
}
