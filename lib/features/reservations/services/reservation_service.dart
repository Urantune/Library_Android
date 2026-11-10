import 'dart:math';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/reservation.dart';

/// Nguyen Duy Khang
/// Gọi API tạo lượt đặt trước cho sách đã hết bản sao khả dụng.
class ReservationService {
  ReservationService({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  static const _path = '/reservation/api/reservations';

  /// Lấy toàn bộ lịch sử đặt trước của người đang đăng nhập.
  Future<List<Reservation>> getMyReservations() async {
    try {
      final first = await _getReservationPage(0);
      final reservations = _parseList(first.data);
      final data = _unwrapData(first.data);
      final totalPages =
          data is Map ? int.tryParse('${data['totalPages'] ?? 1}') ?? 1 : 1;

      for (var page = 1; page < totalPages; page++) {
        final response = await _getReservationPage(page);
        reservations.addAll(_parseList(response.data));
      }
      return reservations;
    } on DioException catch (error) {
      throw Exception(_messageFor(error));
    }
  }

  /// Hủy một lượt đang chờ hoặc đã sẵn sàng nhận sách.
  Future<void> cancelReservation(String reservationId) async {
    final id = reservationId.trim();
    if (id.isEmpty) throw Exception('Mã lượt đặt trước không hợp lệ.');
    try {
      await _dio.delete<dynamic>('$_path/${Uri.encodeComponent(id)}');
    } on DioException catch (error) {
      throw Exception(_messageFor(error));
    }
  }

  /// PRM-033: Đặt trước sách hết hàng và trả về vị trí trong hàng chờ.
  Future<Reservation> createReservation(String bookId) async {
    final normalizedId = bookId.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Mã sách không hợp lệ.');
    }

    try {
      final response = await _dio.post<dynamic>(
        _path,
        data: {'bookId': normalizedId},
        options: Options(headers: {'Idempotency-Key': _newIdempotencyKey()}),
      );
      return _parse(response.data);
    } on DioException catch (error) {
      throw Exception(_messageFor(error));
    }
  }

  Reservation _parse(dynamic body) {
    final data = _unwrapData(body);
    if (data is! Map) {
      throw const FormatException('Phản hồi đặt trước không hợp lệ.');
    }
    return Reservation.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Future<Response<dynamic>> _getReservationPage(int page) => _dio.get<dynamic>(
        '$_path/me',
        queryParameters: {'page': page, 'size': 100},
      );

  dynamic _unwrapData(dynamic body) => body is Map ? body['data'] : null;

  List<Reservation> _parseList(dynamic body) {
    final data = _unwrapData(body);
    final items = data is Map ? data['items'] : null;
    if (items is! List) {
      throw const FormatException('Danh sách đặt trước không hợp lệ.');
    }
    return items.map((item) {
      if (item is! Map) {
        throw const FormatException('Thông tin đặt trước không hợp lệ.');
      }
      return Reservation.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  String _messageFor(DioException error) {
    final body = error.response?.data;
    final code = body is Map ? body['code']?.toString() : null;

    if (code == 'DUPLICATE_ACTIVE_RESERVATION') {
      return 'Bạn đã có một lượt đặt trước đang hoạt động cho sách này.';
    }
    if (code == 'BOOK_COPIES_AVAILABLE') {
      return 'Sách vừa có bản khả dụng, bạn có thể mượn trực tiếp.';
    }
    if (code == 'RESERVATION_NOT_CANCELLABLE') {
      return 'Lượt đặt trước này không thể hủy.';
    }
    if (code == 'RESERVATION_NOT_FOUND') {
      return 'Không tìm thấy lượt đặt trước.';
    }

    return switch (error.response?.statusCode) {
      400 => 'Thông tin đặt trước không hợp lệ.',
      401 => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      403 => 'Bạn không có quyền đặt trước sách.',
      404 => 'Không tìm thấy sách cần đặt trước.',
      409 => 'Không thể đặt trước sách này ở thời điểm hiện tại.',
      502 ||
      503 ||
      504 =>
        'Dịch vụ đặt trước chưa sẵn sàng. Vui lòng thử lại sau.',
      _ => switch (error.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.receiveTimeout ||
          DioExceptionType.sendTimeout =>
            'Kết nối quá thời gian. Vui lòng thử lại.',
          DioExceptionType.connectionError =>
            'Không thể kết nối dịch vụ đặt trước.',
          _ => 'Không thể đặt trước sách. Vui lòng thử lại.',
        },
    };
  }

  /// Tạo UUID v4 để Backend nhận biết và chống gửi trùng một thao tác.
  String _newIdempotencyKey() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final value = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    final hex = value.join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
