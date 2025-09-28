import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../models/notification_model.dart';
import 'package:intl/intl.dart';
import '../../../core/route_names.dart';

class EmployerNotificationsScreen extends StatelessWidget {
  const EmployerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: const Color(0xFF1a73e8),
        actions: [
          if (notificationProvider.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.mark_email_read),
              tooltip: "Mark all as read",
              onPressed: () async {
                await notificationProvider.markAllAsRead();
              },
            ),
        ],
      ),
      body: notificationProvider.notifications.isEmpty
          ? const Center(
              child: Text(
                "No notifications yet",
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notificationProvider.notifications.length,
              itemBuilder: (context, index) {
                final NotificationModel notification =
                    notificationProvider.notifications[index];

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  color: notification.read ? Colors.white : Colors.blue[50],
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    leading: Icon(
                      notification.read
                          ? Icons.notifications_none
                          : Icons.notifications_active,
                      color: notification.read
                          ? Colors.grey
                          : Colors.blueAccent,
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.read
                            ? FontWeight.normal
                            : FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notification.message),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat.yMMMd().add_jm().format(notification.timestamp),
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: !notification.read
                        ? IconButton(
                            icon: const Icon(
                              Icons.check,
                              color: Colors.blueAccent,
                            ),
                            onPressed: () async {
                              await notificationProvider
                                  .markAsRead(notification.id);
                            },
                          )
                        : null,
                    onTap: () async {
                      if (!notification.read) {
                        await notificationProvider.markAsRead(notification.id);
                      }
                      // Navigate to relevant screen based on notification type
                      if (notification.title == 'New Application Received') {
                        if (!context.mounted) return;
                        Navigator.of(context).pushNamed(RouteNames.myJobs);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
