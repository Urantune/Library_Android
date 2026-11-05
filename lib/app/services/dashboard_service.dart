import 'package:dio/dio.dart';

import '../../features/books/data/dto/book_dto.dart';
import '../../features/books/domain/entities/book.dart';

class BooksOverview {
  const BooksOverview({required this.total, required this.items});

  final int total;
  final List<Book> items;
}

class DashboardService {
  DashboardService({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  Future<BooksOverview> fetchBooksOverview({int limit = 5}) async {
    final response = await _dio.get<dynamic>(
      '/api/books',
      queryParameters: {'page': 0, 'size': limit},
    );
    final data = _unwrap(response.data);
    final books = (_itemsOf(data) ?? const <dynamic>[])
        .whereType<Map>()
        .map((e) => BookDto(Map<String, dynamic>.from(e)).toDomain())
        .toList();
    return BooksOverview(total: _totalOf(data) ?? books.length, items: books);
  }

  Future<int> countAuthors() => _count('/api/authors');

  Future<int> countCategories() =>
      _count('/api/categories', const {'status': 'ACTIVE'});

  Future<int> countPublishers() => _count('/api/publishers');

  Future<int> _count(
    String path, [
    Map<String, dynamic> query = const {},
  ]) async {
    final first = await _dio.get<dynamic>(
      path,
      queryParameters: {...query, 'page': 0, 'size': 1},
    );
    final total = _totalOf(_unwrap(first.data));
    if (total != null) return total;

    final all = await _dio.get<dynamic>(
      path,
      queryParameters: {...query, 'page': 0, 'size': 100},
    );
    return _itemsOf(_unwrap(all.data))?.length ?? 0;
  }

  dynamic _unwrap(dynamic body) {
    var current = body;
    for (var i = 0; i < 4; i++) {
      if (current is Map && current['data'] != null) {
        current = current['data'];
      } else if (current is Map && current['result'] != null) {
        current = current['result'];
      } else {
        break;
      }
    }
    return current;
  }

  List<dynamic>? _itemsOf(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final items = data['items'] ?? data['content'];
      if (items is List) return items;
    }
    return null;
  }

  int? _totalOf(dynamic data) {
    if (data is! Map) return null;
    final raw = data['totalElements'] ?? data['total'];
    if (raw == null) return null;
    return raw is num ? raw.toInt() : int.tryParse('$raw');
  }
}
