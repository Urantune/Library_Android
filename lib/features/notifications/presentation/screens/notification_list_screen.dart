import 'package:flutter/material.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String type;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type = 'info',
  });
}

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: 'noti-001',
      title: 'Sách sắp đến hạn trả',
      message: 'Cuốn "Dế Mèn phiêu lưu ký" sẽ đến hạn trả vào ngày 20/10/2026.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: 'warning',
    ),
    NotificationItem(
      id: 'noti-002',
      title: 'Đặt trước thành công',
      message: 'Bạn đã đặt trước cuốn "Nhà giả kim" thành công.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
      type: 'success',
    ),
    NotificationItem(
      id: 'noti-003',
      title: 'Hệ thống bảo trì',
      message: 'Hệ thống sẽ bảo trì vào ngày 15/10/2026 từ 22:00 - 23:00.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      type: 'info',
    ),
    NotificationItem(
      id: 'noti-004',
      title: 'Quá hạn trả sách',
      message: 'Cuốn "Clean Code" đã quá hạn 3 ngày. Vui lòng trả sách sớm nhất.',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      type: 'error',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var i = 0; i < _notifications.length; i++) {
                  _notifications[i] = NotificationItem(
                    id: _notifications[i].id,
                    title: _notifications[i].title,
                    message: _notifications[i].message,
                    timestamp: _notifications[i].timestamp,
                    isRead: true,
                    type: _notifications[i].type,
                  );
                }
              });
            },
            child: const Text('Đọc tất cả'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = _notifications[index];
            return _NotificationCard(
              item: item,
              onTap: () {
                setState(() {
                  _notifications[index] = NotificationItem(
                    id: item.id,
                    title: item.title,
                    message: item.message,
                    timestamp: item.timestamp,
                    isRead: true,
                    type: item.type,
                  );
                });
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color iconColor;
    Color iconBgColor;

    switch (item.type) {
      case 'warning':
        iconData = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFF59E0B);
        iconBgColor = const Color(0xFFFEF3C7);
        break;
      case 'success':
        iconData = Icons.check_circle_outline;
        iconColor = const Color(0xFF16A34A);
        iconBgColor = const Color(0xFFE2F6E9);
        break;
      case 'error':
        iconData = Icons.error_outline;
        iconColor = const Color(0xFFEF4444);
        iconBgColor = const Color(0xFFFFE9E7);
        break;
      default:
        iconData = Icons.info_outline;
        iconColor = const Color(0xFF2563EB);
        iconBgColor = const Color(0xFFDBEAFE);
    }

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: item.isRead
              ? const Color(0xFFE6EAF0)
              : const Color(0xFF2563EB).withOpacity(0.3),
          width: item.isRead ? 1 : 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: item.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimestamp(item.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else {
      return '${diff.inDays} ngày trước';
    }
  }
}
