import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' show ReadContext;

import '../providers/dashboard_provider.dart';
import '../providers/navigation_provider.dart';
import '../services/dashboard_service.dart';
import '../theme/app_decorations.dart';
import 'book_card.dart';
import 'skeleton.dart';

class InventoryBooksSection extends ConsumerWidget {
  const InventoryBooksSection({super.key});

  static const _cardWidth = 150.0;
  static const _gap = 14.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(booksOverviewProvider);
    final data = async.hasValue ? async.value : null;

    final Widget body;
    if (data != null) {
      body = data.items.isEmpty
          ? const _Notice(
              icon: Icons.inbox_outlined,
              message: 'Kho chưa có cuốn sách nào. Thêm sách ở mục Sách.',
            )
          : _BookStrip(books: data);
    } else if (async.hasError) {
      body = _ErrorBlock(
        message: dashboardErrorMessage(async.error!),
        onRetry: () => ref.invalidate(booksOverviewProvider),
      );
    } else {
      body = const _BookStripSkeleton();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sách trong kho',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context
                    .read<NavigationProvider>()
                    .selectMenu(NavIndex.book),
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }
}

class _BookStrip extends StatelessWidget {
  const _BookStrip({required this.books});

  final BooksOverview books;

  @override
  Widget build(BuildContext context) {
    final items = books.items;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: InventoryBooksSection._gap),
            SizedBox(
              width: InventoryBooksSection._cardWidth,
              child: BookCard(book: items[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _BookStripSkeleton extends StatelessWidget {
  const _BookStripSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget card() => SizedBox(
          width: InventoryBooksSection._cardWidth,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EDF4)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Skeleton(radius: 8),
                ),
                SizedBox(height: 12),
                Skeleton(height: 13),
                SizedBox(height: 8),
                Skeleton(width: 70, height: 11),
              ],
            ),
          ),
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          card(),
          const SizedBox(width: InventoryBooksSection._gap),
          card(),
          const SizedBox(width: InventoryBooksSection._gap),
          card(),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 32, color: Color(0xFFDC2626)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
