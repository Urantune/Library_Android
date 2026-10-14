import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/author.dart';
import '../providers/author_provider.dart';
import 'author_add_screen.dart';

class AuthorDetailScreen extends ConsumerWidget {
  final String authorId;

  const AuthorDetailScreen({
    super.key,
    required this.authorId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorAsync = ref.watch(authorDetailProvider(authorId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Chi tiết tác giả'),
        backgroundColor: Colors.white,
        actions: [
          authorAsync.maybeWhen(
            data: (author) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Sửa thông tin',
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () async {
                    final updated = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => AuthorAddScreen(author: author),
                      ),
                    );
                    if (updated == true && context.mounted) {
                      ref.invalidate(authorDetailProvider(authorId));
                      ref.invalidate(authorListProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cập nhật tác giả thành công!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Xóa tác giả',
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Xác nhận xóa'),
                        content: Text('Bạn có chắc chắn muốn xóa tác giả "${author.name}" không?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Hủy'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && context.mounted) {
                      try {
                        await ref.read(authorRepositoryProvider).deleteAuthor(author.id);
                        ref.invalidate(authorListProvider);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã xóa tác giả thành công!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Không thể xóa tác giả: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: authorAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 52, color: Colors.redAccent),
                const SizedBox(height: 12),
                const Text('Không thể tải chi tiết tác giả'),
                const SizedBox(height: 8),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(
                    authorDetailProvider(authorId),
                  ),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (author) => _AuthorDetail(author: author),
      ),
    );
  }
}

class _AuthorDetail extends StatelessWidget {
  final Author author;

  const _AuthorDetail({required this.author});

  @override
  Widget build(BuildContext context) {
    final active = author.status.toUpperCase() == 'ACTIVE';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: const Color(0xFFE6EDFF),
                child: Text(
                  author.name.isEmpty ? '?' : author.name[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3157B7),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                author.name.isEmpty ? 'Chưa có tên' : author.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ID: ${author.id}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Chip(
                label: Text(author.status),
                backgroundColor: active
                    ? const Color(0xFFE2F6E9)
                    : const Color(0xFFFFE9E7),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin tác giả',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _InfoRow(
                label: 'Ngày sinh',
                value: _formatDate(author.birthDate),
              ),
              _InfoRow(
                label: 'Quốc gia',
                value: _display(author.country),
              ),
              const Divider(height: 28),
              const Text(
                'Tiểu sử',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _display(author.bio),
                style: const TextStyle(fontSize: 15, height: 1.6),
              ),
              const Divider(height: 28),
              _InfoRow(
                label: 'Ngày tạo',
                value: _formatDateTime(author.createdAt),
              ),
              _InfoRow(
                label: 'Ngày cập nhật',
                value: _formatDateTime(author.updatedAt),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          (label.isNotEmpty)
              ? SizedBox(
                  width: 125,
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.black54),
                  ),
                )
              : const SizedBox.shrink(),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

String _display(String? value) =>
    value == null || value.trim().isEmpty ? 'Chưa cập nhật' : value;

String _formatDate(DateTime? date) {
  if (date == null) return 'Chưa cập nhật';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String _formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return 'Chưa cập nhật';
  return '${dateTime.hour.toString().padLeft(2, '0')}:'
      '${dateTime.minute.toString().padLeft(2, '0')} ngày '
      '${dateTime.day.toString().padLeft(2, '0')}/'
      '${dateTime.month.toString().padLeft(2, '0')}/'
      '${dateTime.year}';
}
