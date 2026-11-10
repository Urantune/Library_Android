import 'package:flutter/material.dart';
import '../../data/notification_api.dart';

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key, required this.notification});
  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final date = notification.createdAt;
    final timestamp = date == null
        ? null
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
          title: const Text('Chi tiết thông báo'),
          backgroundColor: Colors.white),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          color: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    if (timestamp != null) ...[
                      const SizedBox(height: 8),
                      Text(timestamp,
                          style: const TextStyle(color: Colors.black54))
                    ],
                    const Divider(height: 32),
                    SelectableText(notification.body,
                        style: const TextStyle(fontSize: 16, height: 1.5)),
                  ])),
        ),
      ]),
    );
  }
}
