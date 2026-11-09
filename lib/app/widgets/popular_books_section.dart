import 'package:flutter/material.dart';

import '../services/dashboard_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import 'book_card.dart';

class PopularBooksSection extends StatelessWidget {
  const PopularBooksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final books = DashboardService.getPopularBooks();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Sách được mượn nhiều',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.chevron_right, size: 18),
                label: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < books.length; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                Expanded(child: BookCard(book: books[i])),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
