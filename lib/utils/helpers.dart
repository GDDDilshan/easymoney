import 'package:intl/intl.dart';

class Helpers {
  // Format currency
  static String formatCurrency(double amount, String currency) {
    final symbol = AppConstants.currencies[currency] ?? '\$';
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  // Format date
  static String formatDate(DateTime date, {String format = 'MMM d, yyyy'}) {
    return DateFormat(format).format(date);
  }

  // Format date time
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy hh:mm a').format(dateTime);
  }

  // Get greeting based on time
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  // Get month name
  static String getMonthName(int month) {
    return DateFormat('MMMM').format(DateTime(2024, month));
  }

  // Calculate percentage
  static double calculatePercentage(double value, double total) {
    if (total == 0) return 0;
    return (value / total) * 100;
  }

  // Get category color
  static Color getCategoryColor(String category) {
    return AppConstants.categoryColors[category] ?? const Color(0xFF6B7280);
  }

  // Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate password
  static String? validatePassword(String password) {
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Show snackbar
  static void showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
