import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedType = 'expense';
  String _selectedCategory = 'Food';
  String _selectedCurrency = 'USD';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _initializeWithTransaction();
    }
  }

  void _initializeWithTransaction() {
    final t = widget.transaction!;
    _amountController.text = t.amount.toStringAsFixed(2);
    _descriptionController.text = t.description;
    _notesController.text = t.notes ?? ''; // NEW: Initialize notes
    _selectedType = t.type;
    _selectedCategory = t.category;
    _selectedCurrency = t.currency;
    _selectedDate = t.date;
    _selectedTime = TimeOfDay.fromDateTime(t.date);
    _tags = List.from(t.tags);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _tagController.dispose();
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
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTypeSelector(),
                        const SizedBox(height: 24),
                        _buildAmountInput(),
                        const SizedBox(height: 20),
                        _buildDescriptionInput(),
                        const SizedBox(height: 20),
                        _buildCategorySection(),
                        const SizedBox(height: 20),
                        _buildDateTimeSection(),
                        const SizedBox(height: 20),
                        _buildCurrencySelector(),
                        const SizedBox(height: 20),
                        _buildTagsSection(),
                        const SizedBox(height: 20),
                        _buildNotesInput(),
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
            widget.transaction != null ? 'Edit Transaction' : 'Add Transaction',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0);
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
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
      child: Row(
        children: [
          Expanded(
            child: _buildTypeOption('Income', 'income', Iconsax.arrow_down_1),
          ),
          Expanded(
            child: _buildTypeOption('Expense', 'expense', Iconsax.arrow_up_3),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildTypeOption(String label, String value, IconData icon) {
    final isSelected = _selectedType == value;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedType = value;
        // Reset category when type changes
        _selectedCategory = value == 'income'
            ? AppConstants.incomeCategories.first
            : AppConstants.expenseCategories.first;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? (value == 'income'
                  ? AppTheme.incomeGradient
                  : AppTheme.expenseGradient)
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount',
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _selectedType == 'income'
                  ? AppTheme.incomeColor
                  : AppTheme.expenseColor,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: GoogleFonts.poppins(
                fontSize: 32,
                color: Colors.grey.shade400,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 20, top: 12),
                child: Text(
                  AppConstants.currencies[_selectedCurrency] ?? '\$',
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
                return 'Please enter amount';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter valid amount';
              }
              return null;
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildDescriptionInput() {
    return CustomTextField(
      controller: _descriptionController,
      label: 'Description',
      hint: 'Enter transaction description',
      prefixIcon: Iconsax.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter description';
        }
        return null;
      },
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildCategorySection() {
    final categories = _selectedType == 'income'
        ? AppConstants.incomeCategories
        : AppConstants.expenseCategories;

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
          children: categories.map((category) {
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
    ).animate().fadeIn(delay: 500.ms);
  }

  IconData _getCategoryIcon(String category) {
    const icons = {
      'Food': Iconsax.shop,
      'Transport': Iconsax.car,
      'Shopping': Iconsax.bag,
      'Entertainment': Iconsax.video_play,
      'Health': Iconsax.heart,
      'Education': Iconsax.book,
      'Salary': Iconsax.wallet_money,
      'Investment': Iconsax.chart,
      'Gift': Iconsax.gift,
    };
    return icons[category] ?? Iconsax.category;
  }

  Widget _buildDateTimeSection() {
    return Row(
      children: [
        Expanded(
          child: _buildDatePicker(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTimePicker(),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: now,
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Iconsax.calendar, size: 20, color: AppTheme.primaryGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    Helpers.formatDate(_selectedDate),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _selectedTime,
        );
        if (picked != null) {
          setState(() => _selectedTime = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Iconsax.clock, size: 20, color: AppTheme.primaryGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    _selectedTime.format(context),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Currency',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: AppConstants.currencies.keys.map((currency) {
            final isSelected = _selectedCurrency == currency;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedCurrency = currency),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.primaryGradient : null,
                    color:
                        isSelected ? null : Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      currency,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 700.ms);
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: 'Add tag...',
                  hintStyle:
                      GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                  filled: true,
                  fillColor: Theme.of(context).cardTheme.color,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty && !_tags.contains(value)) {
                    setState(() => _tags.add(value));
                    _tagController.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                if (_tagController.text.isNotEmpty &&
                    !_tags.contains(_tagController.text)) {
                  setState(() => _tags.add(_tagController.text));
                  _tagController.clear();
                }
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Iconsax.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '#$tag',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _tags.remove(tag)),
                      child: const Icon(
                        Iconsax.close_circle,
                        size: 16,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    ).animate().fadeIn(delay: 800.ms);
  }

  Widget _buildNotesInput() {
    return CustomTextField(
      controller: _notesController,
      label: 'Notes (Optional)',
      hint: 'Add any additional notes...',
      prefixIcon: Iconsax.note,
      maxLines: 3,
    ).animate().fadeIn(delay: 900.ms);
  }

  Widget _buildSaveButton() {
    return CustomButton(
      text:
          widget.transaction != null ? 'Update Transaction' : 'Add Transaction',
      onPressed: _saveTransaction,
      isLoading: _isLoading,
      gradient: const [AppTheme.primaryGreen, AppTheme.primaryTeal],
      width: double.infinity,
    ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2, end: 0);
  }

  void _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final combinedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final transaction = TransactionModel(
        id: widget.transaction?.id,
        amount: double.parse(_amountController.text),
        type: _selectedType,
        category: _selectedCategory,
        description: _descriptionController.text,
        date: combinedDateTime,
        currency: _selectedCurrency,
        tags: _tags,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(), // NEW: Save notes
      );

      final provider = Provider.of<TransactionProvider>(context, listen: false);

      if (widget.transaction != null) {
        await provider.updateTransaction(widget.transaction!.id!, transaction);
        if (mounted) {
          Helpers.showSnackBar(context, 'Transaction updated successfully');
        }
      } else {
        await provider.addTransaction(transaction);
        if (mounted) {
          Helpers.showSnackBar(context, 'Transaction added successfully');
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
