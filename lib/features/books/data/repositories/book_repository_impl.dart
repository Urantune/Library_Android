import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../datasources/book_local_data_source.dart';

class BookRepositoryImpl implements BookRepository {
  BookRepositoryImpl(this._local);
  final BookLocalDataSource _local;
  @override
  Future<List<Book>> getBooks() => _local.getBooks();
  @override
  Future<Book> getBookById(String id) => _local.getBookById(id);
  @override
  Future<void> createBook(Book book) => _local.createBook(book);
  @override
  Future<void> updateBook(Book book) => _local.updateBook(book);
  @override
  Future<void> deleteBook(String id) => _local.deleteBook(id);
}
