import '../../../../core/config/api_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../books/data/datasources/book_api.dart';
import '../../../books/domain/entities/book.dart';
import '../../../sign/controllers/auth_controller.dart';
import '../../../sign/models/user.dart' as auth_user;
import '../../../users/data/datasources/user_remote_data_source.dart';
import '../../../users/domain/entities/user.dart' as user_entity;
import '../../data/datasources/loan_remote_data_source.dart';
import '../../data/models/loan_renewal_response.dart';
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
  final authenticatedUserId =
      ref.watch(authControllerProvider.select((state) => state.user?.id));
  if (authenticatedUserId != userId) {
    throw StateError(
        'Phiên đăng nhập đã thay đổi. Vui lòng tải lại phiếu mượn.');
  }
  return ref.watch(loanRemoteDataSourceProvider).getBorrowedLoans(userId);
});

final adminLoansProvider =
    FutureProvider.family<PageDTO<LoanResponseDTO>, String>((ref, userRoles) {
  ref.watch(authControllerProvider.select((state) => state.user?.id));
  return ref
      .watch(loanRemoteDataSourceProvider)
      .getAllLoans(userRoles: userRoles);
});

final adminLoanRenewalsProvider =
    FutureProvider<List<LoanRenewalResponseDTO>>((ref) {
  ref.watch(authControllerProvider.select((state) => state.user?.id));
  return ref.watch(loanRemoteDataSourceProvider).getRenewals();
});

final loanUserDetailsProvider =
    FutureProvider.family<user_entity.User, String>((ref, userId) {
  const configuredUrl = String.fromEnvironment('USER_API_BASE_URL');
  final baseUrl = configuredUrl.isNotEmpty
      ? configuredUrl
      : ApiConfig.baseUrl;
  final dio = ApiClient.create(baseUrl: baseUrl);
  return UserRemoteDataSource(dio: dio).getUserById(userId);
});

final loanBookListProvider = FutureProvider<List<Book>>((ref) {
  const configuredUrl = String.fromEnvironment('CATALOG_API_URL');
  final baseUrl = configuredUrl.isNotEmpty
      ? configuredUrl
      : ApiConfig.baseUrl;
  final dio = ApiClient.create(baseUrl: baseUrl);
  return BookRemoteDataSource(dio).getBooks();
});
