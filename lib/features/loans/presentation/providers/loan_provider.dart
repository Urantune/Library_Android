import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../books/data/datasources/book_remote_data_source.dart';
import '../../../books/domain/entities/book.dart';
import '../../../sign/controllers/auth_controller.dart';
import '../../data/datasources/loan_remote_data_source.dart';
import '../../data/models/loan_response.dart';

final loanCurrentUserIdProvider = FutureProvider<String>((ref) async {
  final user = ref.watch(authControllerProvider.select((state) => state.user));
  if (user == null) {
    throw StateError('Phiên đăng nhập không có thông tin người dùng.');
  }
  return user.id;
});
final loanRemoteDataSourceProvider = Provider<LoanRemoteDataSource>((ref) {
  return LoanRemoteDataSource();
});

final borrowedLoansProvider =
    FutureProvider.family<PageDTO<LoanResponseDTO>, String>((ref, userId) {
  return ref.watch(loanRemoteDataSourceProvider).getBorrowedLoans(userId);
});

final loanBookListProvider = FutureProvider<List<Book>>((ref) {
  const configuredUrl = String.fromEnvironment('CATALOG_API_URL');
  final baseUrl = configuredUrl.isNotEmpty
      ? configuredUrl
      : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? 'http://10.0.2.2:8082'
          : 'http://localhost:8082';
  final dio = ApiClient.create(baseUrl: baseUrl);
  return BookRemoteDataSource(dio).getBooks();
});