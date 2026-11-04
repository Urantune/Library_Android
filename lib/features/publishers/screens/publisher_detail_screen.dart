import 'package:flutter/material.dart';

import '../models/publisher.dart';
import '../services/publisher_service.dart';

class PublisherDetailScreen extends StatefulWidget {
  final int publisherId;

  const PublisherDetailScreen({
    super.key,
    required this.publisherId,
  });

  @override
  State<PublisherDetailScreen> createState() => _PublisherDetailScreenState();
}

class _PublisherDetailScreenState extends State<PublisherDetailScreen> {
  final PublisherService service = PublisherService();

  late Future<Publisher> publisherFuture;

  @override
  void initState() {
    super.initState();

    // Gọi API lấy chi tiết nhà xuất bản
    publisherFuture = service.getPublisherById(
      widget.publisherId,
    );
  }

  // Tải lại thông tin
  void refreshPublisher() {
    setState(() {
      publisherFuture = service.getPublisherById(
        widget.publisherId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Chi tiết nhà xuất bản'),
        actions: [
          IconButton(
            onPressed: refreshPublisher,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Publisher>(
        future: publisherFuture,
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
                    'Không thể tải thông tin nhà xuất bản',
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: refreshPublisher,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final publisher = snapshot.data;

          if (publisher == null) {
            return const Center(
              child: Text('Không tìm thấy nhà xuất bản'),
            );
          }

          // HIỂN THỊ CHI TIẾT
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Icon(
                        Icons.apartment,
                        size: 65,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        publisher.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(height: 35),
                    buildInfo(
                      'Mã nhà xuất bản',
                      publisher.id.toString(),
                    ),
                    buildInfo(
                      'Tên nhà xuất bản',
                      publisher.name,
                    ),
                    buildInfo(
                      'Địa chỉ',
                      publisher.address,
                    ),
                    buildInfo(
                      'Số điện thoại',
                      publisher.phone,
                    ),
                    buildInfo(
                      'Email',
                      publisher.email,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Hiển thị một dòng thông tin
  Widget buildInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value.isEmpty ? 'Chưa cập nhật' : value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
