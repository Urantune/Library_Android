import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/features/users/domain/entities/user.dart';

void main() {
  group('User Entity', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'user-001',
        'username': 'admin',
        'email': 'admin@library.com',
        'fullName': 'Nguyễn Văn A',
        'phone': '0901234567',
        'role': 'ADMIN',
        'status': 'ACTIVE',
        'createdAt': '2024-01-15T08:00:00.000Z',
        'updatedAt': '2024-03-05T14:20:00.000Z',
      };

      final user = User.fromJson(json);

      expect(user.id, 'user-001');
      expect(user.username, 'admin');
      expect(user.email, 'admin@library.com');
      expect(user.fullName, 'Nguyễn Văn A');
      expect(user.phone, '0901234567');
      expect(user.role, 'ADMIN');
      expect(user.status, 'ACTIVE');
      expect(user.createdAt, isNotNull);
      expect(user.updatedAt, isNotNull);
    });

    test('fromJson handles snake_case keys', () {
      final json = {
        'id': 'user-002',
        'username': 'staff01',
        'email': 'staff@library.com',
        'full_name': 'Trần Thị B',
        'role': 'STAFF',
        'status': 'ACTIVE',
        'created_at': '2024-02-10T09:30:00.000Z',
        'updated_at': '2024-03-05T14:20:00.000Z',
      };

      final user = User.fromJson(json);

      expect(user.fullName, 'Trần Thị B');
      expect(user.createdAt, isNotNull);
      expect(user.updatedAt, isNotNull);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'user-003',
        'username': 'user01',
        'email': 'user01@gmail.com',
        'role': 'USER',
        'status': 'ACTIVE',
      };

      final user = User.fromJson(json);

      expect(user.fullName, '');
      expect(user.phone, isNull);
      expect(user.createdAt, isNull);
      expect(user.updatedAt, isNull);
    });

    test('toJson produces correct map', () {
      final user = User(
        id: 'user-001',
        username: 'admin',
        email: 'admin@library.com',
        fullName: 'Nguyễn Văn A',
        phone: '0901234567',
        role: 'ADMIN',
        status: 'ACTIVE',
        createdAt: DateTime.parse('2024-01-15T08:00:00.000Z'),
        updatedAt: DateTime.parse('2024-03-05T14:20:00.000Z'),
      );

      final json = user.toJson();

      expect(json['id'], 'user-001');
      expect(json['username'], 'admin');
      expect(json['email'], 'admin@library.com');
      expect(json['fullName'], 'Nguyễn Văn A');
      expect(json['phone'], '0901234567');
      expect(json['role'], 'ADMIN');
      expect(json['status'], 'ACTIVE');
      expect(json['createdAt'], isNotNull);
      expect(json['updatedAt'], isNotNull);
    });

    test('copyWith updates only specified fields', () {
      final user = User(
        id: 'user-001',
        username: 'admin',
        email: 'admin@library.com',
        fullName: 'Nguyễn Văn A',
        role: 'ADMIN',
        status: 'ACTIVE',
      );

      final updated = user.copyWith(
        fullName: 'Nguyễn Văn B',
        status: 'LOCKED',
      );

      expect(updated.id, 'user-001');
      expect(updated.username, 'admin');
      expect(updated.fullName, 'Nguyễn Văn B');
      expect(updated.status, 'LOCKED');
      expect(updated.email, 'admin@library.com');
    });

    test('copyWith keeps original values when null is passed', () {
      final user = User(
        id: 'user-001',
        username: 'admin',
        email: 'admin@library.com',
        fullName: 'Nguyễn Văn A',
        role: 'ADMIN',
        status: 'ACTIVE',
      );

      final updated = user.copyWith();

      expect(updated.id, user.id);
      expect(updated.username, user.username);
      expect(updated.email, user.email);
      expect(updated.fullName, user.fullName);
      expect(updated.role, user.role);
      expect(updated.status, user.status);
    });
  });
}
