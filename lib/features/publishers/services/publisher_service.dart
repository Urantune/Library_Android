import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/publisher.dart';

// PublisherService là lớp chịu trách nhiệm lấy dữ liệu Nhà xuất bản.
// UI như PublisherListScreen hoặc PublisherDetailScreen không cần tự đọc JSON hay tự gọi API.
// UI chỉ gọi: PublisherService().getPublishers(); hoặc: PublisherService().getPublisherById(id);
// Sau đó service sẽ tự quyết định lấy dữ liệu từ MOCK hay API thật.
class PublisherService {
  // CHỌN NGUỒN DỮ LIỆU
  // ==================================================

  // Biến dùng để chọn nguồn dữ liệu.
  // true: dùng dữ liệu giả từ file JSON trong assets.
  // false: gọi API thật từ backend.
  // Hiện tại đang phát triển frontend nên đặt true để test trước mà chưa cần backend chạy.
  static const bool useMock = true;

  // URL API của Nhà xuất bản.
  // 10.0.2.2:
  // khi chạy Android Emulator, localhost của máy tính không phải 127.0.0.1 mà dùng địa chỉ đặc biệt 10.0.2.2.
  //
  // Ví dụ backend chạy: http://localhost:8080
  // Android Emulator sẽ gọi: http://10.0.2.2:8080
  static const String baseUrl = 'http://10.0.2.2:8080/api/publishers';

  // GET DANH SÁCH NHÀ XUẤT BẢN
  // ==================================================

  // Hàm public được UI gọi để lấy toàn bộ danh sách Nhà xuất bản.
  // Future<List<Publisher>>:
  // hàm không trả dữ liệu ngay lập tức, mà sẽ trả về danh sách Publisher trong tương lai.
  // async: đánh dấu hàm có xử lý bất đồng bộ.
  Future<List<Publisher>> getPublishers() async {
    // Nếu đang sử dụng dữ liệu mock.
    if (useMock) {
      // Đọc danh sách từ file JSON local.
      return _getPublishersFromMock();
    }

    // Nếu useMock = false thì gọi API backend thật.
    return _getPublishersFromApi();
  }

  // GET CHI TIẾT NHÀ XUẤT BẢN THEO ID
  // ==================================================

  // Hàm public dùng để lấy một Nhà xuất bản cụ thể.
  // Ví dụ: getPublisherById(2)
  // -> tìm Nhà xuất bản có id = 2.
  Future<Publisher> getPublisherById(int id) async {
    // Nếu đang dùng mock data.
    if (useMock) {
      return _getPublisherByIdFromMock(id);
    }

    // Nếu dùng API thật.
    return _getPublisherByIdFromApi(id);
  }

  // MOCK DATA - DANH SÁCH
  // ==================================================

