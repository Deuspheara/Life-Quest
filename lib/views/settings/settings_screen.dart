import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/constants/app_colors.dart';
import 'package:life_quest/constants/app_strings.dart';
import 'package:life_quest/services/analytics_service.dart';
import 'package:life_quest/services/auth_service.dart';
import 'package:life_quest/views/auth/onboarding_screen.dart';
import 'package:life_quest/views/settings/gdpr_screen.dart';
import 'package:life_quest/views/settings/profile_edit_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = AuthService();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account section
              _SettingsCard(
                icon: Icons.account_circle_outlined,
                title: 'Account',
                children: [
                  _SettingsTile(
                    icon: Icons.person_outline,
                    title: 'Profile',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileEditScreen(),
                        ),
                      ).then((_) {
                        // Refresh user profile data when returning
                        ref.invalidate(currentUserProfileProvider);
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Preferences section
              _SettingsCard(
                icon: Icons.tune,
                title: 'Preferences',
                children: [
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: AppStrings.notifications,
                    onTap: () {
                      // TODO: Navigate to notifications settings
                    },
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Theme',
                    onTap: () {
                      // TODO: Implement theme selector
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Privacy section
              _SettingsCard(
                icon: Icons.shield_outlined,
                title: 'Privacy & Security',
                children: [
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: AppStrings.privacy,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GdprScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Support section
              _SettingsCard(
                icon: Icons.support_outlined,
                title: 'Support',
                children: [
                  _SettingsTile(
                    icon: Icons.help_outline,
                    title: AppStrings.help,
                    onTap: () {
                      // TODO: Navigate to help center
                    },
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.feedback_outlined,
                    title: 'Send Feedback',
                    onTap: () {
                      // TODO: Implement feedback form
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // About section
              _SettingsCard(
                icon: Icons.info_outline,
                title: 'About',
                children: [
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: AppStrings.about,
                    onTap: () {
                      // TODO: Navigate to about screen
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Sign out button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.red.shade100,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      try {
                        await authService.signOut();
                        // Track sign out event
                        await AnalyticsService.trackEvent('user_sign_out');

                        if (!context.mounted) return;

                        // Navigate to onboarding screen
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OnboardingScreen(),
                          ),
                              (route) => false,
                        );
                      } catch (e) {
                        // Show error
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to sign out: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.signOut,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // App version
              Center(
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Card content
          ...children,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: Colors.grey.shade700,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}