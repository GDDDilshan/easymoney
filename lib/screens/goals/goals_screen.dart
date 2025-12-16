class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Goals',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: const Center(
        child: Text('Goals Screen - Coming Soon'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Add goal
        },
        icon: const Icon(Iconsax.add),
        label: const Text('Add Goal'),
      ),
    );
  }
}
