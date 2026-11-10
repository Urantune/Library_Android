import '../../domain/entities/book.dart';
import '../../domain/entities/book_page.dart';
import '../../domain/repositories/book_repository.dart';
import '../datasources/book_remote_data_source.dart';

class BookRepositoryImpl implements BookRepository {
  BookRepositoryImpl(this._remote);
  final BookRemoteDataSource _remote;

  @override
  Future<List<Book>> getBooks() => _remote.getBooks();
  @override
  Future<BookPage> getBookPage({int page = 0, int size = 10, String? query,
      String? publisherId, String? authorId, String? categoryId, String? copyStatus}) =>
      _remote.getBookPage(page: page, size: size, query: query,
          publisherId: publisherId, authorId: authorId, categoryId: categoryId, copyStatus: copyStatus);
  @override
  Future<Book> getBookById(String id) => _remote.getBookById(id);
  @override
  Future<void> createBook(Book book) async { await _remote.createBook(book); }
  @override
  Future<void> updateBook(Book book) async { await _remote.updateBook(book); }
  @override
  Future<void> deleteBook(String id) => _remote.deleteBook(id);
}
