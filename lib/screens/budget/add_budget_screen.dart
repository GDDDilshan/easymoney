import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/budget_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class AddBudgetScreen extends StatefulWidget {
  final BudgetModel? budget;

  const AddBudgetScreen({super.key, this.budget});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String _selectedCategory = 'Food';
  int _alertThreshold = 80;
  bool _isLoading = false;
  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;

    if (widget.budget != null) {
      _initializeWithBudget();
    }
  }

  void _initializeWithBudget() {
    final b = widget.budget!;
    _amountController.text = b.monthlyLimit.toStringAsFixed(0);
    _selectedCategory = b.category;
    _alertThreshold = b.alertThreshold;
    _selectedMonth = b.month;
    _selectedYear = b.year;
  }

  @override
  void dispose() {
    _amountController.dispose();
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
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAmountInput(currency),
                        const SizedBox(height: 24),
                        _buildCategorySection(),
                        const SizedBox(height: 24),
                        _buildMonthYearSelector(),
                        const SizedBox(height: 24),
                        _buildAlertThresholdSection(),
                        const SizedBox(height: 24),
                        _buildInfoCard(currency),
                        const SizedBox(height: 32),
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
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
          const SizedBox(width: 16),
          Text(
            widget.budget != null ? 'Edit Budget' : 'Create Budget',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0);
  }

  Widget _buildAmountInput(String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Budget Limit',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
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
          child: TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: GoogleFonts.poppins(
                fontSize: 32,
                color: Colors.grey.shade400,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 20, top: 12),
                child: Text(
                  Helpers.getCurrencySymbol(currency),
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter budget amount';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter valid amount';
              }
              return null;
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          children: AppConstants.expenseCategories.map((category) {
            final isSelected = _selectedCategory == category;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Helpers.getCategoryColor(category)
                          .withValues(alpha: 0.2)
                      : Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Helpers.getCategoryColor(category)
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      size: 18,
                      color: isSelected
                          ? Helpers.getCategoryColor(category)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Helpers.getCategoryColor(category)
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildMonthYearSelector() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Period',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () => _showMonthPicker(),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.calendar_1,
                          size: 20, color: AppTheme.primaryGreen),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Month',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              months[_selectedMonth - 1],
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Iconsax.arrow_down_1, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _showYearPicker(),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Year',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$_selectedYear',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(Iconsax.arrow_down_1,
                              size: 16, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isCurrentMonth()
                ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                : _isFutureMonth()
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _isCurrentMonth()
                    ? Iconsax.tick_circle
                    : _isFutureMonth()
                        ? Iconsax.clock
                        : Iconsax.info_circle,
                size: 16,
                color: _isCurrentMonth()
                    ? AppTheme.primaryGreen
                    : _isFutureMonth()
                        ? Colors.blue
                        : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isCurrentMonth()
                      ? 'This is the current month budget'
                      : _isFutureMonth()
                          ? 'Future budget - will activate in ${months[_selectedMonth - 1]} $_selectedYear'
                          : 'Past budget - for ${months[_selectedMonth - 1]} $_selectedYear',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _isCurrentMonth()
                        ? AppTheme.primaryGreen
                        : _isFutureMonth()
                            ? Colors.blue
                            : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  void _showMonthPicker() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Month',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(12, (index) {
                final month = index + 1;
                final isSelected = month == _selectedMonth;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedMonth = month);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
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
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showYearPicker() {
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (index) => currentYear + index);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Year',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose from $currentYear to ${currentYear + 9}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: years.map((year) {
                final isSelected = year == _selectedYear;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedYear = year);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
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
            ),
          ],
        ),
      ),
    );
  }

  bool _isCurrentMonth() {
    final now = DateTime.now();
    return _selectedMonth == now.month && _selectedYear == now.year;
  }

  bool _isFutureMonth() {
    final now = DateTime.now();
    final selected = DateTime(_selectedYear, _selectedMonth);
    final current = DateTime(now.year, now.month);
    return selected.isAfter(current);
  }

  Widget _buildAlertThresholdSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Alert Threshold',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_alertThreshold%',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Get notified when you reach this percentage of your budget',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
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
            children: [
              Slider(
                value: _alertThreshold.toDouble(),
                min: 50,
                max: 100,
                divisions: 10,
                activeColor: AppTheme.primaryGreen,
                inactiveColor: Colors.grey.shade300,
                onChanged: (value) {
                  setState(() => _alertThreshold = value.toInt());
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '50%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '75%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '100%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildInfoCard(String currency) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final alertAmount = amount * (_alertThreshold / 100);
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // FIXED: Better background colors
        gradient: Theme.of(context).brightness == Brightness.dark
            ? LinearGradient(
                colors: [
                  const Color(0xFF1E293B),
                  const Color(0xFF1E293B).withValues(alpha: 0.95),
                ],
              )
            : null,
        color: Theme.of(context).brightness == Brightness.dark
            ? null
            : AppTheme.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? 0.5 : 0.3,
          ),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.info_circle,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Budget Summary',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Category', _selectedCategory),
          _buildSummaryRow(
              'Period', '${months[_selectedMonth - 1]} $_selectedYear'),
          _buildSummaryRow(
              'Monthly Limit', Helpers.formatCurrency(amount, currency)),
          _buildSummaryRow('Alert When Spent',
              Helpers.formatCurrency(alertAmount, currency)),
          _buildSummaryRow('Alert Threshold', '$_alertThreshold%'),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildSummaryRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              // FIXED: Much lighter text for dark mode
              color: isDark
                  ? const Color(0xFF94A3B8) // Light gray
                  : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              // FIXED: Bright text for dark mode
              color: isDark
                  ? const Color(0xFFF1F5F9) // Almost white
                  : Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return CustomButton(
      text: widget.budget != null ? 'Update Budget' : 'Create Budget',
      onPressed: _saveBudget,
      isLoading: _isLoading,
      gradient: const [AppTheme.primaryGreen, AppTheme.primaryTeal],
      width: double.infinity,
    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0);
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

  void _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final budget = BudgetModel(
        id: widget.budget?.id,
        category: _selectedCategory,
        monthlyLimit: double.parse(_amountController.text),
        alertThreshold: _alertThreshold,
        month: _selectedMonth,
        year: _selectedYear,
      );

      final provider = Provider.of<BudgetProvider>(context, listen: false);

      if (widget.budget != null) {
        await provider.updateBudget(widget.budget!.id!, budget);
        if (mounted) {
          Helpers.showSnackBar(context, 'Budget updated successfully');
        }
      } else {
        await provider.addBudget(budget);
        if (mounted) {
          Helpers.showSnackBar(context, 'Budget created successfully');
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
