import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../books/data/datasources/book_remote_data_source.dart';
import '../../../books/domain/entities/book.dart';
import '../../../sign/controllers/auth_controller.dart';
import '../../../sign/models/user.dart' as auth_user;
import '../../../users/data/datasources/user_remote_data_source.dart';
import '../../../users/domain/entities/user.dart' as user_entity;
import '../../data/datasources/loan_remote_data_source.dart';
import '../../data/models/loan_response.dart';

final loanCurrentUserIdProvider = FutureProvider<String>((ref) async {
  final user = ref.watch(authControllerProvider.select((state) => state.user));
  if (user == null) {
    throw StateError('Phiên đăng nhập không có thông tin người dùng.');
  }
  return user.id;
});

final loanCurrentUserInfoProvider = Provider<auth_user.User?>((ref) {
  return ref.watch(authControllerProvider.select((state) => state.user));
});

final loanRemoteDataSourceProvider = Provider<LoanRemoteDataSource>((ref) {
  return LoanRemoteDataSource();
});

final borrowedLoansProvider =
    FutureProvider.family<PageDTO<LoanResponseDTO>, String>((ref, userId) {
  return ref.watch(loanRemoteDataSourceProvider).getBorrowedLoans(userId);
});

final adminLoansProvider =
    FutureProvider.family<PageDTO<LoanResponseDTO>, String>((ref, userRoles) {
  return ref.watch(loanRemoteDataSourceProvider).getAllLoans(userRoles: userRoles);
});

final loanUserDetailsProvider =
    FutureProvider.family<user_entity.User, String>((ref, userId) {
  const configuredUrl = String.fromEnvironment('USER_API_BASE_URL');
  final baseUrl = configuredUrl.isNotEmpty
      ? configuredUrl
      : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? 'http://10.0.2.2:8081'
          : 'http://localhost:8081';
  final dio = ApiClient.create(baseUrl: baseUrl);
  return UserRemoteDataSource(dio: dio).getUserById(userId);
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
