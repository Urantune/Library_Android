import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' show ReadContext;

import '../models/stat_item.dart';
import '../providers/dashboard_provider.dart';
import '../providers/navigation_provider.dart';
import 'stat_card.dart';

class StatsRow extends ConsumerWidget {
  const StatsRow({super.key});

  static const _books = StatItem(
    icon: Icons.menu_book_rounded,
    color: Color(0xFF2563EB),
    label: 'Sách',
    navIndex: NavIndex.book,
  );
  static const _authors = StatItem(
    icon: Icons.person_outline_rounded,
    color: Color(0xFFF59E0B),
    label: 'Tác giả',
    navIndex: NavIndex.author,
  );
  static const _categories = StatItem(
    icon: Icons.category_outlined,
    color: Color(0xFFEF4444),
    label: 'Thể loại',
    navIndex: NavIndex.category,
  );
  static const _publishers = StatItem(
    icon: Icons.apartment_rounded,
    color: Color(0xFF06B6D4),
    label: 'Nhà xuất bản',
    navIndex: NavIndex.publisher,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(booksOverviewProvider);
    final authors = ref.watch(dashboardCountProvider(CountMetric.authors));
    final categories =
        ref.watch(dashboardCountProvider(CountMetric.categories));
    final publishers =
        ref.watch(dashboardCountProvider(CountMetric.publishers));

    void open(StatItem item) =>
        context.read<NavigationProvider>().selectMenu(item.navIndex);

    final cards = <Widget Function(double)>[
      (w) => _sized(
            w,
            StatCard(
              item: _books,
              value: books.hasValue ? books.value!.total : null,
              hasError: books.hasError,
              onTap: () => open(_books),
              onRetry: () => ref.invalidate(booksOverviewProvider),
            ),
          ),
      (w) => _sized(
            w,
            StatCard(
              item: _authors,
              value: authors.hasValue ? authors.value : null,
              hasError: authors.hasError,
              onTap: () => open(_authors),
              onRetry: () => ref
                  .invalidate(dashboardCountProvider(CountMetric.authors)),
            ),
          ),
      (w) => _sized(
            w,
            StatCard(
              item: _categories,
              value: categories.hasValue ? categories.value : null,
              hasError: categories.hasError,
              onTap: () => open(_categories),
              onRetry: () => ref
                  .invalidate(dashboardCountProvider(CountMetric.categories)),
            ),
          ),
      (w) => _sized(
            w,
            StatCard(
              item: _publishers,
              value: publishers.hasValue ? publishers.value : null,
              hasError: publishers.hasError,
              onTap: () => open(_publishers),
              onRetry: () => ref
                  .invalidate(dashboardCountProvider(CountMetric.publishers)),
            ),
          ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final columns = constraints.maxWidth >= 640 ? 4 : 2;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final build in cards) build(width)],
        );
      },
    );
  }

  static Widget _sized(double width, Widget child) =>
      SizedBox(width: width, child: child);
}
