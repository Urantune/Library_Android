import 'package:dio/dio.dart';

import '../../domain/entities/book.dart';
import '../../domain/entities/book_page.dart';
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

  Future<BookPage> getBookPage({
    int page = 0,
    int size = 10,
    String? query,
    String? publisherId,
    String? authorId,
    String? categoryId,
    String? copyStatus,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/books',
      queryParameters: {
        'page': page,
        'size': size,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (publisherId != null && publisherId.trim().isNotEmpty) 'publisherId': publisherId.trim(),
        if (authorId != null && authorId.trim().isNotEmpty) 'authorId': authorId.trim(),
        if (categoryId != null && categoryId.trim().isNotEmpty) 'categoryId': categoryId.trim(),
        if (copyStatus != null && copyStatus.isNotEmpty) 'copyStatus': copyStatus,
      },
    );
    final data = _dataMap(response.data);
    final items = data['items'];
    final bookList = (items is List)
        ? items
            .whereType<Map>()
            .map((item) => BookDto(Map<String, dynamic>.from(item)).toDomain())
            .toList()
        : <Book>[];
    final totalElements = (data['totalElements'] as num?)?.toInt() ?? bookList.length;
    final totalPages = (data['totalPages'] as num?)?.toInt() ?? (totalElements == 0 ? 1 : (totalElements / size).ceil());
    final currentPage = (data['page'] as num?)?.toInt() ?? page;

    return BookPage(
      items: bookList,
      page: currentPage,
      size: size,
      totalElements: totalElements,
      totalPages: totalPages == 0 && bookList.isNotEmpty ? 1 : totalPages,
    );
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
        'pageCount': book.pageCount,
        'language': book.language.isEmpty ? null : book.language,
        'coverUrl': book.coverUrl.isEmpty ? null : book.coverUrl,
        'publisherId': (book.publisherId == null || book.publisherId!.trim().isEmpty) ? null : book.publisherId!.trim(),
        'authorIds': book.authorIds,
        'categoryIds': book.categoryIds,
        'status': book.status.isEmpty ? 'ACTIVE' : book.status,
      };

  Map<String, dynamic> _dataMap(Map<String, dynamic>? body) {
    final data = body?['data'];
    return data is Map ? Map<String, dynamic>.from(data) : const {};
  }
}
