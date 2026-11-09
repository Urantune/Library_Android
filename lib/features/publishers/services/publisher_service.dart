import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/publisher.dart';

/// Nguyen Duy Khang - CE192012
/// Service xử lý gọi API kết nối Backend cho chức năng Quản lý nhà xuất bản
/// Phụ trách PRM-023 (Lấy danh sách, xem chi tiết) và PRM-024 (Tạo mới nhà xuất bản)
class PublisherService {
  // Dio client dùng chung của app (đã tích hợp TokenStorage và AuthInterceptor tự đính kèm JWT)
  final Dio _dio;

  PublisherService({Dio? dio}) : _dio = dio ?? ApiClient.catalogDio;

  // =========================================================
  // BỘ BÓC TÁCH VÀ PARSE DỮ LIỆU RESPONSE TỪ BACKEND
  // =========================================================

  /// Bóc tách phần dữ liệu bên trong envelope của API Backend ({ "status": 200, "data": ... })
  dynamic _unwrap(dynamic value) {
    if (value is Map) {
      if (value['data'] != null) return value['data'];
      if (value['result'] != null) return value['result'];
    }
    return value;
  }

  /// Chuyển đổi dữ liệu JSON trả về thành danh sách List<Publisher>
  List<Publisher> _parsePublisherList(dynamic response) {
    final data = _unwrap(response);
    dynamic items;

    if (data is List) {
      items = data;
    } else if (data is Map) {
      // Backend PageResponse trả về danh sách trong thuộc tính 'items' hoặc 'content'
      items = data['items'] ?? data['content'] ?? data['publishers'];
    }

    if (items is! List) {
      throw const FormatException('Response danh sách nhà xuất bản không hợp lệ.');
    }

    return items.map((item) {
      if (item is! Map) {
        throw const FormatException('Thông tin nhà xuất bản không hợp lệ.');
      }
      return Publisher.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  /// Chuyển đổi dữ liệu JSON chi tiết thành một đối tượng Publisher
  Publisher _parsePublisher(dynamic response) {
    final data = _unwrap(response);

    if (data is! Map) {
      throw const FormatException('Response chi tiết nhà xuất bản không hợp lệ.');
    }

    return Publisher.fromJson(Map<String, dynamic>.from(data));
  }

  // =========================================================
  // XỬ LÝ VÀ CHUYỂN ĐỔI THÔNG BÁO LỖI (ERROR HANDLING)
  // =========================================================

  /// Phân tích lỗi từ DioException để trả về câu thông báo thân thiện bằng tiếng Việt
  String _errorMessage(DioException error) {
    // Xử lý mã lỗi trùng tên nhà xuất bản từ server trả về (409 Conflict)
    if (error.response?.statusCode == 409) {
      return 'Tên nhà xuất bản đã tồn tại trong hệ thống.';
    }

    final responseData = error.response?.data;
    if (responseData is Map) {
      final message = responseData['message'] ??
          responseData['error'] ??
          responseData['detail'] ??
          responseData['reason'];

      if (message != null) {
        return message.toString();
      }
    }

    // Xử lý lỗi kết nối mạng và timeout
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Kết nối đến máy chủ quá thời gian chờ.';

      case DioExceptionType.connectionError:
        return 'Không thể kết nối Backend. Vui lòng kiểm tra server và mạng.';

      default:
        return error.message ?? 'Đã xảy ra lỗi khi xử lý nhà xuất bản.';
    }
  }

  // =========================================================
  // PRM-023: LẤY DANH SÁCH NHÀ XUẤT BẢN (GET LIST)
  // =========================================================

  /// Gọi API GET /api/publishers để lấy danh sách tất cả nhà xuất bản
  Future<List<Publisher>> getPublishers() async {
    try {
      final response = await _dio.get(
        '/api/publishers',
        queryParameters: {
          'page': 0,
          'size': 100, // Lấy số lượng vừa đủ hiển thị danh sách
        },
      );

      return _parsePublisherList(response.data);
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    }
  }

  // =========================================================
  // PRM-023: XEM CHI TIẾT NHÀ XUẤT BẢN (GET DETAIL)
  // =========================================================

  /// Gọi API GET /api/publishers/{id} để lấy thông tin chi tiết một nhà xuất bản theo ID
  Future<Publisher> getPublisherById(String id) async {
    try {
      final response = await _dio.get(
        '/api/publishers/$id',
      );

      return _parsePublisher(response.data);
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    }
  }

  // =========================================================
  // PRM-024: THÊM NHÀ XUẤT BẢN MỚI (CREATE PUBLISHER)
  // =========================================================

  /// Gọi API POST /api/publishers với map dữ liệu JSON
  Future<Publisher> createPublisher(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        '/api/publishers',
        data: data,
      );

      return _parsePublisher(response.data);
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    }
  }

  /// Hàm tiện ích tạo nhà xuất bản với từng tham số cụ thể, tự loại bỏ trường trống
  Future<Publisher> createPublisherData({
    required String name,
    String? address,
    String? phone,
    String? email,
    String? website,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (website != null && website.trim().isNotEmpty) 'website': website.trim(),
    };

    return createPublisher(payload);
  }

  // =========================================================
  // CẬP NHẬT & XÓA NHÀ XUẤT BẢN (HỖ TRỢ CHO TOÀN BỘ CRUD)
  // =========================================================

  /// Gọi API PUT /api/publishers/{id} để cập nhật thông tin nhà xuất bản
  Future<Publisher> updatePublisher(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(
        '/api/publishers/$id',
        data: data,
      );

      return _parsePublisher(response.data);
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    }
  }

  /// Gọi API DELETE /api/publishers/{id} để xóa nhà xuất bản
  Future<void> deletePublisher(String id) async {
    try {
      await _dio.delete(
        '/api/publishers/$id',
      );
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    }
  }
}
