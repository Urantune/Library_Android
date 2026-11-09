import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/popular_books_section.dart';
import '../widgets/stats_row.dart';

/// Nội dung trang Dashboard.
class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Xin chào, Nguyễn Văn A 👋',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hôm nay là ngày ${now.day} tháng ${now.month}, ${now.year}',
            style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          const StatsRow(),
          const SizedBox(height: 24),
          const PopularBooksSection(),
        ],
      ),
    );
  }
}
