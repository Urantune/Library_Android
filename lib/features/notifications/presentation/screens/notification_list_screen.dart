import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/notification_api.dart';
import '../providers/notification_provider.dart';
import 'notification_detail_screen.dart';

class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});
  @override
  ConsumerState<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState
    extends ConsumerState<NotificationListScreen> {
  NotificationApi get _api => ref.read(notificationApiProvider);
  late Future<NotificationPage> _request;
  int _page = 0;
  bool _unreadOnly = false;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _request = _api.list(page: _page, unreadOnly: _unreadOnly);
  }

  Future<void> _reload() async {
    final request = _api.list(page: _page, unreadOnly: _unreadOnly);
    setState(() {
      _request = request;
    });
    try {
      await request;
    } catch (_) {}
  }

  Future<void> _markRead(AppNotification? item) async {
    if (_updating || (item?.isRead ?? false)) return;
    setState(() => _updating = true);
    try {
      if (item == null) {
        await _api.markAllRead();
      } else {
        await _api.markRead(item.id);
      }
      ref.invalidate(unreadNotificationCountProvider);
      if (mounted) {
        _page = 0;
        await _reload();
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Không thể cập nhật thông báo. Vui lòng thử lại.')));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  void _openNotification(AppNotification item) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => NotificationDetailScreen(notification: item)));
    if (!item.isRead) _markRead(item);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
            title: const Text('Thông báo'),
            backgroundColor: Colors.white,
            actions: [
              TextButton(
                  onPressed: _updating ? null : () => _markRead(null),
                  child: const Text('Đọc tất cả')),
            ]),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    label: const Text('Chưa đọc'),
                    selected: _unreadOnly,
                    onSelected: (value) {
                      _unreadOnly = value;
                      _page = 0;
                      _reload();
                    },
                  ))),
          Expanded(
              child: FutureBuilder<NotificationPage>(
                  future: _request,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done)
                      return const Center(child: CircularProgressIndicator());
                    if (snapshot.hasError) {
                      return Center(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text('Không tải được thông báo.'),
                        TextButton(
                            onPressed: _reload, child: const Text('Thử lại')),
                      ]));
                    }
                    final result = snapshot.requireData;
                    if (result.items.isEmpty)
                      return Center(
                          child: Text(_unreadOnly
                              ? 'Không có thông báo chưa đọc.'
                              : 'Chưa có thông báo.'));
                    return Column(children: [
                      Expanded(
                          child: RefreshIndicator(
                              onRefresh: _reload,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: result.items.length,
                                itemBuilder: (context, index) {
                                  final item = result.items[index];
                                  return Card(
                                      color: Colors.white,
                                      child: ListTile(
                                        leading: Icon(
                                            item.isRead
                                                ? Icons.notifications_none
                                                : Icons
                                                    .notifications_active_outlined,
                                            color: item.isRead
                                                ? Colors.grey
                                                : Colors.blue),
                                        title: Text(item.title,
                                            style: TextStyle(
                                                fontWeight: item.isRead
                                                    ? FontWeight.normal
                                                    : FontWeight.bold)),
                                        subtitle: Text([
                                          item.body,
                                          if (item.createdAt != null)
                                            _date(item.createdAt!)
                                        ]
                                            .where((s) => s.isNotEmpty)
                                            .join('\n')),
                                        isThreeLine: item.createdAt != null,
                                        trailing:
                                            const Icon(Icons.chevron_right),
                                        onTap: () => _openNotification(item),
                                      ));
                                },
                              ))),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                                tooltip: 'Trang trước',
                                onPressed: _page > 0
                                    ? () {
                                        _page--;
                                        _reload();
                                      }
                                    : null,
                                icon: const Icon(Icons.chevron_left)),
                            Text('Trang ${_page + 1}/${result.totalPages}'),
                            IconButton(
                                tooltip: 'Trang sau',
                                onPressed: _page + 1 < result.totalPages
                                    ? () {
                                        _page++;
                                        _reload();
                                      }
                                    : null,
                                icon: const Icon(Icons.chevron_right)),
                          ]),
                    ]);
                  })),
        ]),
      );

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
