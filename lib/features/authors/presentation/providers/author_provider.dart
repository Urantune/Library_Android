
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/author_local_data_source.dart';
import '../../data/repositories/author_repository_impl.dart';
import '../../domain/entities/author.dart';
import '../../domain/repositories/author_repository.dart';

final authorLocalDataSourceProvider = Provider<AuthorLocalDataSource>((ref) {
  return AuthorLocalDataSource();
});

final authorRepositoryProvider = Provider<AuthorRepository>((ref) {
  return AuthorRepositoryImpl(ref.watch(authorLocalDataSourceProvider));
});

final authorListProvider = FutureProvider<List<Author>>((ref) {
  return ref.watch(authorRepositoryProvider).getAuthors();
});

final authorDetailProvider =
    FutureProvider.family<Author, String>((ref, authorId) {
  return ref.watch(authorRepositoryProvider).getAuthorById(authorId);
});
