import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';
import '../screens/budget/budget_screen.dart';
import '../screens/goals/goals_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';

class NotificationPanel extends StatelessWidget {
  const NotificationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          _buildHeader(context),

          // Notifications List
          Expanded(
            child: Consumer<NotificationProvider>(
              builder: (context, notificationProvider, _) {
                if (notificationProvider.notifications.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: notificationProvider.notifications.length,
                  itemBuilder: (context, index) {
                    final notification =
                        notificationProvider.notifications[index];
                    return _buildNotificationItem(
                      context,
                      notification,
                      index,
                      notificationProvider,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Iconsax.notification5,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Consumer<NotificationProvider>(
                    builder: (context, provider, _) {
                      return Text(
                        '${provider.notifications.length} total',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.notifications.isNotEmpty) {
                return TextButton(
                  onPressed: () async {
                    await provider.deleteAllNotifications();
                    if (context.mounted) {
                      Helpers.showSnackBar(
                        context,
                        'All notifications cleared',
                      );
                    }
                  },
                  child: Text(
                    'Clear all',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationModel notification,
    int index,
    NotificationProvider provider,
  ) {
    return Dismissible(
      key: Key(notification.id ?? ''),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFF97316)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Iconsax.trash, color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        provider.deleteNotification(notification.id!);
        Helpers.showSnackBar(context, 'Notification deleted');
      },
      child: GestureDetector(
        onTap: () => _handleNotificationTap(context, notification, provider),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getNotificationColor(notification.type)
                  .withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _getNotificationColor(notification.type)
                    .withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: _getNotificationGradient(notification.type),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _getNotificationColor(notification.type)
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFA1A9B8)
                            : Colors.grey.shade700,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Iconsax.clock,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeago.format(notification.createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: (50 * index).ms)
            .slideX(begin: -0.2, end: 0, delay: (50 * index).ms),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.notification_bing,
              size: 50,
              color: Colors.grey.shade400,
            ),
          ).animate().scale(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 24),
          Text(
            'No Notifications',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey,
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
    NotificationProvider provider,
  ) async {
    // Delete notification immediately (not just mark as read)
    await provider.deleteNotification(notification.id!);

    // Close notification panel
    Navigator.pop(context);

    // Navigate to related screen
    if (notification.relatedScreen != null) {
      switch (notification.relatedScreen) {
        case 'budget':
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const DashboardScreen(initialIndex: 2),
            ),
          );
          break;
        case 'goals':
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const DashboardScreen(initialIndex: 3),
            ),
          );
          break;
      }
    }
  }

  LinearGradient _getNotificationGradient(NotificationType type) {
    switch (type) {
      case NotificationType.budgetWarning:
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
        );
      case NotificationType.budgetExceeded:
        return const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFF97316)],
        );
      case NotificationType.goalCompleted:
        return const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
        );
      case NotificationType.goalNearTarget:
        return const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
        );
      case NotificationType.recurringDue:
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
        );
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.budgetWarning:
        return const Color(0xFFF59E0B);
      case NotificationType.budgetExceeded:
        return const Color(0xFFEF4444);
      case NotificationType.goalCompleted:
        return const Color(0xFF10B981);
      case NotificationType.goalNearTarget:
        return const Color(0xFF3B82F6);
      case NotificationType.recurringDue:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.budgetWarning:
        return Iconsax.warning_2;
      case NotificationType.budgetExceeded:
        return Iconsax.danger;
      case NotificationType.goalCompleted:
        return Iconsax.cup;
      case NotificationType.goalNearTarget:
        return Iconsax.chart_21;
      case NotificationType.recurringDue:
        return Iconsax.clock;
    }
  }
}
