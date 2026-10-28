import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/user_local_data_source.dart';
import '../../data/datasources/user_remote_data_source.dart';
import '../../data/datasources/user_config.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/repositories/user_repository_impl.dart';

final userLocalDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  return UserLocalDataSource();
});

final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSource();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final local = ref.watch(userLocalDataSourceProvider);
  final remote = ref.watch(userRemoteDataSourceProvider);
  return UserRepositoryImpl(
    localDataSource: local,
    remoteDataSource: remote,
    useRemote: UserConfig.useRemote,
  );
});

final userListProvider = FutureProvider<List<User>>((ref) {
  return ref.watch(userRepositoryProvider).getUsers();
});

final userDetailProvider =
    FutureProvider.family<User, String>((ref, userId) {
  return ref.watch(userRepositoryProvider).getUserById(userId);
});
