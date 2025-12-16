class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: const Center(
        child: Text('Analytics Screen - Coming Soon'),
      ),
    );
  }
}
