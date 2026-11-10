import '../entities/book.dart';
import '../entities/book_page.dart';

abstract class BookRepository {
  Future<List<Book>> getBooks();
  Future<BookPage> getBookPage({
    int page = 0,
    int size = 10,
    String? query,
    String? publisherId,
    String? authorId,
    String? categoryId,
  });
  Future<Book> getBookById(String id);
  Future<void> createBook(Book book);
  Future<void> updateBook(Book book);
  Future<void> deleteBook(String id);
}
