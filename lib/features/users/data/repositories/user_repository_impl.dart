import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_local_data_source.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._localDataSource);

  final UserLocalDataSource _localDataSource;

  @override
  Future<List<User>> getUsers() => _localDataSource.getUsers();

  @override
  Future<User> getUserById(String id) => _localDataSource.getUserById(id);

  @override
  Future<void> createUser(User user) => _localDataSource.createUser(user);

  @override
  Future<void> updateUser(User user) => _localDataSource.updateUser(user);

  @override
  Future<void> deleteUser(String id) => _localDataSource.deleteUser(id);

  @override
  Future<void> lockUser(String id) => _localDataSource.lockUser(id);

  @override
  Future<void> unlockUser(String id) => _localDataSource.unlockUser(id);
}
