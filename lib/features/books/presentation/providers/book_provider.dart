import '../../../../core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/book_copy_api.dart';
import '../../data/datasources/book_api.dart';
import '../../data/repositories/book_repository_impl.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_copy.dart';
import '../../domain/entities/book_page.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/services/book_save_service.dart';
import '../../../categories/models/book_category.dart';
import '../../../categories/services/category_api_service.dart';
import '../../../publishers/models/publisher.dart';
import '../../../publishers/services/publisher_service.dart';

class BookQuery {
  final int page;
  final int size;
  final String query;
  final String? publisherId;
  final String? authorId;
  final String? categoryId;
  final String? copyStatus;

  const BookQuery({
    this.page = 0,
    this.size = 10,
    this.query = '',
    this.publisherId,
    this.authorId,
    this.categoryId,
    this.copyStatus,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookQuery &&
          runtimeType == other.runtimeType &&
          page == other.page &&
          size == other.size &&
          query == other.query &&
          publisherId == other.publisherId &&
          authorId == other.authorId &&
          categoryId == other.categoryId && copyStatus == other.copyStatus;

  @override
  int get hashCode => Object.hash(page, size, query, publisherId, authorId, categoryId, copyStatus);
}

final bookCategoriesProvider = FutureProvider<List<BookCategory>>(
    (ref) => CategoryApiService().listActive());
final bookPublishersProvider = FutureProvider<List<Publisher>>(
    (ref) => PublisherService().getPublishers());
final bookRemoteDataSourceProvider =
    Provider<BookRemoteDataSource>((ref) => BookRemoteDataSource(ApiClient.catalogDio));
final bookRepositoryProvider = Provider<BookRepository>(
    (ref) => BookRepositoryImpl(ref.watch(bookRemoteDataSourceProvider)));
final bookSaveServiceProvider = Provider<BookSaveService>(
    (ref) => BookSaveService(ref.watch(bookRepositoryProvider)));
final bookListProvider = FutureProvider<List<Book>>(
    (ref) => ref.watch(bookRepositoryProvider).getBooks());
final bookPagedProvider = FutureProvider.family<BookPage, BookQuery>((ref, query) {
  return ref.watch(bookRepositoryProvider).getBookPage(
        page: query.page,
        size: query.size,
        query: query.query,
        publisherId: query.publisherId,
        authorId: query.authorId,
        categoryId: query.categoryId,
        copyStatus: query.copyStatus,
      );
});
final bookDetailProvider = FutureProvider.family<Book, String>(
    (ref, id) => ref.watch(bookRepositoryProvider).getBookById(id));
final bookCopyDataSourceProvider = Provider<BookCopyRemoteDataSource>(
    (ref) => BookCopyRemoteDataSource(ApiClient.catalogDio));
final bookCopiesProvider = FutureProvider.family<List<BookCopy>, String>(
    (ref, bookId) => ref.watch(bookCopyDataSourceProvider).list(bookId));
