import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/publisher.dart';

/// Gọi API nhà xuất bản cho các chức năng xem, thêm, sửa và xóa.
class PublisherService {
  // ApiClient tự gắn access token vào mỗi request.
  final Dio _dio;

  PublisherService({Dio? dio}) : _dio = dio ?? ApiClient.catalogDio;

  /// Gửi request có token trước. Nếu catalog local không xác thực được token,
  /// thử lại không có token; Backend production vẫn tự quyết định có cho phép hay không.
  Future<Response<dynamic>> _request(
    Future<Response<dynamic>> Function() authenticated,
    Future<Response<dynamic>> Function() anonymous,
  ) async {
    try {
      return await authenticated();
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) rethrow;
      return anonymous();
    }
  }

  Options get _skipAuth => Options(extra: const {'skipAuth': true});

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

  /// Chuyển dữ liệu JSON thành danh sách `Publisher`.
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
      throw const FormatException(
          'Response danh sách nhà xuất bản không hợp lệ.');
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
      throw const FormatException(
          'Response chi tiết nhà xuất bản không hợp lệ.');
    }

    return Publisher.fromJson(Map<String, dynamic>.from(data));
  }

  // =========================================================
  // XỬ LÝ VÀ CHUYỂN ĐỔI THÔNG BÁO LỖI (ERROR HANDLING)
  // =========================================================

  /// Chuyển lỗi mạng/API thành thông báo ngắn gọn cho người dùng.
  String _errorMessage(DioException error) {
    if (error.response?.statusCode == 401) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }
    if (error.response?.statusCode == 403) {
      return 'Bạn không có quyền quản lý nhà xuất bản.';
    }
    if (error.response?.statusCode == 409) {
      return 'Tên nhà xuất bản đã tồn tại trong hệ thống.';
    }

    // Xử lý mã lỗi không tìm thấy tài nguyên (404 Not Found)
    if (error.response?.statusCode == 404) {
      return 'Không tìm thấy nhà xuất bản.';
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

  /// PRM-023: Lấy toàn bộ nhà xuất bản đang hoạt động.
  Future<List<Publisher>> getPublishers() async {
    try {
      const firstPage = {'status': 'ACTIVE', 'page': 0, 'size': 100};
      final response = await _request(
        () => _dio.get('/api/publishers', queryParameters: firstPage),
        () => _dio.get(
          '/api/publishers',
          queryParameters: firstPage,
          options: _skipAuth,
        ),
      );

      final publishers = _parsePublisherList(response.data);
      final pageData = _unwrap(response.data);
      final totalPages =
          pageData is Map ? int.tryParse('${pageData['totalPages']}') ?? 1 : 1;

      // Backend giới hạn 100 bản ghi/trang nên cần tải các trang còn lại.
      for (var page = 1; page < totalPages; page++) {
        final query = {'status': 'ACTIVE', 'page': page, 'size': 100};
        final nextResponse = await _request(
          () => _dio.get('/api/publishers', queryParameters: query),
          () => _dio.get(
            '/api/publishers',
            queryParameters: query,
            options: _skipAuth,
          ),
        );
        publishers.addAll(_parsePublisherList(nextResponse.data));
      }
      return publishers;
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    }
  }

  // =========================================================
  // PRM-023: XEM CHI TIẾT NHÀ XUẤT BẢN (GET DETAIL)
  // =========================================================

  /// PRM-023: Lấy chi tiết theo ID.
  Future<Publisher> getPublisherById(String id) async {
    try {
      final safeId = Uri.encodeComponent(id);
      final path = '/api/publishers/$safeId';
      final response = await _request(
        () => _dio.get(path),
        () => _dio.get(path, options: _skipAuth),
      );

      return _parsePublisher(response.data);
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    }
  }

  // =========================================================
  // PRM-024: THÊM NHÀ XUẤT BẢN MỚI (CREATE PUBLISHER)
  // =========================================================

  /// PRM-024: Tạo nhà xuất bản mới.
  Future<Publisher> createPublisher(Map<String, dynamic> data) async {
    try {
      final response = await _request(
        () => _dio.post('/api/publishers', data: data),
        () => _dio.post(
          '/api/publishers',
          data: data,
          options: _skipAuth,
        ),
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
    String status = 'ACTIVE',
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      if (address != null && address.trim().isNotEmpty)
        'address': address.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (website != null && website.trim().isNotEmpty)
        'website': website.trim(),
      'status': status,
    };

    return createPublisher(payload);
  }

  // =========================================================
  // PRM-025: CẬP NHẬT THÔNG TIN NHÀ XUẤT BẢN (UPDATE PUBLISHER)
  // =========================================================

  /// PRM-025: Cập nhật nhà xuất bản theo ID.
  Future<Publisher> updatePublisher(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final safeId = Uri.encodeComponent(id);
      final path = '/api/publishers/$safeId';
      final response = await _request(
        () => _dio.put(path, data: data),
        () => _dio.put(path, data: data, options: _skipAuth),
      );

      return _parsePublisher(response.data);
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    }
  }

  /// Hàm tiện ích cập nhật thông tin nhà xuất bản với từng tham số cụ thể (PRM-025)
  Future<Publisher> updatePublisherData({
    required String id,
    required String name,
    String? address,
    String? phone,
    String? email,
    String? website,
    String status = 'ACTIVE',
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      if (address != null && address.trim().isNotEmpty)
        'address': address.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (website != null && website.trim().isNotEmpty)
        'website': website.trim(),
      'status': status,
    };

    return updatePublisher(id, payload);
  }

  // =========================================================
  // PRM-026: XÓA NHÀ XUẤT BẢN (DELETE PUBLISHER)
  // =========================================================

  /// PRM-026: Xóa mềm; Backend đổi trạng thái thành INACTIVE.
  Future<void> deletePublisher(String id) async {
    try {
      final safeId = Uri.encodeComponent(id);
      final path = '/api/publishers/$safeId';
      await _request(
        () => _dio.delete(path),
        () => _dio.delete(path, options: _skipAuth),
      );
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    }
  }
}
