import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/sign/controllers/auth_controller.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/inventory_books_section.dart';
import '../widgets/stats_row.dart';

class DashboardHome extends ConsumerWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider.select((s) => s.user));
    final fullName = user?.fullName.trim() ?? '';
    final name = fullName.isNotEmpty ? fullName : (user?.fullName ?? '');

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name.isEmpty ? 'Xin chào' : 'Xin chào, $name',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _todayLabel(DateTime.now()),
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            const StatsRow(),
            const SizedBox(height: 20),
            const InventoryBooksSection(),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(booksOverviewProvider);
    ref.invalidate(dashboardCountProvider);

    Future<void> settle(Future<Object?> f) =>
        f.then<void>((_) {}, onError: (_) {});

    await Future.wait([
      settle(ref.read(booksOverviewProvider.future)),
      for (final metric in CountMetric.values)
        settle(ref.read(dashboardCountProvider(metric).future)),
    ]);
  }

  static String _todayLabel(DateTime d) {
    const weekdays = [
      'Thứ hai',
      'Thứ ba',
      'Thứ tư',
      'Thứ năm',
      'Thứ sáu',
      'Thứ bảy',
      'Chủ nhật',
    ];
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '${weekdays[d.weekday - 1]}, $dd/$mm/${d.year}';
  }
}
