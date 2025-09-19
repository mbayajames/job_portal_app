import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/account_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  @override
  _AccountSettingsScreenState createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _emailNotifications = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final accountService = AccountService();
    final user = authProvider.user;
    if (user != null) {
      final preferences = await accountService.getPreferences(user.uid);
      if (preferences != null) {
        setState(() {
          _emailNotifications = preferences['emailNotifications'] ?? true;
        });
      }
    }
  }

  Future<void> _savePreferences() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final accountService = AccountService();
    final user = authProvider.user;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await accountService.savePreferences(user.uid, {
        'emailNotifications': _emailNotifications,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preferences saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving preferences: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Preferences',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.blue),
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Email Notifications', style: TextStyle(color: Colors.black)),
              value: _emailNotifications,
              onChanged: (value) => setState(() => _emailNotifications = value),
              activeColor: Colors.blue,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isSaving ? null : _savePreferences,
              child: _isSaving
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Save Preferences'),
            ),
          ],
        ),
      ),
    );
  }
}