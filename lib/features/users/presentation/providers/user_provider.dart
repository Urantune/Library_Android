import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final currentUserProvider = FutureProvider<User>((ref) {
  return ref.watch(userRepositoryProvider).getMe();
});

final userListProvider = FutureProvider<List<User>>((ref) {
  return ref.watch(userRepositoryProvider).getUsers();
});

final userDetailProvider =
    FutureProvider.family<User, String>((ref, userId) {
  return ref.watch(userRepositoryProvider).getUserById(userId);
});
