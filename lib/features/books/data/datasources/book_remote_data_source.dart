import 'package:dio/dio.dart';

import '../../domain/entities/book.dart';
import '../dto/book_dto.dart';

class BookRemoteDataSource {
  BookRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<Book>> getBooks({int page = 0, int size = 100, String? query}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/books',
      queryParameters: {
        'page': page,
        'size': size,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      },
    );
    final data = _dataMap(response.data);
    final items = data['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => BookDto(Map<String, dynamic>.from(item)).toDomain())
        .toList();
  }

  Future<Book> getBookById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/books/$id');
    return BookDto(_dataMap(response.data)).toDomain();
  }

  Future<Book> createBook(Book book) async {
    final response = await _dio.post<Map<String, dynamic>>('/api/books', data: _request(book));
    return BookDto(_dataMap(response.data)).toDomain();
  }

  Future<Book> updateBook(Book book) async {
    final response = await _dio.put<Map<String, dynamic>>('/api/books/${book.id}', data: _request(book));
    return BookDto(_dataMap(response.data)).toDomain();
  }

  Future<void> deleteBook(String id) => _dio.delete<void>('/api/books/$id');

  Map<String, dynamic> _request(Book book) => {
        'title': book.title,
        'isbn': book.isbn,
        'description': book.description,
        'publicationYear': book.year == 0 ? null : book.year,
        'pageCount': null,
        'publisherId': null,
        'authorIds': const [],
        'categoryIds': const [],
        'status': 'ACTIVE',
      };

  Map<String, dynamic> _dataMap(Map<String, dynamic>? body) {
    final data = body?['data'];
    return data is Map ? Map<String, dynamic>.from(data) : const {};
  }
}
