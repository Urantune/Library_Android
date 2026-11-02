import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/publisher.dart';

// PRM-023: GET LIST / DETAIL PUBLISHER
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
    // await: Chờ Backend phản hồi dữ liệu.
    // response: Chứa dữ liệu mà Backend trả về.
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
    //
    // content: Danh sách dữ liệu phân trang.
    // items: Một dạng danh sách khác.
    // publishers: Danh sách nhà xuất bản.
    if (data is Map) {
      data = data['content'] ?? data['items'] ?? data['publishers'];
    }

    // Kiểm tra dữ liệu sau khi xử lý có phải List không.
    // Nếu không phải List thì dữ liệu không đúng định dạng.
    if (data is! List) {
      throw Exception('Dữ liệu danh sách không hợp lệ');
    }

    // Chuyển từng phần tử JSON thành Publisher Object.
    //
    // data.map(): Duyệt qua từng phần tử trong danh sách.
    // Publisher.fromJson(): Chuyển JSON thành Publisher.
    // toList(): Chuyển kết quả thành List<Publisher>.
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
    // Vì chi tiết một nhà xuất bản là một Object, không phải một danh sách List.
    if (data is! Map) {
      throw Exception('Dữ liệu nhà xuất bản không hợp lệ');
    }

    // Chuyển JSON thành đối tượng Publisher.
    return Publisher.fromJson(
      Map<String, dynamic>.from(data),
    );
  }
}
