import 'package:flutter/material.dart';

import '../../features/books/domain/entities/book.dart';

class BookCard extends StatelessWidget {
  const BookCard({super.key, required this.book});

  final Book book;

  static const _palette = [
    Color(0xFF2563EB),
    Color(0xFF0EA5E9),
    Color(0xFF14B8A6),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF475569),
  ];

  Color get _coverColor {
    final seed = book.title.codeUnits.fold<int>(0, (a, b) => a + b);
    return _palette[seed % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final author =
        book.author.trim().isEmpty ? 'Chưa rõ tác giả' : book.author;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Container(
              decoration: BoxDecoration(
                color: _coverColor,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              child: Text(
                book.title,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          if (book.quantity > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Còn ${book.available}/${book.quantity} cuốn',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2563EB),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
