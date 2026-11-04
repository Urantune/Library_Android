import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_local_data_source.dart';
import '../datasources/user_remote_data_source.dart';
import '../datasources/user_config.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._localDataSource, {UserRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final UserLocalDataSource _localDataSource;
  final UserRemoteDataSource? _remoteDataSource;
  bool get _useRemote => UserConfig.useRemote && _remoteDataSource != null;

  @override
  Future<List<User>> getUsers() => _useRemote ? _remoteDataSource!.getUsers() : _localDataSource.getUsers();

  @override
  Future<User> getUserById(String id) => _useRemote ? _remoteDataSource!.getUserById(id) : _localDataSource.getUserById(id);

  @override
  Future<User> getMe() => _useRemote ? _remoteDataSource!.getMe() : _localDataSource.getUserById('user-001');

  @override
  Future<void> updateMe(User user) => _useRemote ? _remoteDataSource!.updateMe(user) : _localDataSource.updateUser(user);

  @override
  Future<void> createUser(User user, {String password = ''}) => _useRemote
      ? _remoteDataSource!.createUser(user, password: password)
      : _localDataSource.createUser(user);

  @override
  Future<void> updateUser(User user) => _useRemote ? _remoteDataSource!.updateUser(user) : _localDataSource.updateUser(user);

  @override
  Future<void> deleteUser(String id) => _useRemote ? _remoteDataSource!.deleteUser(id) : _localDataSource.deleteUser(id);

  @override
  Future<void> lockUser(String id) => _useRemote ? _remoteDataSource!.lockUser(id) : _localDataSource.lockUser(id);

  @override
  Future<void> unlockUser(String id) => _useRemote ? _remoteDataSource!.unlockUser(id) : _localDataSource.unlockUser(id);
}
