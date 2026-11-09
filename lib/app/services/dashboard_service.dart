import 'package:flutter/material.dart';

import '../../core/auth/user_role.dart';
import '../models/book.dart';
import '../models/my_loan.dart';
import '../models/stat_item.dart';

/// Nguồn dữ liệu cho Dashboard (hiện là dữ liệu mẫu,
/// sau này thay bằng gọi API tại đây).
class DashboardService {
  /// Số liệu hiển thị theo từng vai trò.
  static List<StatItem> getStatsFor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const [
          StatItem(
            icon: Icons.menu_book_rounded,
            color: Color(0xFF2563EB),
            label: 'Tổng sách',
            value: '1,245',
            change: '+ 12% so với tháng trước',
          ),
          StatItem(
            icon: Icons.import_contacts_rounded,
            color: Color(0xFFF59E0B),
            label: 'Đang mượn',
            value: '86',
            change: '+ 33% so với tháng trước',
          ),
          StatItem(
            icon: Icons.bookmark_rounded,
            color: Color(0xFFEF4444),
            label: 'Đặt trước',
            value: '24',
            change: '+ 55% so với tháng trước',
          ),
          StatItem(
            icon: Icons.people_rounded,
            color: Color(0xFF06B6D4),
            label: 'Người dùng',
            value: '532',
            change: '+ 58% so với tháng trước',
          ),
        ];
      case UserRole.librarian:
        return const [
          StatItem(
            icon: Icons.import_contacts_rounded,
            color: Color(0xFF2563EB),
            label: 'Đang cho mượn',
            value: '86',
            change: '+ 8 phiếu hôm nay',
          ),
          StatItem(
            icon: Icons.bookmark_added_rounded,
            color: Color(0xFFF59E0B),
            label: 'Chờ duyệt đặt trước',
            value: '12',
            change: '3 yêu cầu mới',
          ),
          StatItem(
            icon: Icons.warning_amber_rounded,
            color: Color(0xFFEF4444),
            label: 'Sách quá hạn',
            value: '5',
            change: 'Cần nhắc nhở',
            changeColor: Color(0xFFEF4444),
          ),
          StatItem(
            icon: Icons.people_rounded,
            color: Color(0xFF06B6D4),
            label: 'Độc giả hoạt động',
            value: '318',
            change: '+ 14 trong tuần',
          ),
        ];
      case UserRole.member:
        return const [
          StatItem(
            icon: Icons.import_contacts_rounded,
            color: Color(0xFF2563EB),
            label: 'Sách đang mượn',
            value: '3',
            change: 'Còn 7 ngày để trả',
          ),
          StatItem(
            icon: Icons.bookmark_rounded,
            color: Color(0xFFF59E0B),
            label: 'Đặt trước',
            value: '2',
            change: '1 cuốn đã sẵn sàng',
          ),
          StatItem(
            icon: Icons.warning_amber_rounded,
            color: Color(0xFFEF4444),
            label: 'Sách quá hạn',
            value: '1',
            change: '1 cuốn cần trả sớm',
            changeColor: Color(0xFFEF4444),
          ),
          StatItem(
            icon: Icons.history_rounded,
            color: Color(0xFF06B6D4),
            label: 'Đã mượn',
            value: '27',
            change: 'Tổng cộng từ trước đến nay',
          ),
        ];
    }
  }

  /// Dữ liệu mẫu "Sách đã mượn" của người dùng hiện tại.
  /// Ngày được tính tương đối để trạng thái luôn hợp lý khi demo.
  static List<MyLoan> getMyLoans() {
    final now = DateTime.now();
    return [
      MyLoan(
        bookTitle: 'Dế Mèn phiêu lưu ký',
        author: 'Nguyễn Nhật Ánh',
        borrowedAt: now.subtract(const Duration(days: 23)),
        dueAt: now.subtract(const Duration(days: 9)),
        status: MyLoanStatus.overdue,
      ),
      MyLoan(
        bookTitle: 'Clean Code',
        author: 'Robert C. Martin',
        borrowedAt: now.subtract(const Duration(days: 7)),
        dueAt: now.add(const Duration(days: 7)),
        status: MyLoanStatus.borrowing,
      ),
      MyLoan(
        bookTitle: 'Tuổi trẻ đáng giá bao nhiêu',
        author: 'Rosie Nguyễn',
        borrowedAt: now.subtract(const Duration(days: 3)),
        dueAt: now.add(const Duration(days: 11)),
        status: MyLoanStatus.borrowing,
      ),
      MyLoan(
        bookTitle: 'Nhà giả kim',
        author: 'Paulo Coelho',
        borrowedAt: now.subtract(const Duration(days: 40)),
        dueAt: now.subtract(const Duration(days: 26)),
        returnedAt: now.subtract(const Duration(days: 25)),
        status: MyLoanStatus.returned,
      ),
      MyLoan(
        bookTitle: 'Đắc nhân tâm',
        author: 'Dale Carnegie',
        borrowedAt: now.subtract(const Duration(days: 50)),
        dueAt: now.subtract(const Duration(days: 36)),
        returnedAt: now.subtract(const Duration(days: 35)),
        status: MyLoanStatus.returned,
      ),
    ];
  }

  static List<Book> getPopularBooks() => const [
        Book('Dế Mèn phiêu lưu ký', 'Nguyễn Nhật Ánh', 30, Color(0xFF7CB342)),
        Book('Nhà giả kim', 'Paulo Coelho', 28, Color(0xFFE67E22)),
        Book('Đắc nhân tâm', 'Dale Carnegie', 25, Color(0xFF212121)),
        Book('Tuổi trẻ đáng giá bao nhiêu', 'Rosie Nguyễn', 20,
            Color(0xFF1E3A8A)),
        Book('Clean Code', 'Robert C. Martin', 18, Color(0xFF111827)),
      ];
}
