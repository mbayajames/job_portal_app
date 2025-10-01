import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  @override
  void initState() {
    super.initState();
    // Load settings when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings();
    });
  }

  Future<void> _savePreferences() async {
    final settingsProvider = context.read<SettingsProvider>();

    await settingsProvider.updateNotifications(
      email: settingsProvider.emailNotifications,
      push: settingsProvider.pushNotifications,
      sms: settingsProvider.smsNotifications,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preferences saved")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Scaffold(
          appBar: AppBar(title: const Text("Notification Preferences")),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("Email Notifications"),
                  value: settingsProvider.emailNotifications,
                  onChanged: (val) => settingsProvider.emailNotifications = val,
                ),
                SwitchListTile(
                  title: const Text("SMS Notifications"),
                  value: settingsProvider.smsNotifications,
                  onChanged: (val) => settingsProvider.smsNotifications = val,
                ),
                SwitchListTile(
                  title: const Text("Push Notifications"),
                  value: settingsProvider.pushNotifications,
                  onChanged: (val) => settingsProvider.pushNotifications = val,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: settingsProvider.isLoading ? null : _savePreferences,
                  child: settingsProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Save Preferences"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}