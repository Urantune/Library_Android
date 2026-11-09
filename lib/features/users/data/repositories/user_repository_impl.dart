import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_local_data_source.dart';
import '../datasources/user_remote_data_source.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({
    required UserLocalDataSource localDataSource,
    UserRemoteDataSource? remoteDataSource,
    bool useRemote = false,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _useRemote = useRemote;

  final UserLocalDataSource _localDataSource;
  final UserRemoteDataSource? _remoteDataSource;
  final bool _useRemote;

  bool get _isRemote => _useRemote && _remoteDataSource != null;

  @override
  Future<List<User>> getUsers() async {
    if (_isRemote) return _remoteDataSource!.getUsers();
    return _localDataSource.getUsers();
  }

  @override
  Future<User> getUserById(String id) async {
    if (_isRemote) return _remoteDataSource!.getUserById(id);
    return _localDataSource.getUserById(id);
  }

  @override
  Future<void> createUser(User user) async {
    if (_isRemote) return _remoteDataSource!.createUser(user);
    return _localDataSource.createUser(user);
  }

  @override
  Future<void> updateUser(User user) async {
    if (_isRemote) return _remoteDataSource!.updateUser(user);
    return _localDataSource.updateUser(user);
  }

  @override
  Future<void> deleteUser(String id) async {
    if (_isRemote) return _remoteDataSource!.deleteUser(id);
    return _localDataSource.deleteUser(id);
  }

  @override
  Future<void> lockUser(String id) async {
    if (_isRemote) return _remoteDataSource!.lockUser(id);
    return _localDataSource.lockUser(id);
  }

  @override
  Future<void> unlockUser(String id) async {
    if (_isRemote) return _remoteDataSource!.unlockUser(id);
    return _localDataSource.unlockUser(id);
  }
}