  // Hàm private đọc danh sách Nhà xuất bản từ file JSON trong assets.
  // Dấu "_" ở đầu tên hàm:
  // Dart hiểu đây là thành phần private, chỉ sử dụng bên trong file/library này.
  Future<List<Publisher>> _getPublishersFromMock() async {
    // rootBundle.loadString()
    // đọc nội dung của file JSON
    // và trả về dưới dạng String.
    final jsonString = await rootBundle.loadString(
      'assets/data/publishers/duykhang.json',
    );

    // jsonDecode() chuyển chuỗi JSON thành dữ liệu Dart.
    // Vì JSON ngoài cùng là:
    // [...]
    // nên kết quả là một List<dynamic>.
    final List<dynamic> jsonList = jsonDecode(jsonString);

    // jsonList hiện tại vẫn là List các Map JSON.
    // Ta cần chuyển từng JSON thành Publisher.
    // map(): duyệt từng phần tử trong danh sách.
    // Publisher.fromJson(): chuyển Map JSON thành object Publisher.
    // toList(): chuyển kết quả map() thành List<Publisher>.
    return jsonList
        .map(
          (json) => Publisher.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // MOCK DATA - CHI TIẾT THEO ID
  // ==================================================

  // Hàm lấy một Nhà xuất bản theo ID từ danh sách fake JSON.
  Future<Publisher> _getPublisherByIdFromMock(
    int id,
  ) async {
    // Trước tiên đọc toàn bộ danh sách.
    final publishers = await _getPublishersFromMock();

    try {
      // firstWhere(): tìm phần tử đầu tiên thỏa điều kiện.
      // Điều kiện:
      // publisher.id phải bằng id được truyền vào.
      return publishers.firstWhere(
        (publisher) => publisher.id == id,
      );
    } catch (_) {
      // Nếu firstWhere không tìm thấy phần tử, nó sẽ throw lỗi.
      // Ta bắt lỗi lại và throw Exception với thông báo dễ hiểu hơn.
      throw Exception(
        'Không tìm thấy nhà xuất bản có ID = $id',
      );
    }
  }

  // API THẬT - DANH SÁCH
  // ==================================================

  // Hàm này được dùng khi: useMock = false
  // Nó gửi HTTP GET request tới backend để lấy danh sách Nhà xuất bản.
  Future<List<Publisher>> _getPublishersFromApi() async {
    // http.get(): gửi GET request tới API.
    // Uri.parse(): chuyển String URL thành Uri mà package http có thể sử dụng.
    final response = await http.get(
      Uri.parse(baseUrl),
    );

    // HTTP status code 200 nghĩa là request thành công.
    if (response.statusCode == 200) {
      // response.body: dữ liệu JSON backend trả về dưới dạng String.
      // jsonDecode(): chuyển String JSON thành dữ liệu Dart.
      final decoded = jsonDecode(response.body);

      // Giả sử API trả về dạng:
      // [
      //   {...},
      //   {...}
      // ]
      // nên ép kiểu decoded thành List<dynamic>.
      final List<dynamic> jsonList = decoded;

      // Chuyển từng JSON object thành Publisher object.
      return jsonList
          .map(
            (json) => Publisher.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    // Nếu HTTP status code không phải 200 thì coi như request thất bại.
    // Ví dụ:
    // 400 = Bad Request
    // 401 = Unauthorized
    // 404 = Not Found
    // 500 = Server Error
    // Exception này sẽ được FutureBuilder ở màn hình danh sách bắt thông qua:
    // snapshot.hasError
    throw Exception(
      'Không thể tải danh sách nhà xuất bản. '
      'Status code: ${response.statusCode}',
    );
  }

  // API THẬT - CHI TIẾT THEO ID
  // ==================================================

  // Hàm gọi API để lấy chi tiết một Nhà xuất bản cụ thể.
  // Ví dụ:
  // baseUrl:
  // http://10.0.2.2:8080/api/publishers
  // id = 3
  // URL cuối cùng:
  // http://10.0.2.2:8080/api/publishers/3
  Future<Publisher> _getPublisherByIdFromApi(
    int id,
  ) async {
    // Gửi GET request tới endpoint có ID.
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
    );

    // Nếu server trả về 200 nghĩa là tìm thấy dữ liệu.
    if (response.statusCode == 200) {
      // API chi tiết thường trả về
      // một JSON object:
      // {
      //   "id": 1,
      //   "name": "...",
      //   ...
      // }
      // nên parse thành Map<String, dynamic>.
      final Map<String, dynamic> json = jsonDecode(response.body);

      // Chuyển JSON thành Publisher object.
      return Publisher.fromJson(json);
    }

    // HTTP 404 nghĩa là: server không tìm thấy Nhà xuất bản có ID tương ứng.
    if (response.statusCode == 404) {
      throw Exception(
        'Không tìm thấy nhà xuất bản',
      );
    }

    // Các status code khác đều coi là lỗi.
    throw Exception(
      'Không thể tải chi tiết nhà xuất bản. '
      'Status code: ${response.statusCode}',
    );
  }
}
