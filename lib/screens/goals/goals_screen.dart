import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../providers/goal_provider.dart';
import '../../models/goal_model.dart';
import '../../utils/helpers.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import 'add_goal_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalProvider = Provider.of<GoalProvider>(context);

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
              _buildHeader(goalProvider),
              _buildTabBar(),
              Expanded(
                child: goalProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildGoalsList(goalProvider.activeGoals, isActive: true),
                          _buildGoalsList(goalProvider.completedGoals, isActive: false),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddGoal,
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Iconsax.add, color: Colors.white),
        label: Text(
          'Add Goal',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(GoalProvider provider) {
    final totalGoals = provider.goals.length;
    final completedCount = provider.completedGoals.length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Savings Goals',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.displayLarge?.color,
                ),
              )
                  .animate()
                  .fadeIn(delay: 100.ms)
                  .slideX(begin: -0.2, end: 0),
              Text(
                '$completedCount of $totalGoals goals completed',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Iconsax.flag, color: Colors.white, size: 24),
                const SizedBox(height: 4),
                Text(
                  '$totalGoals',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 300.ms)
              .scale(delay: 300.ms),
        ],
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
          Tab(text: 'Active Goals'),
          Tab(text: 'Completed'),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms);
  }

  Widget _buildGoalsList(List<GoalModel> goals, {required bool isActive}) {
    if (goals.isEmpty) {
      return EmptyState(
        icon: Iconsax.flag,
        title: isActive ? 'No Active Goals' : 'No Completed Goals',
        message: isActive
            ? 'Create your first savings goal'
            : 'Complete your goals to see them here',
        actionText: isActive ? 'Create Goal' : null,
        onAction: isActive ? _navigateToAddGoal : null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        return _buildGoalCard(goal, index, isActive)
            .animate()
            .fadeIn(delay: (100 * index).ms)
            .slideX(begin: -0.2, end: 0);
      },
    );
  }

  Widget _buildGoalCard(GoalModel goal, int index, bool isActive) {
    final progress = goal.progress;
    final isCompleted = goal.isCompleted;
    final remaining = goal.targetAmount - goal.currentAmount;
    final daysRemaining = goal.targetDate.difference(DateTime.now()).inDays;

    return Dismissible(
      key: Key(goal.id ?? ''),
      background: _buildDismissBackground(Alignment.centerLeft, Colors.blue, Iconsax.edit),
      secondaryBackground: _buildDismissBackground(Alignment.centerRight, Colors.red, Iconsax.trash),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await _showDeleteConfirmation(goal);
        } else {
          _navigateToEditGoal(goal);
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
            color: Color(int.parse(goal.color.replaceFirst('#', '0xFF'))).withOpacity(0.3),
            width: 2,
          ),
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
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Color(int.parse(goal.color.replaceFirst('#', '0xFF'))).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isCompleted ? Iconsax.tick_circle5 : Iconsax.flag,
                    color: Color(int.parse(goal.color.replaceFirst('#', '0xFF'))),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Target: ${Helpers.formatDate(goal.targetDate)}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.tick_circle, color: AppTheme.primaryGreen, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (daysRemaining < 30 && daysRemaining > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.clock, color: Colors.orange, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$daysRemaining days',
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      Helpers.formatCurrency(goal.currentAmount, 'USD'),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(int.parse(goal.color.replaceFirst('#', '0xFF'))),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Target',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      Helpers.formatCurrency(goal.targetAmount, 'USD'),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
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
                  Color(int.parse(goal.color.replaceFirst('#', '0xFF'))),
                ),
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.toStringAsFixed(1)}% completed',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(int.parse(goal.color.replaceFirst('#', '0xFF'))),
                  ),
                ),
                if (!isCompleted)
                  Text(
                    '${Helpers.formatCurrency(remaining, 'USD')} to go',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            if (!isCompleted) ...[
              const SizedBox(height: 16),
              CustomButton(
                text: 'Add Contribution',
                onPressed: () => _showAddContributionDialog(goal),
                icon: Iconsax.add_circle,
                gradient: [
                  Color(int.parse(goal.color.replaceFirst('#', '0xFF'))),
                  Color(int.parse(goal.color.replaceFirst('#', '0xFF'))).withOpacity(0.7),
                ],
                height: 44,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDismissBackground(Alignment alignment, Color color, IconData icon) {
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

  void _showAddContributionDialog(GoalModel goal) {
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add Contribution',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goal: ${goal.name}',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                await Provider.of<GoalProvider>(context, listen: false)
                    .addContribution(goal.id!, amount);
                if (context.mounted) {
                  Navigator.pop(context);
                  Helpers.showSnackBar(context, 'Contribution added successfully');
                }
              }
            },
            child: Text('Add', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(GoalModel goal) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Goal',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${goal.name}"?',
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
              await Provider.of<GoalProvider>(context, listen: false)
                  .deleteGoal(goal.id!);
              if (mounted) {
                Helpers.showSnackBar(context, 'Goal deleted');
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: Colors.red),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  void _navigateToAddGoal() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddGoalScreen()),
    );
  }

  void _navigateToEditGoal(GoalModel goal) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddGoalScreen(goal: goal)),
    );
  }
}