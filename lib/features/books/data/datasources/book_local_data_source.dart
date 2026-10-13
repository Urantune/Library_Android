import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/book.dart';

class BookLocalDataSource {
  static const _assetPath = 'assets/data/authors/urantune.json';
  List<Book>? _cache;

  Future<List<Book>> getBooks() async {
    if (_cache != null) return List.of(_cache!);
    final seed = _decode(await rootBundle.loadString(_assetPath));
    try {
      final file = await _localFile().timeout(const Duration(seconds: 3));
      if (!await file.exists()) {
        await file.parent.create(recursive: true);
        await file.writeAsString(jsonEncode(seed.map((book) => book.toJson()).toList()), flush: true);
        _cache = seed;
      } else {
        _cache = _decode(await file.readAsString());
      }
    } catch (_) {
      _cache = seed;
    }
    return List.of(_cache!);
  }

  Future<Book> getBookById(String id) async =>
      (await getBooks()).firstWhere((book) => book.id == id);

  Future<void> createBook(Book book) async {
    final books = await getBooks();
    if (books.any((item) => item.isbn == book.isbn)) {
      throw StateError('ISBN đã tồn tại.');
    }
    await _save([...books, book]);
  }

  Future<void> updateBook(Book book) async {
    final books = await getBooks();
    final index = books.indexWhere((item) => item.id == book.id);
    if (index < 0) throw StateError('Không tìm thấy sách.');
    books[index] = book;
    await _save(books);
  }

  Future<void> deleteBook(String id) async {
    final books = await getBooks();
    await _save(books.where((book) => book.id != id).toList());
  }

  List<Book> _decode(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! List) throw const FormatException('Dữ liệu sách không hợp lệ.');
    return decoded.map((item) => Book.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  Future<void> _save(List<Book> books) async {
    _cache = List.of(books);
    try {
      final file = await _localFile().timeout(const Duration(seconds: 3));
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(books.map((book) => book.toJson()).toList()), flush: true);
    } catch (_) {}
  }

  Future<File> _localFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}${Platform.pathSeparator}books${Platform.pathSeparator}urantune.json');
  }
}
