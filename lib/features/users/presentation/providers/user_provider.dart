import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../sign/controllers/auth_controller.dart';
import '../../data/datasources/user_local_data_source.dart';
import '../../data/datasources/user_remote_data_source.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

final userLocalDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  return UserLocalDataSource();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(
    ref.watch(userLocalDataSourceProvider),
    remoteDataSource: UserRemoteDataSource(),
  );
});

/// Không retry tự động để màn hình hiện lỗi ngay thay vì quay loading mãi.
Duration? _noRetry(int retryCount, Object error) => null;

/// Theo dõi tài khoản đang đăng nhập. Khi đăng nhập/đăng xuất/đổi tài khoản,
/// các provider bên dưới tự nạp lại; nếu không sẽ hiển thị dữ liệu tài khoản cũ.
String? _authUserId(Ref ref) =>
    ref.watch(authControllerProvider.select((state) => state.user?.id));

final currentUserProvider = FutureProvider<User>((ref) {
  _authUserId(ref);
  return ref.watch(userRepositoryProvider).getMe();
}, retry: _noRetry);

final userListProvider = FutureProvider<List<User>>((ref) {
  _authUserId(ref);
  return ref.watch(userRepositoryProvider).getUsers();
}, retry: _noRetry);

final userDetailProvider = FutureProvider.family<User, String>((ref, userId) {
  _authUserId(ref);
  return ref.watch(userRepositoryProvider).getUserById(userId);
}, retry: _noRetry);
