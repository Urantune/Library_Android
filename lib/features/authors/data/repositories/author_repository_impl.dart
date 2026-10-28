import '../../domain/entities/author.dart';
import '../../domain/repositories/author_repository.dart';
import '../datasources/author_remote_data_source.dart';

class AuthorRepositoryImpl implements AuthorRepository {
  final AuthorRemoteDataSource _remoteDataSource;

  AuthorRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Author>> getAuthors() async {
    final page = await _remoteDataSource.fetchAuthors(page: 0, size: 1000); // fetch all for now
    // Map AuthorResponse to Author (add id if available)
    return page.content.map((e) => Author(
      id: e.id, // fallback, update if BE returns id
      name: e.name,
      bio: e.bio,
      birthDate: e.birthDate,
      country: e.country,
      status: e.status,
      createdAt: e.createAt,
      updatedAt: e.updateAt,
    )).toList();
  }

  @override
  Future<Author> getAuthorById(String id) async {
    final authors = await getAuthors();
    return authors.firstWhere((a) => a.id == id);
  }

  @override
  Future<void> createAuthor(Author author) async {
    await _remoteDataSource.createAuthor(
      name: author.name,
      bio: author.bio,
      birthDate: author.birthDate,
      country: author.country,
      status: author.status,
    );
  }

  @override
  Future<void> updateAuthor(Author author) async {
    throw UnimplementedError('API does not support updateAuthor yet');
  }

  @override
  Future<void> deleteAuthor(String id) async {
    throw UnimplementedError('API does not support deleteAuthor yet');
  }
}
