import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_quest/constants/app_colors.dart';
import 'package:life_quest/constants/app_strings.dart';
import 'package:life_quest/services/analytics_service.dart';
import 'package:life_quest/services/auth_service.dart';
import 'package:life_quest/utils/local_storage.dart';
import 'package:url_launcher/url_launcher.dart';

final privacyConsentProvider = StateProvider<bool>((ref) {
  // Default to false, will be updated in initState
  return false;
});

final analyticsConsentProvider = StateProvider<bool>((ref) {
  // Default to false, will be updated in initState
  return false;
});

class GdprScreen extends ConsumerStatefulWidget {
  const GdprScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GdprScreen> createState() => _GdprScreenState();
}

class _GdprScreenState extends ConsumerState<GdprScreen> {
  final AuthService _authService = AuthService();
  bool _isExporting = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadConsents();
  }

  Future<void> _loadConsents() async {
    // Load privacy consent
    final privacyConsent = await LocalStorage.getData('privacy_consent', defaultValue: false);
    ref.read(privacyConsentProvider.notifier).state = privacyConsent;

    // Load analytics consent
    final analyticsConsent = await LocalStorage.getData('analytics_consent', defaultValue: false);
    ref.read(analyticsConsentProvider.notifier).state = analyticsConsent;
  }

  Future<void> _updatePrivacyConsent(bool value) async {
    await LocalStorage.saveData('privacy_consent', value);
    ref.read(privacyConsentProvider.notifier).state = value;
  }

  Future<void> _updateAnalyticsConsent(bool value) async {
    await LocalStorage.saveData('analytics_consent', value);
    ref.read(analyticsConsentProvider.notifier).state = value;
    // Update analytics opt-out state
    await AnalyticsService.optOut(!value);
  }

  Future<void> _exportUserData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // TODO: Implement data export functionality
      await Future.delayed(const Duration(seconds: 2)); // Simulate loading

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your data has been exported successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export data: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await _authService.deleteAccount();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account has been deleted.'),
          backgroundColor: AppColors.success,
        ),
      );

      // Navigate back to the auth screen
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete account: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  Future<void> _showDeleteConfirmation() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(AppStrings.deleteAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final privacyConsent = ref.watch(privacyConsentProvider);
    final analyticsConsent = ref.watch(analyticsConsentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.privacy),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy Header
            const Text(
              AppStrings.gdprTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.gdprDesc,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.mediumText,
              ),
            ),
            const SizedBox(height: 24),

            // Data Collection
            const Text(
              AppStrings.gdprDataCollected,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.gdprDataCollectedDesc,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.mediumText,
              ),
            ),
            const SizedBox(height: 16),

            // Data Usage
            const Text(
              AppStrings.gdprDataUsage,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.gdprDataUsageDesc,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.mediumText,
              ),
            ),
            const SizedBox(height: 16),

            // User Rights
            const Text(
              AppStrings.gdprDataRights,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.gdprDataRightsDesc,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.mediumText,
              ),
            ),
            const SizedBox(height: 24),

            // Consent toggles
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Consent Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Privacy policy consent
                    SwitchListTile(
                      title: const Text(
                        'Privacy Policy',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'I consent to the collection and processing of my data as described in the Privacy Policy.',
                      ),
                      value: privacyConsent,
                      onChanged: _updatePrivacyConsent,
                      activeColor: AppColors.primary,
                    ),

                    const Divider(),

                    // Analytics consent
                    SwitchListTile(
                      title: const Text(
                        'Analytics',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'I consent to the collection of anonymous usage data to help improve the app.',
                      ),
                      value: analyticsConsent,
                      onChanged: _updateAnalyticsConsent,
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Data management actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Export data
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: const Text('Export My Data'),
                      subtitle: const Text(
                        'Download a copy of all your personal data.',
                      ),
                      trailing: _isExporting
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _isExporting ? null : _exportUserData,
                    ),

                    const Divider(),

                    // Delete account
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: AppColors.error),
                      title: const Text(
                        'Delete My Account',
                        style: TextStyle(color: AppColors.error),
                      ),
                      subtitle: const Text(
                        'Permanently delete your account and all associated data.',
                        style: TextStyle(color: AppColors.mediumText),
                      ),
                      trailing: _isDeleting
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.error),
                      onTap: _isDeleting ? null : _showDeleteConfirmation,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Links to legal documents
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Legal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Privacy Policy link
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.open_in_new, size: 16),
                      onTap: () {
                        // TODO: Implement link to privacy policy
                      },
                    ),

                    const Divider(),

                    // Terms of Service link
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Terms of Service'),
                      trailing: const Icon(Icons.open_in_new, size: 16),
                      onTap: () {
                        // TODO: Implement link to terms of service
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}