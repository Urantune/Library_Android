import 'package:dio/dio.dart';

import '../../../core/api_client.dart';
import '../models/author.dart';

class AuthorService {
  final Dio _dio;
  AuthorService([Dio? dio]) : _dio = dio ?? ApiClient.dio;
  // AuthorService(this._dio);

  Future<List<Author>> getAuthors() async {
    final response = await _dio.get('/api/authors');
    final dynamic body = response.data;

    final dynamic data =
        body is Map<String, dynamic> && body.containsKey('data')
        ? body['data']
        : body;

    final dynamic items = data is Map<String, dynamic> ? data['content'] : data;

    if (items is! List) {
      throw const FormatException(
        'API danh sách tác giả phải trả về List hoặc data.content.',
      );
    }

    return items
        .map((item) => Author.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Author> getAuthorById(String id) async {
    final response = await _dio.get('/api/authors/${Uri.encodeComponent(id)}');

    final dynamic body = response.data;
    final dynamic data =
        body is Map<String, dynamic> && body.containsKey('data')
        ? body['data']
        : body;

    if (data is! Map) {
      throw const FormatException(
        'API chi tiết tác giả phải trả về một object.',
      );
    }

    return Author.fromJson(Map<String, dynamic>.from(data));
  }
}
