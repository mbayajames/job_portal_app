import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../providers/notification_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text("Notifications", style: TextStyle(color: primaryWhite)),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read, color: primaryWhite),
            onPressed: () {
              Provider.of<NotificationProvider>(context, listen: false).markAllAsRead();
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: primaryBlue));
          }

          if (provider.notifications.isEmpty) {
            return const Center(
              child: Text(
                "No notifications yet.",
                style: TextStyle(fontSize: 18, color: primaryBlack),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            itemCount: provider.notifications.length,
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                color: notification['read'] ? primaryWhite : primaryBlue.withOpacity(0.1),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Icon(
                    notification['read'] ? Icons.notifications_none : Icons.notifications_active,
                    color: notification['read'] ? primaryBlue : Colors.green,
                    size: 32,
                  ),
                  title: Text(
                    notification['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 20 : 16,
                      color: primaryBlack,
                    ),
                  ),
                  subtitle: Text(
                    notification['message'],
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 14,
                      color: primaryBlack.withOpacity(0.7),
                    ),
                  ),
                  trailing: !notification['read']
                      ? IconButton(
                          icon: const Icon(Icons.mark_email_read, color: Colors.green),
                          onPressed: () {
                            provider.markAsRead(notification['id']);
                          },
                          tooltip: 'Mark as read',
                        )
                      : null,
                  onTap: () {
                    if (!notification['read']) {
                      provider.markAsRead(notification['id']);
                    }
                    // Optional: handle notification click action
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Clicked: ${notification['title']}")),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}