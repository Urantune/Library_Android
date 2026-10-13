import '../entities/author.dart';

abstract class AuthorRepository {
  Future<List<Author>> getAuthors();
  Future<Author> getAuthorById(String id);
  Future<void> createAuthor(Author author);
  Future<void> updateAuthor(Author author);
  Future<void> deleteAuthor(String id);
}
