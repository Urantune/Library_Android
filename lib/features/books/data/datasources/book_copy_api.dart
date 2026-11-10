import 'package:dio/dio.dart';
import '../../domain/entities/book_copy.dart';

class BookCopyRemoteDataSource {
  BookCopyRemoteDataSource(this._dio);
  final Dio _dio;

  String _path(String bookId) => '/api/books/${Uri.encodeComponent(bookId)}/copies';

  Future<List<BookCopy>> list(String bookId) async {
    final response = await _dio.get<Map<String, dynamic>>(_path(bookId));
    final data = response.data?['data'];
    if (data is! List) throw const FormatException('Dữ liệu cuốn sách không hợp lệ.');
    return data.whereType<Map>().map((item) => BookCopy.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  Future<void> create(String bookId, String code, String shelf) async {
    await _dio.post(_path(bookId), data: {'code': code, 'shelfLocation': shelf});
  }

  Future<void> setStatus(String bookId, String copyId, String status) async {
    await _dio.patch('${_path(bookId)}/${Uri.encodeComponent(copyId)}/status', data: {'status': status});
  }
}
