import '../entities/user.dart';

abstract class UserRepository {
  Future<List<User>> getUsers();
  Future<User> getUserById(String id);
  Future<User> getMe();
  Future<User> updateMe(User user);
  Future<void> createUser(User user, {String password = ''});
  Future<void> updateUser(User user);
  Future<void> deleteUser(String id);
  Future<void> lockUser(String id);
  Future<void> unlockUser(String id);
}
