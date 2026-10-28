import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/features/sign/utils/validators.dart';

void main() {
  test('checks registration password UTF8 limit and matching confirmation', () {
    expect(Validators.password('1234567'), isNotNull);
    expect(Validators.password('Password123!'), isNull);
    expect(Validators.password('đ'.padRight(80, 'đ')), isNotNull);
    expect(
        Validators.confirmPassword(() => 'Password123!')('wrong'), isNotNull);
    expect(Validators.confirmPassword(() => 'Password123!')('Password123!'),
        isNull);
  });
  test('checks bounded names and emails', () {
    expect(Validators.email('bad'), isNotNull);
    expect(Validators.email('user@example.com'), isNull);
    expect(Validators.fullName(' '), isNotNull);
    expect(Validators.fullName('Name\u0000'), isNotNull);
    expect(Validators.fullName('Dương Phúc Khang'), isNull);
  });
}
