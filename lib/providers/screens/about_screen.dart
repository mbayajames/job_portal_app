import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/about_service.dart';

class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final aboutService = AboutService();
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('About', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: aboutService.getAppInfo(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
            final info = snapshot.data ?? {};
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About Job Portal',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.blue),
                  ),
                  SizedBox(height: 16),
                  Text(
                    info['description'] ?? 'A platform to connect job seekers and employers.',
                    style: TextStyle(color: Colors.black),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Version: ${info['version'] ?? '1.0.0'}',
                    style: TextStyle(color: Colors.black),
                  ),
                  SizedBox(height: 16),
                  if (info['termsUrl'] != null)
                    TextButton(
                      onPressed: () => _launchUrl(info['termsUrl'], context),
                      child: Text('Terms of Service', style: TextStyle(color: Colors.blue)),
                    ),
                  if (info['privacyUrl'] != null)
                    TextButton(
                      onPressed: () => _launchUrl(info['privacyUrl'], context),
                      child: Text('Privacy Policy', style: TextStyle(color: Colors.blue)),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }
}