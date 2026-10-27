import 'package:dio/dio.dart';

import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../datasources/book_local_data_source.dart';
import '../datasources/book_remote_data_source.dart';

class BookRepositoryImpl implements BookRepository {
  BookRepositoryImpl(this._local, {BookRemoteDataSource? remote}) : _remote = remote;
  final BookLocalDataSource _local;
  final BookRemoteDataSource? _remote;
  @override
  Future<List<Book>> getBooks() => _useRemote(
        (remote) => remote.getBooks(),
        _local.getBooks,
      );
  @override
  Future<Book> getBookById(String id) => _useRemote(
        (remote) => remote.getBookById(id),
        () => _local.getBookById(id),
      );
  @override
  Future<void> createBook(Book book) => _useRemote(
        (remote) => remote.createBook(book).then((_) {}),
        () => _local.createBook(book),
      );
  @override
  Future<void> updateBook(Book book) => _useRemote(
        (remote) => remote.updateBook(book).then((_) {}),
        () => _local.updateBook(book),
      );
  @override
  Future<void> deleteBook(String id) => _useRemote(
        (remote) => remote.deleteBook(id),
        () => _local.deleteBook(id),
      );

  Future<T> _useRemote<T>(Future<T> Function(BookRemoteDataSource remote) online, Future<T> Function() offline) async {
    final remote = _remote;
    if (remote == null) return offline();
    try {
      return await online(remote);
    } on DioException {
      return offline();
    }
  }
}
