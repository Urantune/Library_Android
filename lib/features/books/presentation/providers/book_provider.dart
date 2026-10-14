import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/book_local_data_source.dart';
import '../../data/repositories/book_repository_impl.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';

final bookLocalDataSourceProvider = Provider<BookLocalDataSource>((ref) => BookLocalDataSource());
final bookRepositoryProvider = Provider<BookRepository>((ref) => BookRepositoryImpl(ref.watch(bookLocalDataSourceProvider)));
final bookListProvider = FutureProvider<List<Book>>((ref) => ref.watch(bookRepositoryProvider).getBooks());
final bookDetailProvider = FutureProvider.family<Book, String>((ref, id) => ref.watch(bookRepositoryProvider).getBookById(id));
