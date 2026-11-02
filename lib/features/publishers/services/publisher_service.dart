import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/publisher.dart';

// PRM-023 + PRM-024: PUBLISHER SERVICE
// =====================================================

class PublisherService {
  // Sử dụng Dio được cấu hình sẵn trong project.
  // catalogDio dùng để giao tiếp với Catalog Service.
  // Không tạo một Dio mới vì project đã có ApiClient quản lý cấu hình kết nối Backend.
  final Dio dio = ApiClient.catalogDio;

  // ===================================================
  // METHOD 1: GET DANH SÁCH NHÀ XUẤT BẢN
  // API: GET /api/publishers
  // ===================================================

  Future<List<Publisher>> getPublishers() async {
    // Gửi GET Request đến Backend.
    final response = await dio.get('/api/publishers');

    // Lấy dữ liệu JSON từ Response.
    dynamic data = response.data;

    // Backend của project sử dụng ResponseAPI có trường result chứa dữ liệu thực tế.
    if (data is Map && data['result'] != null) {
      data = data['result'];
    }

    // Một số API có thể bọc dữ liệu bên trong trường data.
    if (data is Map && data['data'] != null) {
      data = data['data'];
    }

    // Xử lý trường hợp Backend trả dữ liệu phân trang.
    if (data is Map) {
      data = data['content'] ?? data['items'] ?? data['publishers'];
    }

    // Kiểm tra dữ liệu sau khi xử lý có phải List không.
    if (data is! List) {
      throw Exception('Dữ liệu danh sách không hợp lệ');
    }

    // Chuyển từng phần tử JSON thành Publisher Object.
    return data.map((item) {
      return Publisher.fromJson(
        Map<String, dynamic>.from(item),
      );
    }).toList();
  }

  // ===================================================
  // METHOD 2: GET CHI TIẾT NHÀ XUẤT BẢN
  // API: GET /api/publishers/{id}
  // ===================================================

  Future<Publisher> getPublisherById(int id) async {
    // Gửi GET Request đến API chi tiết.
    //
    // Ví dụ id = 1:
    // GET /api/publishers/1
    final response = await dio.get('/api/publishers/$id');

    // Lấy dữ liệu JSON từ Backend.
    dynamic data = response.data;

    // Lấy dữ liệu bên trong trường result nếu Backend sử dụng ResponseAPI.
    if (data is Map && data['result'] != null) {
      data = data['result'];
    }

    // Xử lý trường hợp dữ liệu được bọc trong data.
    if (data is Map && data['data'] != null) {
      data = data['data'];
    }

    // Kiểm tra dữ liệu có đúng kiểu Map không.
    if (data is! Map) {
      throw Exception('Dữ liệu nhà xuất bản không hợp lệ');
    }

    // Chuyển JSON thành đối tượng Publisher.
    return Publisher.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  // ===================================================
  // METHOD 3: CREATE NHÀ XUẤT BẢN - PRM-024
  // API: POST /api/publishers
  // ===================================================

  Future<void> createPublisher({
    required String name,
    String address = '',
    String email = '',
    String phone = '',
  }) async {
    // BƯỚC 1: Chuẩn bị dữ liệu gửi lên Backend.
    //
    // name: Tên nhà xuất bản (bắt buộc).
    // address: Địa chỉ (không bắt buộc).
    // email: Email (không bắt buộc).
    // phone: Số điện thoại (không bắt buộc).
    //
    // Không gửi id, status, created_at, updated_at.
    // Những trường này do Backend quản lý.

    final Map<String, dynamic> requestBody = {
      'name': name.trim(),

      // Chỉ gửi các trường tùy chọn nếu người dùng có nhập.
      if (address.trim().isNotEmpty) 'address': address.trim(),

      if (email.trim().isNotEmpty) 'email': email.trim(),

      if (phone.trim().isNotEmpty) 'phone': phone.trim(),
    };

    try {
      // BƯỚC 2: Gửi POST Request đến Backend.
      //
      // dio: Dio instance đã cấu hình ở đầu class.
      // data: requestBody sẽ được Dio chuyển thành JSON.
      //
      // Endpoint giống cấu trúc đang sử dụng ở hai hàm GET.

      final response = await dio.post(
        '/api/publishers',
        data: requestBody,
      );

      // BƯỚC 3: Kiểm tra kết quả trả về.
      //
      // 201: Created - Tạo thành công.
      // 200: OK - Một số Backend sử dụng mã này.

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception(
          'Không thể tạo nhà xuất bản',
        );
      }

      // Nếu chạy đến đây nghĩa là tạo thành công.
      // Trả về void vì màn hình Form chỉ cần biết
      // thao tác tạo mới đã hoàn thành.
    } on DioException catch (e) {
      // BƯỚC 4: Lấy HTTP Status Code khi có lỗi.

      final statusCode = e.response?.statusCode;

      // BƯỚC 5: Xử lý từng loại lỗi từ Backend.

      switch (statusCode) {
        case 400:
          throw Exception(
            'Dữ liệu nhà xuất bản không hợp lệ',
          );

        case 401:
          throw Exception(
            'Phiên đăng nhập đã hết hạn',
          );

        case 403:
          throw Exception(
            'Bạn không có quyền thêm nhà xuất bản',
          );

        case 404:
          throw Exception(
            'Không tìm thấy API tạo nhà xuất bản',
          );

        case 409:
          throw Exception(
            'Nhà xuất bản đã tồn tại',
          );

        case 500:
          throw Exception(
            'Backend gặp lỗi khi tạo nhà xuất bản',
          );

        case 503:
          throw Exception(
            'Catalog Service hiện không khả dụng',
          );

        default:
          throw Exception(
            'Lỗi kết nối Backend: ${e.message}',
          );
      }
    }
  }
}
