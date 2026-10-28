import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/author_remote_data_source.dart';
import '../../data/repositories/author_repository_impl.dart';
import '../../domain/entities/author.dart';
import '../../domain/repositories/author_repository.dart';

final authorRemoteDataSourceProvider = Provider<AuthorRemoteDataSource>((ref) {
  return AuthorRemoteDataSource();
});

final authorRepositoryProvider = Provider<AuthorRepository>((ref) {
  return AuthorRepositoryImpl(ref.watch(authorRemoteDataSourceProvider));
});

final authorListProvider = FutureProvider<List<Author>>((ref) {
  return ref.watch(authorRepositoryProvider).getAuthors();
});

final authorDetailProvider =
    FutureProvider.family<Author, String>((ref, authorId) {
  return ref.watch(authorRepositoryProvider).getAuthorById(authorId);
});
