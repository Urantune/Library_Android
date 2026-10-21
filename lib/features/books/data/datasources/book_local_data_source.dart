import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/book.dart';
import '../../domain/entities/book_validation.dart';

class BookLocalDataSource {
  BookLocalDataSource({
    Future<File> Function()? fileResolver,
    Future<String> Function()? seedLoader,
  })  : _fileResolver = fileResolver,
        _seedLoader = seedLoader;

  static const _assetPath = 'assets/data/authors/urantune.json';
  final Future<File> Function()? _fileResolver;
  final Future<String> Function()? _seedLoader;
  List<Book>? _cache;
  Future<List<Book>>? _loading;
  Future<void> _writes = Future.value();

  Future<List<Book>> getBooks() async {
    if (_cache != null) return List.of(_cache!);
    _loading ??= _load().whenComplete(() => _loading = null);
    return List.of(await _loading!);
  }

  Future<List<Book>> _load() async {
    File file;
    try {
      file = await _localFile().timeout(const Duration(seconds: 3));
    } on MissingPluginException {
      return _cache = await _seed();
    } on PlatformException {
      return _cache = await _seed();
    } on TimeoutException {
      return _cache = await _seed();
    }
    if (await file.exists()) {
      return _cache = _decode(await file.readAsString());
    }
    final seed = await _seed();
    await _save(seed);
    return seed;
  }

  Future<List<Book>> _seed() async =>
      _decode(await (_seedLoader?.call() ?? rootBundle.loadString(_assetPath)));

  Future<Book> getBookById(String id) async => (await getBooks()).firstWhere(
        (book) => book.id == id,
        orElse: () => throw StateError('Không tìm thấy sách.'),
      );

  Future<void> createBook(Book book) => _mutate((books) {
        _validate(book, books);
        if (books.any((item) => item.id == book.id)) {
          throw StateError('Mã sách đã tồn tại.');
        }
        return [...books, book];
      });

  Future<void> updateBook(Book book) => _mutate((books) {
        final index = books.indexWhere((item) => item.id == book.id);
        if (index < 0) throw StateError('Không tìm thấy sách.');
        _validate(book, books);
        return [...books]..[index] = book;
      });

  Future<void> deleteBook(String id) => _mutate((books) {
        if (!books.any((book) => book.id == id)) {
          throw StateError('Không tìm thấy sách.');
        }
        return books.where((book) => book.id != id).toList();
      });

  void _validate(Book book, List<Book> books) {
    final errors = BookValidation.validate(book);
    if (errors.isNotEmpty) throw StateError(errors.values.first);
    final isbn = BookValidation.normalizeIsbn(book.isbn);
    if (books.any((item) =>
        item.id != book.id &&
        BookValidation.normalizeIsbn(item.isbn) == isbn)) {
      throw StateError('ISBN đã tồn tại.');
    }
  }

  Future<void> _mutate(List<Book> Function(List<Book>) transform) {
    final result = _writes.then((_) async {
      final current = await getBooks();
      await _save(transform(current));
    });
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  List<Book> _decode(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! List) {
      throw const FormatException('Dữ liệu sách không hợp lệ.');
    }
    return decoded
        .map((item) => Book.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> _save(List<Book> books) async {
    final file = await _localFile().timeout(const Duration(seconds: 3));
    await file.parent.create(recursive: true);
    final pending =
        File('${file.path}.${DateTime.now().microsecondsSinceEpoch}.tmp');
    try {
      await pending.writeAsString(
          jsonEncode(books.map((book) => book.toJson()).toList()),
          flush: true);
      await pending.rename(file.path);
      _cache = List.of(books);
    } finally {
      if (await pending.exists()) await pending.delete();
    }
  }

  Future<File> _localFile() async {
    if (_fileResolver != null) return _fileResolver!();
    final directory = await getApplicationSupportDirectory();
    return File(
        '${directory.path}${Platform.pathSeparator}books${Platform.pathSeparator}urantune.json');
  }
}
