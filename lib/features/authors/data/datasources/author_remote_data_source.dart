import 'dart:convert';
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
}
