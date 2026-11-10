/// Nguyen Duy Khang
/// Lưu kết quả một lượt đặt trước sách trả về từ Backend.
class Reservation {
  const Reservation({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.status,
    required this.queuePosition,
    this.copyId,
    this.readyAt,
    this.expiresAt,
    this.fulfilledAt,
    this.cancelledAt,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String bookId;
  final String status;
  final int queuePosition;
  final String? copyId;
  final DateTime? readyAt;
  final DateTime? expiresAt;
  final DateTime? fulfilledAt;
  final DateTime? cancelledAt;
  final DateTime? createdAt;

  /// Chuyển JSON trong `data` thành đối tượng dùng cho giao diện.
  factory Reservation.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString().trim() ?? '';
    final bookId = json['bookId']?.toString().trim() ?? '';
    if (id.isEmpty || bookId.isEmpty) {
      throw const FormatException('Dữ liệu đặt trước không hợp lệ.');
    }

    return Reservation(
      id: id,
      userId: json['userId']?.toString() ?? '',
      bookId: bookId,
      copyId: json['copyId']?.toString(),
      status: json['status']?.toString() ?? 'WAITING',
      queuePosition: int.tryParse('${json['queuePosition'] ?? 0}') ?? 0,
      readyAt: DateTime.tryParse(json['readyAt']?.toString() ?? ''),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
      fulfilledAt: DateTime.tryParse(json['fulfilledAt']?.toString() ?? ''),
      cancelledAt: DateTime.tryParse(json['cancelledAt']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
