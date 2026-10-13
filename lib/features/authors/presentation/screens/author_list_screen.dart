import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/author.dart';
import '../providers/author_provider.dart';
import 'author_detail_screen.dart';
import 'author_add_screen.dart';

class AuthorListScreen extends ConsumerStatefulWidget {
  const AuthorListScreen({super.key});

  @override
  ConsumerState<AuthorListScreen> createState() => _AuthorListScreenState();
}

class _AuthorListScreenState extends ConsumerState<AuthorListScreen> {
  String keyword = '';

  @override
  Widget build(BuildContext context) {
    final authorsAsync = ref.watch(authorListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Danh sách tác giả',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Thêm tác giả',
            onPressed: () async {
              final added = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const AuthorAddScreen(),
                ),
              );

              if (added == true && mounted) {
                ref.invalidate(authorListProvider);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thêm tác giả thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(
              Icons.person_add_alt_1,
              color: Color(0xFF3157B7),
            ),
          ),
          IconButton(
            tooltip: 'Làm mới',
            onPressed: () => ref.invalidate(authorListProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() => keyword = value.trim().toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Tìm theo tên tác giả...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: authorsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => _ErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(authorListProvider),
              ),
              data: (authors) {
                final filtered = authors.where((author) {
                  return author.name.toLowerCase().contains(keyword);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      authors.isEmpty
                          ? 'Chưa có tác giả nào.'
                          : 'Không tìm thấy tác giả phù hợp.',
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(authorListProvider);
                    await ref.read(authorListProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final author = filtered[index];
                      return _AuthorCard(author: author);
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

class _AuthorCard extends StatelessWidget {
  final Author author;

  const _AuthorCard({required this.author});

  @override
  Widget build(BuildContext context) {
    final active = author.status.toUpperCase() == 'ACTIVE';

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE6EAF0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AuthorDetailScreen(authorId: author.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: const Color(0xFFE6EDFF),
                child: Text(
                  author.name.isEmpty ? '?' : author.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF3157B7),
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author.name.isEmpty ? 'Chưa có tên' : author.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text('Quốc gia: ${_display(author.country)}'),
                    const SizedBox(height: 5),
                    Text('Ngày sinh: ${_formatDate(author.birthDate)}'),
                    const SizedBox(height: 8),
                    _StatusChip(active: active, status: author.status),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool active;
  final String status;

  const _StatusChip({
    required this.active,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE2F6E9) : const Color(0xFFFFE9E7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: active ? const Color(0xFF16713A) : const Color(0xFFB42318),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 52, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text(
              'Không thể tải danh sách tác giả',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
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
