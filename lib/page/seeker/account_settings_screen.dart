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

class AccountSettingsScreenState extends State<AccountSettingsScreen> 
    with TickerProviderStateMixin {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _loadSettings();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

    if (key == 'notifications_enabled') {
      _showCustomSnackBar(
        message: value ? 'Notifications enabled' : 'Notifications disabled',
        type: value ? SnackBarType.success : SnackBarType.info,
        icon: value ? Icons.notifications_active : Icons.notifications_off,
      );
    }
  }

  void _showCustomSnackBar({
    required String message,
    required SnackBarType type,
    required IconData icon,
  }) {
    Color backgroundColor;
    switch (type) {
      case SnackBarType.success:
        backgroundColor = Colors.green[600]!;
        break;
      case SnackBarType.error:
        backgroundColor = Colors.red[600]!;
        break;
      case SnackBarType.warning:
        backgroundColor = Colors.orange[600]!;
        break;
      case SnackBarType.info:
        backgroundColor = Colors.blue[600]!;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handleLogout() {
    _showStyledDialog(
      title: 'Logout',
      icon: Icons.logout,
      iconColor: Colors.orange[600]!,
      content: 'Are you sure you want to logout from your account?',
      actions: [
        _buildDialogButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
          isPrimary: false,
        ),
        _buildDialogButton(
          label: 'Logout',
          onPressed: () async {
            Navigator.pop(context);
            final authService = Provider.of<AuthService>(context, listen: false);
            await authService.signOut();
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/login');
          },
          isPrimary: true,
          color: Colors.orange[600]!,
        ),
      ],
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.lock_reset, color: Colors.blue[600], size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                _buildPasswordField(
                  controller: currentPasswordController,
                  label: 'Current Password',
                  icon: Icons.lock_outline,
                ),
                const SizedBox(height: 16),
                
                _buildPasswordField(
                  controller: newPasswordController,
                  label: 'New Password',
                  icon: Icons.lock_outline,
                ),
                const SizedBox(height: 16),
                
                _buildPasswordField(
                  controller: confirmPasswordController,
                  label: 'Confirm New Password',
                  icon: Icons.lock_outline,
                ),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _handlePasswordChange(
                        newPasswordController.text,
                        confirmPasswordController.text,
                        context,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Update Password'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: Colors.blue[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  void _handlePasswordChange(String newPassword, String confirmPassword, BuildContext dialogContext) {
    if (newPassword != confirmPassword) {
      Navigator.pop(dialogContext);
      _showCustomSnackBar(
        message: 'New passwords do not match',
        type: SnackBarType.error,
        icon: Icons.error,
      );
      return;
    }

    if (newPassword.length < 6) {
      Navigator.pop(dialogContext);
      _showCustomSnackBar(
        message: 'Password must be at least 6 characters',
        type: SnackBarType.error,
        icon: Icons.error,
      );
      return;
    }

    Navigator.pop(dialogContext);
    _showCustomSnackBar(
      message: 'Password changed successfully',
      type: SnackBarType.success,
      icon: Icons.check_circle,
    );
  }

  void _showDeleteAccountDialog() {
    _showStyledDialog(
      title: 'Delete Account',
      icon: Icons.warning_amber,
      iconColor: Colors.red[600]!,
      content: 'This action cannot be undone. This will permanently delete:\n\n'
               '• Your profile data\n'
               '• All your preferences\n'
               '• Account information\n\n'
               'Are you absolutely sure?',
      actions: [
        _buildDialogButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
          isPrimary: false,
        ),
        _buildDialogButton(
          label: 'Delete Account',
          onPressed: () {
            Navigator.pop(context);
            _processAccountDeletion();
          },
          isPrimary: true,
          color: Colors.red[600]!,
        ),
      ],
    );
  }

  void _processAccountDeletion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.red[600]),
              const SizedBox(height: 20),
              Text(
                'Deleting your account...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showCustomSnackBar(
                    message: 'Account deletion cancelled',
                    type: SnackBarType.warning,
                    icon: Icons.cancel,
                  );
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.delete, color: Colors.white),
              SizedBox(width: 8),
              Text('Account deletion request sent'),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () {
              _showCustomSnackBar(
                message: 'Account deletion cancelled',
                type: SnackBarType.success,
                icon: Icons.check_circle,
              );
            },
          ),
        ),
      );
    });
  }

  void _showStyledDialog({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
    required List<Widget> actions,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
    Color? color,
  }) {
    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.blue[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(label),
      );
    } else {
      return TextButton(
        onPressed: onPressed,
        child: Text(label, style: TextStyle(color: Colors.grey[600])),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const Sidebar(),
      appBar: AppBar(
        title: const Text(
          'Account Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.blue[600],
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading settings...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 24),
                      
                      _buildNotificationSettings(),
                      const SizedBox(height: 24),
                      
                      _buildPrivacySettings(),
                      const SizedBox(height: 24),
                      
                      _buildAccountActions(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[600]!,
            Colors.blue[800]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.person,
              size: 30,
              color: Colors.blue[600],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Settings',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
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

  Widget _buildNotificationSettings() {
    return _buildSettingsSection(
      title: 'Notifications',
      icon: Icons.notifications_active_outlined,
      children: [
        _buildSwitchTile(
          title: 'Enable Notifications',
          subtitle: 'Receive all notification types',
          icon: Icons.notifications,
          iconColor: _notificationsEnabled ? Colors.blue[600]! : Colors.grey,
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
        ),
        if (_notificationsEnabled) ...[
          const Divider(height: 1, indent: 72),
          _buildSwitchTile(
            title: 'Email Notifications',
            subtitle: 'Receive notifications via email',
            icon: Icons.email,
            iconColor: _emailNotifications ? Colors.green[600]! : Colors.grey,
            value: _emailNotifications,
            onChanged: (value) {
              setState(() => _emailNotifications = value);
              _saveSetting('email_notifications', value);
            },
          ),
          const Divider(height: 1, indent: 72),
          _buildSwitchTile(
            title: 'Push Notifications',
            subtitle: 'Receive push notifications on device',
            icon: Icons.phone_android,
            iconColor: _pushNotifications ? Colors.purple[600]! : Colors.grey,
            value: _pushNotifications,
            onChanged: (value) {
              setState(() => _pushNotifications = value);
              _saveSetting('push_notifications', value);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPrivacySettings() {
    return _buildSettingsSection(
      title: 'Privacy & Security',
      icon: Icons.security_outlined,
      children: [
        _buildActionTile(
          title: 'Change Password',
          subtitle: 'Update your password regularly for security',
          icon: Icons.lock_outline,
          iconColor: Colors.blue[600]!,
          onTap: _showChangePasswordDialog,
        ),
        const Divider(height: 1, indent: 72),
        _buildActionTile(
          title: 'Privacy Policy',
          subtitle: 'Learn how we protect your data',
          icon: Icons.privacy_tip_outlined,
          iconColor: Colors.green[600]!,
          onTap: () => _showInformationDialog(
            'Privacy Policy',
            Icons.privacy_tip,
            Colors.green[600]!,
            _getPrivacyPolicyContent(),
          ),
        ),
        const Divider(height: 1, indent: 72),
        _buildActionTile(
          title: 'Terms of Service',
          subtitle: 'Review our terms and conditions',
          icon: Icons.description_outlined,
          iconColor: Colors.orange[600]!,
          onTap: () => _showInformationDialog(
            'Terms of Service',
            Icons.description,
            Colors.orange[600]!,
            _getTermsOfServiceContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountActions() {
    return _buildSettingsSection(
      title: 'Account Actions',
      icon: Icons.account_circle_outlined,
      children: [
        _buildActionTile(
          title: 'Delete Account',
          subtitle: 'Permanently remove your account and data',
          icon: Icons.delete_outline,
          iconColor: Colors.red[600]!,
          textColor: Colors.red[600]!,
          onTap: _showDeleteAccountDialog,
        ),
        const Divider(height: 1, indent: 72),
        _buildActionTile(
          title: 'Logout',
          subtitle: 'Sign out of your account',
          icon: Icons.logout,
          iconColor: Colors.orange[600]!,
          onTap: _handleLogout,
        ),
      ],
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.blue[600], size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.blue[600],
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor?.withValues(alpha: 0.7) ?? Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: textColor ?? Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInformationDialog(String title, IconData icon, Color iconColor, Widget content) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: content,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close', style: TextStyle(color: Colors.grey[600])),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getPrivacyPolicyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Privacy Matters',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        const Text(
          'We are committed to protecting your personal information. Here\'s how we handle your data:',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        _buildInfoPoint('Data Collection', 'We only collect necessary information to provide our services.'),
        _buildInfoPoint('Data Usage', 'Your data is used solely for app functionality and improvement.'),
        _buildInfoPoint('Data Protection', 'We implement security measures to protect your information.'),
        _buildInfoPoint('Third Parties', 'We do not sell your data to third parties.'),
        const SizedBox(height: 16),
        Text(
          'For more details, please contact our support team.',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _getTermsOfServiceContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Terms and Conditions',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        const Text(
          'By using our application, you agree to the following terms:',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        _buildInfoPoint('Acceptable Use', 'You agree to use the app for lawful purposes only.'),
        _buildInfoPoint('Account Responsibility', 'You are responsible for maintaining your account security.'),
        _buildInfoPoint('Service Modifications', 'We may update or modify the service at any time.'),
        _buildInfoPoint('Termination', 'We reserve the right to terminate accounts for violations.'),
        const SizedBox(height: 16),
        Text(
          'These terms may be updated periodically. Continued use constitutes acceptance.',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildInfoPoint(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum SnackBarType {
  success,
  error,
  warning,
  info,
}