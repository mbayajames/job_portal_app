import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/preferences.dart';
import '../../widgets/sidebar.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  AccountSettingsScreenState createState() => AccountSettingsScreenState();
}

class AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    setState(() => _isLoading = true);
    await Preferences.init();
    setState(() {
      _notificationsEnabled = Preferences.getBool('notifications_enabled') ?? true;
      _emailNotifications = Preferences.getBool('email_notifications') ?? true;
      _pushNotifications = Preferences.getBool('push_notifications') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    await Preferences.setBool(key, value);
    if (!mounted) return;

    // Show confirmation for important changes
    if (key == 'notifications_enabled') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Notifications enabled' : 'Notifications disabled'),
          backgroundColor: value ? Colors.green : Colors.grey[600],
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _handleLogout() {
    final authService = Provider.of<AuthService>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.orange),
              SizedBox(width: 10),
              Text('Logout'),
            ],
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await authService.signOut();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    final outerContext = context;

    showDialog(
      context: outerContext,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_reset, color: Colors.blue),
              SizedBox(width: 10),
              Text('Change Password'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(outerContext).showSnackBar(
                    const SnackBar(
                      content: Text('New passwords do not match'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(outerContext).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Simulate password change
                Navigator.pop(context);
                ScaffoldMessenger.of(outerContext).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Change Password'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.privacy_tip, color: Colors.green),
              SizedBox(width: 10),
              Text('Privacy Policy'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your Privacy Matters',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                const Text(
                  'We are committed to protecting your personal information. Here\'s how we handle your data:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 10),
                _buildPolicyPoint('Data Collection', 'We only collect necessary information to provide our services.'),
                _buildPolicyPoint('Data Usage', 'Your data is used solely for app functionality and improvement.'),
                _buildPolicyPoint('Data Protection', 'We implement security measures to protect your information.'),
                _buildPolicyPoint('Third Parties', 'We do not sell your data to third parties.'),
                const SizedBox(height: 10),
                const Text(
                  'For more details, please contact our support team.',
                  style: TextStyle(fontStyle: FontStyle.italic),
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
        );
      },
    );
  }

  Widget _buildPolicyPoint(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $title:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('  $description'),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.description, color: Colors.orange),
              SizedBox(width: 10),
              Text('Terms of Service'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Terms and Conditions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                const Text(
                  'By using our application, you agree to the following terms:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 10),
                _buildTermPoint('Acceptable Use', 'You agree to use the app for lawful purposes only.'),
                _buildTermPoint('Account Responsibility', 'You are responsible for maintaining your account security.'),
                _buildTermPoint('Service Modifications', 'We may update or modify the service at any time.'),
                _buildTermPoint('Termination', 'We reserve the right to terminate accounts for violations.'),
                const SizedBox(height: 10),
                const Text(
                  'These terms may be updated periodically. Continued use constitutes acceptance.',
                  style: TextStyle(fontStyle: FontStyle.italic),
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
        );
      },
    );
  }

  Widget _buildTermPoint(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $title:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('  $description'),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red),
              SizedBox(width: 10),
              Text('Delete Account'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This action cannot be undone. This will permanently delete:',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text('• Your profile data'),
              Text('• All your preferences'),
              Text('• Account information'),
              SizedBox(height: 12),
              Text(
                'Are you absolutely sure?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                // Simulate account deletion process
                _processAccountDeletion();
              },
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );
  }

  void _processAccountDeletion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                const Text('Deleting your account...'),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account deletion cancelled'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Simulate API call delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Account deletion request sent'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () {
              _undoAccountDeletion();
            },
          ),
        ),
      );
    });
  }

  void _undoAccountDeletion() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account deletion cancelled'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Sidebar(),
      appBar: AppBar(
        title: const Text(
          'Account Settings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            )
          : ListView(
              children: [
                // Profile Header
                _buildProfileHeader(),
                
                // Notifications Settings
                _buildSectionHeader(
                  'Notifications',
                  Icons.notifications_active_outlined,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text(
                          'Enable Notifications',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text('Receive all notification types'),
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                            if (!value) {
                              _emailNotifications = false;
                              _pushNotifications = false;
                              _saveSetting('email_notifications', false);
                              _saveSetting('push_notifications', false);
                            }
                          });
                          _saveSetting('notifications_enabled', value);
                        },
                        secondary: Icon(
                          Icons.notifications,
                          color: _notificationsEnabled 
                              ? Colors.blue 
                              : Colors.grey,
                        ),
                      ),
                      if (_notificationsEnabled) ...[
                        const Divider(height: 1, indent: 20),
                        SwitchListTile(
                          title: const Text('Email Notifications'),
                          subtitle: const Text('Receive notifications via email'),
                          value: _emailNotifications,
                          onChanged: (value) {
                            setState(() => _emailNotifications = value);
                            _saveSetting('email_notifications', value);
                          },
                          secondary: Icon(
                            Icons.email,
                            color: _emailNotifications 
                                ? Colors.green 
                                : Colors.grey,
                          ),
                        ),
                        const Divider(height: 1, indent: 20),
                        SwitchListTile(
                          title: const Text('Push Notifications'),
                          subtitle: const Text('Receive push notifications'),
                          value: _pushNotifications,
                          onChanged: (value) {
                            setState(() => _pushNotifications = value);
                            _saveSetting('push_notifications', value);
                          },
                          secondary: Icon(
                            Icons.phone_android,
                            color: _pushNotifications 
                                ? Colors.purple 
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Privacy Settings
                _buildSectionHeader('Privacy', Icons.security_outlined),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildListTile(
                        title: 'Change Password',
                        subtitle: 'Update your password regularly',
                        icon: Icons.lock_outline,
                        iconColor: Colors.blue,
                        onTap: _showChangePasswordDialog,
                      ),
                      const Divider(height: 1, indent: 20),
                      _buildListTile(
                        title: 'Privacy Policy',
                        subtitle: 'Learn how we protect your data',
                        icon: Icons.privacy_tip_outlined,
                        iconColor: Colors.green,
                        onTap: _showPrivacyPolicy,
                      ),
                      const Divider(height: 1, indent: 20),
                      _buildListTile(
                        title: 'Terms of Service',
                        subtitle: 'Review our terms and conditions',
                        icon: Icons.description_outlined,
                        iconColor: Colors.orange,
                        onTap: _showTermsOfService,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Account Actions
                _buildSectionHeader('Account', Icons.account_circle_outlined),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildListTile(
                        title: 'Delete Account',
                        subtitle: 'Permanently remove your account',
                        icon: Icons.delete_outline,
                        iconColor: Colors.red,
                        textColor: Colors.red,
                        onTap: _showDeleteAccountDialog,
                      ),
                      const Divider(height: 1, indent: 20),
                      _buildListTile(
                        title: 'Logout',
                        subtitle: 'Sign out of your account',
                        icon: Icons.logout,
                        iconColor: Colors.orange,
                        onTap: _handleLogout,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 30,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your preferences and security',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: textColor?.withValues(alpha: 0.7),
          fontSize: 12,
        ),
      ),
      trailing: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: textColor ?? Colors.grey[600],
        ),
      ),
      onTap: onTap,
    );
  }
}