import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/profile_service.dart';

class TwoFactorAuthScreen extends StatefulWidget {
  const TwoFactorAuthScreen({super.key});

  @override
  State<TwoFactorAuthScreen> createState() => _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends State<TwoFactorAuthScreen> {
  bool twoFactorEnabled = false;
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTwoFactorStatus();
  }

  Future<void> _loadTwoFactorStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final profile = await _profileService.getProfile(user.uid);
        if (profile != null) {
          setState(() {
            twoFactorEnabled = profile.twoFactorEnabled;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _toggle2FA(bool value) async {
    setState(() => twoFactorEnabled = value);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _profileService.updateProfile(user.uid, {'twoFactorEnabled': value});
      }
    } catch (e) {
      // Revert the state if save fails
      setState(() => twoFactorEnabled = !value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to update two-factor authentication setting"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(twoFactorEnabled
              ? "Two-Factor Authentication Enabled"
              : "Two-Factor Authentication Disabled"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Two-Factor Authentication")),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Two-Factor Authentication")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text("Enable Two-Factor Authentication"),
              value: twoFactorEnabled,
              onChanged: _toggle2FA,
            ),
            const SizedBox(height: 20),
            const Text(
              "When enabled, you’ll be asked for a verification code sent to your email or phone when signing in.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
