import 'package:dio/dio.dart';
import '../models/author_response.dart';

class AuthorRemoteDataSource {
  final Dio dio;
  final String baseUrl;

  AuthorRemoteDataSource({Dio? dio, this.baseUrl = 'http://localhost:8082'})
      : dio = dio ?? Dio();

  Future<PageDTO<AuthorResponse>> fetchAuthors({int page = 0, int size = 20}) async {
    final response = await dio.get('$baseUrl/api/authors', queryParameters: {
      'page': page,
      'size': size,
    });
    final data = response.data;
final pageJson = (data['result'] ?? data['data'] ?? data) as Map<String, dynamic>;
    return PageDTO<AuthorResponse>.fromJson(
      pageJson,
      (json) => AuthorResponse.fromJson(json),
    );
  }

  Future<void> createAuthor({
    required String name,
    String? bio,
    DateTime? birthDate,
    String? country,
    required String status,
  }) async {
    await dio.post(
      '$baseUrl/api/authors',
      data: {
        'name': name,
        'bio': bio,
        'birthDate': _formatDate(birthDate),
        'country': country,
        'status': status,
      },
    );
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;

    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
