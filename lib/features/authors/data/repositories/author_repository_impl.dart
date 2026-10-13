import '../../domain/entities/author.dart';
import '../../domain/repositories/author_repository.dart';
import '../datasources/author_local_data_source.dart';

class AuthorRepositoryImpl implements AuthorRepository {
  AuthorRepositoryImpl(this._localDataSource);

  final AuthorLocalDataSource _localDataSource;

  @override
  Future<List<Author>> getAuthors() => _localDataSource.getAuthors();

  @override
  Future<Author> getAuthorById(String id) => _localDataSource.getAuthorById(id);

  @override
  Future<void> createAuthor(Author author) => _localDataSource.createAuthor(author);

  @override
  Future<void> updateAuthor(Author author) => _localDataSource.updateAuthor(author);

  @override
  Future<void> deleteAuthor(String id) => _localDataSource.deleteAuthor(id);
}
