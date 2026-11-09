import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/features/users/domain/entities/user.dart';
import 'package:lore_dungeo_library/features/users/domain/repositories/user_repository.dart';
import 'package:lore_dungeo_library/features/users/data/datasources/user_local_data_source.dart';
import 'package:lore_dungeo_library/features/users/data/repositories/user_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'users_data': '[]',
    });
    repository = UserRepositoryImpl(UserLocalDataSource());
  });

  group('UserRepository CRUD', () {
    test('createUser and getUsers returns created user', () async {
      final user = User(
        id: 'test-001',
        username: 'testuser',
        email: 'test@example.com',
        fullName: 'Test User',
        phone: '0123456789',
        role: 'USER',
        status: 'ACTIVE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.createUser(user);
      final users = await repository.getUsers();

      expect(users.any((u) => u.id == 'test-001'), isTrue);
    });

    test('createUser throws when ID already exists', () async {
      final user = User(
        id: 'test-001',
        username: 'testuser',
        email: 'test@example.com',
        fullName: 'Test User',
        role: 'USER',
        status: 'ACTIVE',
      );

      await repository.createUser(user);

      expect(
        () => repository.createUser(user),
        throwsException,
      );
    });

    test('createUser throws when username already exists', () async {
      final user1 = User(
        id: 'test-001',
        username: 'testuser',
        email: 'test1@example.com',
        fullName: 'Test User 1',
        role: 'USER',
        status: 'ACTIVE',
      );

      final user2 = User(
        id: 'test-002',
        username: 'testuser',
        email: 'test2@example.com',
        fullName: 'Test User 2',
        role: 'USER',
        status: 'ACTIVE',
      );

      await repository.createUser(user1);

      expect(
        () => repository.createUser(user2),
        throwsException,
      );
    });

    test('getUserById returns correct user', () async {
      final user = User(
        id: 'test-001',
        username: 'testuser',
        email: 'test@example.com',
        fullName: 'Test User',
        role: 'USER',
        status: 'ACTIVE',
      );

      await repository.createUser(user);
      final found = await repository.getUserById('test-001');

      expect(found.username, 'testuser');
      expect(found.email, 'test@example.com');
    });

    test('getUserById throws when user not found', () async {
      expect(
        () => repository.getUserById('non-existent'),
        throwsException,
      );
    });

    test('updateUser modifies existing user', () async {
      final user = User(
        id: 'test-001',
        username: 'testuser',
        email: 'test@example.com',
        fullName: 'Test User',
        role: 'USER',
        status: 'ACTIVE',
      );

      await repository.createUser(user);

      final updated = user.copyWith(fullName: 'Updated Name');
      await repository.updateUser(updated);

      final found = await repository.getUserById('test-001');
      expect(found.fullName, 'Updated Name');
    });

    test('updateUser throws when user not found', () async {
      final user = User(
        id: 'non-existent',
        username: 'testuser',
        email: 'test@example.com',
        fullName: 'Test User',
        role: 'USER',
        status: 'ACTIVE',
      );

      expect(
        () => repository.updateUser(user),
        throwsException,
      );
    });

    test('deleteUser removes user from list', () async {
      final user = User(
        id: 'test-001',
        username: 'testuser',
        email: 'test@example.com',
        fullName: 'Test User',
        role: 'USER',
        status: 'ACTIVE',
      );

      await repository.createUser(user);
      await repository.deleteUser('test-001');

      final users = await repository.getUsers();
      expect(users.any((u) => u.id == 'test-001'), isFalse);
    });

    test('deleteUser throws when user not found', () async {
      expect(
        () => repository.deleteUser('non-existent'),
        throwsException,
      );
    });

    test('lockUser sets status to LOCKED', () async {
      final user = User(
        id: 'test-001',
        username: 'testuser',
        email: 'test@example.com',
        fullName: 'Test User',
        role: 'USER',
        status: 'ACTIVE',
      );

      await repository.createUser(user);
      await repository.lockUser('test-001');

      final found = await repository.getUserById('test-001');
      expect(found.status, 'LOCKED');
    });

    test('unlockUser sets status to ACTIVE', () async {
      final user = User(
        id: 'test-001',
        username: 'testuser',
        email: 'test@example.com',
        fullName: 'Test User',
        role: 'USER',
        status: 'LOCKED',
      );

      await repository.createUser(user);
      await repository.unlockUser('test-001');

      final found = await repository.getUserById('test-001');
      expect(found.status, 'ACTIVE');
    });
  });
}
