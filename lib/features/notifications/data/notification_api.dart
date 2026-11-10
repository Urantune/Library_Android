import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class AppNotification {
  const AppNotification({required this.id, required this.title, required this.body, required this.isRead, required this.createdAt});
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    body: json['body']?.toString() ?? '',
    isRead: json['isRead'] == true,
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal(),
  );
}

class NotificationPage {
  const NotificationPage(this.items, this.totalPages);
  final List<AppNotification> items;
  final int totalPages;
}

class NotificationApi {
  NotificationApi([Dio? dio]) : _dio = dio ?? ApiClient.dio;
  final Dio _dio;
  static const _path = '/notification/api/notifications';

  Future<NotificationPage> list({required int page, required bool unreadOnly}) async {
    final response = await _dio.get<Map<String, dynamic>>(_path, queryParameters: {'page': page, 'size': 20, if (unreadOnly) 'unreadOnly': true});
    final data = response.data?['data'];
    if (data is! Map || data['items'] is! List) throw const FormatException('Dữ liệu thông báo không hợp lệ.');
    return NotificationPage((data['items'] as List).whereType<Map>().map((item) => AppNotification.fromJson(Map<String, dynamic>.from(item))).toList(), (data['totalPages'] as num?)?.toInt() ?? 0);
  }

  Future<void> markRead(String id) async => _dio.patch('$_path/${Uri.encodeComponent(id)}/read');
  Future<void> markAllRead() async => _dio.patch('$_path/read-all');

  Future<int> unreadCount() async {
    final response = await _dio.get<Map<String, dynamic>>('$_path/unread-count');
    final data = response.data?['data'];
    if (data is! Map || data['unreadCount'] is! num) throw const FormatException('Dữ liệu thông báo không hợp lệ.');
    return (data['unreadCount'] as num).toInt();
  }
}
