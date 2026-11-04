import 'package:flutter/material.dart';

import '../models/publisher.dart';
import '../services/publisher_service.dart';
import 'publisher_detail_screen.dart';

class PublisherListScreen extends StatefulWidget {
  const PublisherListScreen({super.key});

  @override
  State<PublisherListScreen> createState() => _PublisherListScreenState();
}

class _PublisherListScreenState extends State<PublisherListScreen> {
  final PublisherService service = PublisherService();

  late Future<List<Publisher>> publishersFuture;

  @override
  void initState() {
    super.initState();

    // Gọi API khi mở màn hình
    publishersFuture = service.getPublishers();
  }

  // Tải lại danh sách
  Future<void> refreshPublishers() async {
    final future = service.getPublishers();

    setState(() {
      publishersFuture = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder sẽ hiển thị lỗi
    }
  }

  // Mở màn hình chi tiết
  void openDetail(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return PublisherDetailScreen(
            publisherId: id,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FB),
      child: Column(
        children: [
          // TIÊU ĐỀ
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nhà xuất bản',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Quản lý danh sách nhà xuất bản',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // NÚT REFRESH
                IconButton(
                  onPressed: refreshPublishers,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),

          // DANH SÁCH
          Expanded(
            child: FutureBuilder<List<Publisher>>(
              future: publishersFuture,
              builder: (context, snapshot) {
                // ĐANG TẢI
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // LỖI
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 45,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Không thể tải danh sách',
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: refreshPublishers,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                // LẤY DỮ LIỆU
                final publishers = snapshot.data ?? [];

                // DANH SÁCH TRỐNG
                if (publishers.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có nhà xuất bản',
                    ),
                  );
                }

                // HIỂN THỊ DANH SÁCH
                return RefreshIndicator(
                  onRefresh: refreshPublishers,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: publishers.length,
                    itemBuilder: (context, index) {
                      final publisher = publishers[index];

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.apartment),
                          ),
                          title: Text(
                            publisher.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            publisher.address.isEmpty
                                ? 'Chưa có địa chỉ'
                                : publisher.address,
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                          ),
                          onTap: () {
                            openDetail(publisher.id);
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
