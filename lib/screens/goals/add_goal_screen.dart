import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/goal_model.dart';
import '../../providers/goal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../providers/notification_provider.dart';

class AddGoalScreen extends StatefulWidget {
  final GoalModel? goal;

  const AddGoalScreen({super.key, this.goal});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();

  DateTime _targetDate = DateTime.now().add(const Duration(days: 365));
  String _selectedColor = '#10B981';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _initializeWithGoal();
    }
  }

  void _initializeWithGoal() {
    final g = widget.goal!;
    _nameController.text = g.name;
    _targetAmountController.text = g.targetAmount.toStringAsFixed(0);
    _currentAmountController.text = g.currentAmount.toStringAsFixed(0);
    _targetDate = g.targetDate;
    _selectedColor = g.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
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
                        _buildGoalNameInput(),
                        const SizedBox(height: 20),
                        _buildAmountInputs(currency),
                        const SizedBox(height: 20),
                        _buildTargetDatePicker(),
                        const SizedBox(height: 20),
                        _buildColorSelector(),
                        const SizedBox(height: 24),
                        _buildProgressPreview(currency),
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
            widget.goal != null ? 'Edit Goal' : 'Create Savings Goal',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0);
  }

  Widget _buildGoalNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goal Name',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          onChanged: (value) {
            setState(() {}); // FIXED: Update preview when name changes
          },
          decoration: InputDecoration(
            hintText: 'e.g., New Car, Vacation, Emergency Fund',
            prefixIcon: const Icon(Iconsax.flag),
            filled: true,
            fillColor: Theme.of(context).cardTheme.color,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter goal name';
            }
            return null;
          },
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildAmountInputs(String currency) {
    final currencySymbol = Helpers.getCurrencySymbol(currency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Amount',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
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
              TextFormField(
                controller: _targetAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                onChanged: (value) {
                  setState(() {}); // FIXED: Update preview when amount changes
                },
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(
                      int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 28, color: Colors.grey.shade400),
                  prefixText: '$currencySymbol ',
                  prefixStyle: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter target amount';
                  }
                  return null;
                },
              ),
              const Divider(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Amount',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _currentAmountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'))
                          ],
                          onChanged: (value) {
                            setState(
                                () {}); // FIXED: Update preview when current amount changes
                          },
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            prefixText: '$currencySymbol ',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter amount';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildTargetDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Date',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _targetDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
            );
            if (picked != null) {
              setState(() => _targetDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Iconsax.calendar,
                      color: AppTheme.primaryGreen),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target by',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        Helpers.formatDate(_targetDate, format: 'MMMM d, yyyy'),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Iconsax.arrow_right_3, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_targetDate.difference(DateTime.now()).inDays} days from now',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goal Color',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AppConstants.goalColors.map((color) {
            final colorHex =
                '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
            final isSelected = _selectedColor == colorHex;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = colorHex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? color : Colors.transparent,
                    width: 4,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Iconsax.tick_circle5,
                        color: Colors.white, size: 28)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildProgressPreview(String currency) {
    final targetAmount = double.tryParse(_targetAmountController.text) ?? 0;
    final currentAmount = double.tryParse(_currentAmountController.text) ?? 0;
    final progress =
        targetAmount > 0 ? (currentAmount / targetAmount * 100) : 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // FIXED: Better background for both light and dark mode
        gradient: isDark
            ? LinearGradient(
                colors: [
                  const Color(0xFF1E293B),
                  const Color(0xFF1E293B).withValues(alpha: 0.95),
                ],
              )
            : null,
        color: isDark
            ? null
            : Color(int.parse(_selectedColor.replaceFirst('#', '0xFF')))
                .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF')))
              .withValues(alpha: isDark ? 0.5 : 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.chart_1,
                color:
                    Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Goal Preview',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(
                      int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _nameController.text.isEmpty
                ? 'Your Goal Name'
                : _nameController.text,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              // FIXED: Much brighter text for dark mode
              color: isDark
                  ? const Color(0xFFF1F5F9) // Almost white
                  : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Helpers.formatCurrency(currentAmount, currency),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(
                      int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
                ),
              ),
              Text(
                Helpers.formatCurrency(targetAmount, currency),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600, // ADDED: Bolder weight
                  // FIXED: Much brighter text for dark mode
                  color: isDark
                      ? const Color(0xFFE2E8F0) // Very light gray - BRIGHTER!
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (progress / 100).clamp(0, 1),
              backgroundColor: isDark
                  ? const Color(0xFF334155) // Dark mode
                  : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${progress.toStringAsFixed(1)}% completed',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildSaveButton() {
    return CustomButton(
      text: widget.goal != null ? 'Update Goal' : 'Create Goal',
      onPressed: _saveGoal,
      isLoading: _isLoading,
      gradient: [
        Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
        Color(int.parse(_selectedColor.replaceFirst('#', '0xFF')))
            .withValues(alpha: 0.7),
      ],
      width: double.infinity,
    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0);
  }

  void _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final goal = GoalModel(
        id: widget.goal?.id,
        name: _nameController.text,
        targetAmount: double.parse(_targetAmountController.text),
        currentAmount: double.parse(_currentAmountController.text),
        targetDate: _targetDate,
        color: _selectedColor,
      );

      final provider = Provider.of<GoalProvider>(context, listen: false);

      if (widget.goal != null) {
        await provider.updateGoal(widget.goal!.id!, goal);
        if (mounted) {
          Helpers.showSnackBar(context, 'Goal updated successfully');
        }
      } else {
        await provider.addGoal(goal);
        if (mounted) {
          Helpers.showSnackBar(context, 'Goal created successfully');
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
