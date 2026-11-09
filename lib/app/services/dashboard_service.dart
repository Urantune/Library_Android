import 'package:flutter/material.dart';

import '../models/book.dart';
import '../models/stat_item.dart';

/// Nguồn dữ liệu cho Dashboard (hiện là dữ liệu mẫu,
/// sau này thay bằng gọi API tại đây).
class DashboardService {
  static List<StatItem> getStats() => const [
        StatItem(
          icon: Icons.menu_book_rounded,
          color: Color(0xFF2563EB),
          label: 'Tổng sách',
          value: '1,245',
          change: '+ 12%',
        ),
        StatItem(
          icon: Icons.import_contacts_rounded,
          color: Color(0xFFF59E0B),
          label: 'Đang mượn',
          value: '86',
          change: '+ 33%',
        ),
        StatItem(
          icon: Icons.bookmark_rounded,
          color: Color(0xFFEF4444),
          label: 'Đặt trước',
          value: '24',
          change: '+ 55%',
        ),
        StatItem(
          icon: Icons.person_rounded,
          color: Color(0xFF06B6D4),
          label: 'Người dùng',
          value: '532',
          change: '+ 58%',
        ),
      ];

  static List<Book> getPopularBooks() => const [
        Book('Dế Mèn phiêu lưu ký', 'Nguyễn Nhật Ánh', 30, Color(0xFF7CB342)),
        Book('Nhà giả kim', 'Paulo Coelho', 28, Color(0xFFE67E22)),
        Book('Đắc nhân tâm', 'Dale Carnegie', 25, Color(0xFF212121)),
        Book('Tuổi trẻ đáng giá bao nhiêu', 'Rosie Nguyễn', 20,
            Color(0xFF1E3A8A)),
        Book('Clean Code', 'Robert C. Martin', 18, Color(0xFF111827)),
      ];
}
