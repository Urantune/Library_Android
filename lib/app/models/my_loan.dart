/// Trạng thái một lượt mượn sách của chính người dùng.
enum MyLoanStatus {
  borrowing('Đang mượn'),
  overdue('Quá hạn'),
  returned('Đã trả');

  const MyLoanStatus(this.label);

  final String label;
}

/// Lượt mượn sách hiển thị trong màn "Sách đã mượn".
///
/// Hiện là dữ liệu mẫu thuộc phạm vi home của Hiếu; khi circulation-service
/// có API thật sẽ thay bằng repository tương ứng.
class MyLoan {
  final String bookTitle;
  final String author;
  final DateTime borrowedAt;
  final DateTime dueAt;
  final DateTime? returnedAt;
  final MyLoanStatus status;

  const MyLoan({
    required this.bookTitle,
    required this.author,
    required this.borrowedAt,
    required this.dueAt,
    this.returnedAt,
    required this.status,
  });
}
