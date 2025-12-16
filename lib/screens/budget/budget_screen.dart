class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Budget',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: const Center(
        child: Text('Budget Screen - Coming Soon'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Add budget
        },
        icon: const Icon(Iconsax.add),
        label: const Text('Add Budget'),
      ),
    );
  }
}
