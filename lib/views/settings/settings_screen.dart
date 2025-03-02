import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/constants/app_colors.dart';
import 'package:life_quest/constants/app_strings.dart';
import 'package:life_quest/services/analytics_service.dart';
import 'package:life_quest/services/auth_service.dart';
import 'package:life_quest/views/auth/onboarding_screen.dart';
import 'package:life_quest/views/settings/gdpr_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
      ),
      body: ListView(
        children: [
          // Account section
          const _SectionHeader(title: 'Account'),

          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('Profile'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to profile screen
            },
          ),

          const Divider(indent: 16, endIndent: 16),

          // Preferences section
          const _SectionHeader(title: 'Preferences'),

          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text(AppStrings.notifications),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to notifications settings
            },
          ),

          const Divider(indent: 16, endIndent: 16),

          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Theme'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Implement theme selector
            },
          ),

          const Divider(indent: 16, endIndent: 16),

          // Privacy section
          const _SectionHeader(title: 'Privacy & Security'),

          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text(AppStrings.privacy),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GdprScreen(),
                ),
              );
            },
          ),

          const Divider(indent: 16, endIndent: 16),

          // Support section
          const _SectionHeader(title: 'Support'),

          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text(AppStrings.help),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to help center
            },
          ),

          const Divider(indent: 16, endIndent: 16),

          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Send Feedback'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Implement feedback form
            },
          ),

          const Divider(indent: 16, endIndent: 16),

          // About section
          const _SectionHeader(title: 'About'),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text(AppStrings.about),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to about screen
            },
          ),

          const Divider(indent: 16, endIndent: 16),

          // Sign out
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () async {
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
              icon: const Icon(Icons.logout),
              label: const Text(AppStrings.signOut),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red.shade700,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),

          const SizedBox(height: 40),

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
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}