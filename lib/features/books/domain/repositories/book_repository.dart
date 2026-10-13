import '../entities/book.dart';

abstract class BookRepository {
  Future<List<Book>> getBooks();
  Future<Book> getBookById(String id);
  Future<void> createBook(Book book);
  Future<void> updateBook(Book book);
  Future<void> deleteBook(String id);
}
