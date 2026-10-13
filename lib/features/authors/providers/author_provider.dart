
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/author.dart';
import '../services/author_service.dart';

final authorServiceProvider = Provider<AuthorService>((ref) {
  return AuthorService();
});

final authorListProvider = FutureProvider<List<Author>>((ref) {
  return ref.watch(authorServiceProvider).getAuthors();
});

final authorDetailProvider =
    FutureProvider.family<Author, String>((ref, authorId) {
  return ref.watch(authorServiceProvider).getAuthorById(authorId);
});
