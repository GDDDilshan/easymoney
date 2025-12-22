import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/notification_provider.dart';
import '../utils/theme.dart';
import 'notification_panel.dart';

class NotificationBell extends StatelessWidget {
  final VoidCallback? onNavigateToBudget; // NEW: Callback for navigation

  const NotificationBell({
    super.key,
    this.onNavigateToBudget,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        final hasUnread = notificationProvider.hasUnread;
        final unreadCount = notificationProvider.unreadCount;

        return GestureDetector(
          onTap: () => _showNotificationPanel(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Bell Icon with Premium Animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasUnread ? Iconsax.notification5 : Iconsax.notification,
                  color: hasUnread
                      ? AppTheme.primaryGreen
                      : Theme.of(context).iconTheme.color,
                  size: 24,
                ),
              )
                  .animate(
                    onPlay: (controller) =>
                        hasUnread ? controller.repeat() : null,
                  )
                  .shake(
                    duration: 500.ms,
                    delay: 2000.ms,
                    hz: 4,
                  ),

              // Premium Badge with Glow Effect
              if (hasUnread)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFEF4444),
                          Color(0xFFF97316),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .scale(
                        duration: 1000.ms,
                        begin: const Offset(1, 1),
                        end: const Offset(1.15, 1.15),
                      )
                      .then()
                      .scale(
                        duration: 1000.ms,
                        begin: const Offset(1.15, 1.15),
                        end: const Offset(1, 1),
                      ),
                ),

              // Pulse Effect Ring
              if (hasUnread)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat())
                        .scale(
                          duration: 2000.ms,
                          begin: const Offset(1, 1),
                          end: const Offset(1.4, 1.4),
                        )
                        .fadeOut(duration: 2000.ms),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationPanel(
        onNavigateToBudget: onNavigateToBudget, // Pass the callback
      ),
    );
  }
}
