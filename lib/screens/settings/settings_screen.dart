import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../screens/auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedCurrency = 'USD';
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel != null) {
      setState(() {
        _selectedCurrency = authProvider.userModel!.currencyPreference;
        _notificationsEnabled = authProvider.userModel!.notificationsEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

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
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                _buildProfileCard(authProvider),
                const SizedBox(height: 20),
                _buildSettingsSection(
                  'Preferences',
                  [
                    _buildSettingItem(
                      'Currency',
                      'Change your preferred currency',
                      Iconsax.dollar_circle,
                      trailing: _buildCurrencySelector(),
                    ),
                    _buildSettingItem(
                      'Theme',
                      themeProvider.isDarkMode ? 'Dark mode' : 'Light mode',
                      Iconsax.brush,
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (_) => themeProvider.toggleTheme(),
                        activeColor: AppTheme.primaryGreen,
                      ),
                    ),
                    _buildSettingItem(
                      'Language',
                      'English (US)',
                      Iconsax.global,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingsSection(
                  'Security',
                  [
                    _buildSettingItem(
                      'Biometric Login',
                      'Use fingerprint or face ID',
                      Iconsax.finger_scan,
                      trailing: Switch(
                        value: _biometricEnabled,
                        onChanged: (value) {
                          setState(() => _biometricEnabled = value);
                        },
                        activeColor: AppTheme.primaryGreen,
                      ),
                    ),
                    _buildSettingItem(
                      'Change Password',
                      'Update your password',
                      Iconsax.lock,
                      onTap: () => _showChangePasswordDialog(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingsSection(
                  'Notifications',
                  [
                    _buildSettingItem(
                      'Push Notifications',
                      'Receive budget and goal alerts',
                      Iconsax.notification,
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() => _notificationsEnabled = value);
                          _saveSettings(authProvider);
                        },
                        activeColor: AppTheme.primaryGreen,
                      ),
                    ),
                    _buildSettingItem(
                      'Email Notifications',
                      'Get monthly reports via email',
                      Iconsax.sms,
                      trailing: Switch(
                        value: true,
                        onChanged: (value) {},
                        activeColor: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingsSection(
                  'Data & Privacy',
                  [
                    _buildSettingItem(
                      'Export Data',
                      'Download your financial data',
                      Iconsax.document_download,
                      onTap: () => _showExportDialog(),
                    ),
                    _buildSettingItem(
                      'Backup',
                      'Backup to cloud storage',
                      Iconsax.cloud_add,
                      onTap: () {},
                    ),
                    _buildSettingItem(
                      'Privacy Policy',
                      'Read our privacy policy',
                      Iconsax.shield_tick,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingsSection(
                  'About',
                  [
                    _buildSettingItem(
                      'App Version',
                      '1.0.0',
                      Iconsax.info_circle,
                    ),
                    _buildSettingItem(
                      'Rate Us',
                      'Rate EasyMoney on store',
                      Iconsax.star,
                      onTap: () {},
                    ),
                    _buildSettingItem(
                      'Help & Support',
                      'Get help with the app',
                      Iconsax.message_question,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: CustomButton(
                    text: 'Sign Out',
                    onPressed: () => _handleSignOut(authProvider),
                    icon: Iconsax.logout,
                    gradient: const [Colors.red, Colors.redAccent],
                    width: double.infinity,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.displayLarge?.color,
                ),
              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0),
              Text(
                'Manage your preferences',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ).animate().fadeIn(delay: 200.ms),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
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
            child: const Icon(Iconsax.setting_2, color: Colors.white),
          ).animate().fadeIn(delay: 300.ms).scale(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildProfileCard(AuthProvider authProvider) {
    final user = authProvider.userModel;
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                displayName[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showEditProfileDialog(authProvider),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Iconsax.edit, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (onTap != null)
              Icon(
                Iconsax.arrow_right_3,
                color: Colors.grey.shade400,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySelector() {
    return DropdownButton<String>(
      value: _selectedCurrency,
      underline: const SizedBox(),
      items: AppConstants.currencies.keys.map((currency) {
        return DropdownMenuItem(
          value: currency,
          child: Text(
            currency,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedCurrency = value);
          _saveSettings(Provider.of<AuthProvider>(context, listen: false));
        }
      },
    );
  }

  void _showEditProfileDialog(AuthProvider authProvider) {
    final nameController = TextEditingController(
      text: authProvider.userModel?.displayName ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
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
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && authProvider.userModel != null) {
                final updatedUser = authProvider.userModel!.copyWith(
                  displayName: newName,
                );
                await authProvider.updateUserProfile(updatedUser);
                if (context.mounted) {
                  Navigator.pop(context);
                  Helpers.showSnackBar(context, 'Profile updated');
                }
              }
            },
            child: Text(
              'Save',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Change Password',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
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
            onPressed: () {
              Navigator.pop(context);
              Helpers.showSnackBar(context, 'Password changed successfully');
            },
            child: Text(
              'Change',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Export Data',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose export format:',
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Iconsax.document_text),
              title: Text('PDF Report', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                Helpers.showSnackBar(context, 'Exporting as PDF...');
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.document_download),
              title: Text('CSV File', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                Helpers.showSnackBar(context, 'Exporting as CSV...');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveSettings(AuthProvider authProvider) async {
    if (authProvider.userModel != null) {
      final updatedUser = authProvider.userModel!.copyWith(
        currencyPreference: _selectedCurrency,
        notificationsEnabled: _notificationsEnabled,
      );
      await authProvider.updateUserProfile(updatedUser);
    }
  }

  void _handleSignOut(AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await authProvider.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
