import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_connect/providers/auth_provider.dart' as vet_auth;

import 'package:vetcare_connect/providers/firebase_user_provider.dart';

import 'package:vetcare_connect/providers/theme_provider.dart';
import 'package:vetcare_connect/providers/notification_provider.dart';
import 'package:vetcare_connect/views/widgets/drawer_widget.dart';

import 'package:vetcare_connect/models/user_role.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatelessWidget {
  Future<void> _confirmAndDeleteAccount(BuildContext context) async {
    final auth = FirebaseAuth.instance;
    final current = auth.currentUser;
    if (current == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account'),
        content:
            const Text('This will permanently delete your account. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final uid = current.uid;

    try {
      // Soft-delete user document (client delete is blocked by firestore.rules)
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'deleted': true,
          'approved': false,
        },
        SetOptions(merge: true),
      );

      // Hard-delete Firebase Auth user
      await current.delete();

      // Sign out
      await auth.signOut();

      if (!context.mounted) return;
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed. Please try again.')),
      );
    }
  }

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUserProvider = Provider.of<FirebaseUserProvider>(context);
    final currentUser = firebaseUserProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      drawer: const AppDrawer(currentRoute: '/settings'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth > 600 ? 600 : double.infinity;
          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth > 600
                  ? (constraints.maxWidth - maxWidth) / 2
                  : 16,
              vertical: 16,
            ),
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, 'Account'),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Profile'),
                        subtitle: Text(currentUser?.fullname ?? 'No user'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pushNamed(context, '/profile_settings');
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionHeader(context, 'Preferences'),
                    Card(
                      child: Column(
                        children: [
                          Consumer<ThemeProvider>(
                            builder: (context, themeProvider, child) {
                              return SwitchListTile(
                                secondary: const Icon(Icons.dark_mode),
                                title: const Text('Dark Mode'),
                                subtitle: const Text('Toggle dark mode theme'),
                                value: themeProvider.isDarkMode,
                                onChanged: (value) {
                                  themeProvider.toggleDarkMode();
                                },
                              );
                            },
                          ),
                          const Divider(height: 1),
                          Consumer2<NotificationProvider,
                              vet_auth.AuthProvider>(
                            builder: (context, notificationProvider,
                                authProvider, child) {
                              return SwitchListTile(
                                secondary: const Icon(Icons.notifications),
                                title: const Text('Notifications'),
                                subtitle:
                                    const Text('Enable push notifications'),
                                value:
                                    notificationProvider.notificationsEnabled,
                                onChanged: (value) async {
                                  await notificationProvider
                                      .setNotificationsEnabled(value);

                                  // Re-init with proper role to subscribe to role topics.
                                  final roleValue = authProvider.role?.value;
                                  if (value && roleValue != null) {
                                    await notificationProvider.initialize(
                                        role: roleValue);
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionHeader(context, 'Legal'),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.privacy_tip),
                            title: const Text('Privacy Policy'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showPrivacyPolicy(context),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.description),
                            title: const Text('Terms & Conditions'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showTermsConditions(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionHeader(context, 'Account Security'),
                    if (currentUser != null &&
                        currentUser.role == UserRole.customer)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.delete_forever,
                              color: Colors.red),
                          title: const Text('Delete account'),
                          subtitle:
                              const Text('Permanently remove your account'),
                          onTap: () => _confirmAndDeleteAccount(context),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildSectionHeader(context, 'Support'),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.help),
                            title: const Text('Help & Support'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showHelpSupport(context),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.info),
                            title: const Text('About'),
                            subtitle: const Text('Version 1.0.0'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              showAboutDialog(
                                context: context,
                                applicationName: 'FurfectCare',
                                applicationVersion: '1.0.0',
                                applicationLegalese:
                                    '© 2024 FurfectCare\nPhilippine Data Privacy Act Compliant',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FurfectCare respects your privacy.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'We collect personal information only to provide veterinary services. '
                'Your data is protected under the Philippine Data Privacy Act of 2012 (Republic Act 10173). '
                'We do not share your information without your consent unless required by law.',
              ),
              SizedBox(height: 12),
              Text(
                'Your Rights:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Right to be informed'),
              Text('• Right to access your data'),
              Text('• Right to rectification'),
              Text('• Right to erasure'),
              Text('• Right to data portability'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsConditions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'By using FurfectCare, you agree to the following:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                '1. Use our services responsibly and provide accurate information.\n\n'
                '2. Pets should be brought for regular checkups as recommended.\n\n'
                '3. Medical records are confidential and protected.\n\n'
                '4. Payment for services must be settled promptly.\n\n'
                '5. Cancellation of appointments should be done 24 hours in advance.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Need assistance? We\'re here to help!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('Contact us:'),
              SizedBox(height: 8),
              Text('📧 Email: support@furfectcare.com'),
              Text('📞 Phone: +63 900 123 4567'),
              Text('📍 Address: Quezon City, Philippines'),
              SizedBox(height: 16),
              Text(
                'Business Hours:\nMonday - Friday: 8:00 AM - 6:00 PM\nSaturday: 9:00 AM - 4:00 PM\nSunday: Closed',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
