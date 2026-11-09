import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/core/auth/user_role.dart';

void main() {
  group('UserRole.fromRoles', () {
    test('nhận diện ADMIN', () {
      final role = UserRole.fromRoles(['ADMIN']);
      expect(role, UserRole.admin);
      expect(role.canManageUsers, isTrue);
      expect(role.canManageCatalog, isTrue);
      expect(role.canViewReports, isTrue);
    });

    test('nhận diện LIBRARIAN và STAFF cũ', () {
      expect(UserRole.fromRoles(['LIBRARIAN']), UserRole.librarian);
      expect(UserRole.fromRoles(['STAFF']), UserRole.librarian);
      expect(UserRole.librarian.canManageUsers, isFalse);
      expect(UserRole.librarian.canManageCatalog, isTrue);
      expect(UserRole.librarian.canViewReports, isFalse);
    });

    test('MEMBER / USER cũ / rỗng đều là thành viên', () {
      expect(UserRole.fromRoles(['MEMBER']), UserRole.member);
      expect(UserRole.fromRoles(['USER']), UserRole.member);
      expect(UserRole.fromRoles(const []), UserRole.member);
      expect(UserRole.member.canManageCatalog, isFalse);
    });

    test('không phân biệt hoa thường và khoảng trắng', () {
      expect(UserRole.fromRoles([' admin ']), UserRole.admin);
      expect(UserRole.fromRole(null), UserRole.member);
    });

    test('ADMIN được ưu tiên khi có nhiều role', () {
      expect(UserRole.fromRoles(['MEMBER', 'ADMIN']), UserRole.admin);
    });
  });
}
