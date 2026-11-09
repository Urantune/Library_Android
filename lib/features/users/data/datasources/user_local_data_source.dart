import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/user.dart';

class UserLocalDataSource {
  static const String _storageKey = 'users_data';
  static const String _jsonPath = 'assets/data/authors/users.json';

  Future<List<User>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString(_storageKey);

    if (savedJson != null) {
      return _decodeUsers(savedJson);
    }

    final jsonString = await rootBundle.loadString(_jsonPath);
    final users = _decodeUsers(jsonString);

    await _saveUsers(users);

    return users;
  }

  List<User> _decodeUsers(String jsonString) {
    final decoded = jsonDecode(jsonString);

    if (decoded is! List) {
      throw const FormatException('File JSON phải chứa danh sách người dùng.');
    }

    return decoded.map((item) {
      return User.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();
  }

  Future<void> _saveUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = jsonEncode(
      users.map((user) => user.toJson()).toList(),
    );

    await prefs.setString(_storageKey, jsonString);
  }

  Future<User> getUserById(String id) async {
    final users = await getUsers();

    return users.firstWhere(
      (user) => user.id == id,
      orElse: () => throw Exception('Không tìm thấy người dùng.'),
    );
  }

  Future<void> createUser(User user) async {
    final users = await getUsers();

    if (users.any((item) => item.id == user.id)) {
      throw Exception('ID người dùng đã tồn tại.');
    }

    if (users.any((item) => item.username == user.username)) {
      throw Exception('Tên đăng nhập đã tồn tại.');
    }

    users.add(user);
    await _saveUsers(users);
  }

  Future<void> updateUser(User updatedUser) async {
    final users = await getUsers();

    final index = users.indexWhere(
      (user) => user.id == updatedUser.id,
    );

    if (index == -1) {
      throw Exception('Không tìm thấy người dùng.');
    }

    users[index] = updatedUser;
    await _saveUsers(users);
  }

  Future<void> deleteUser(String id) async {
    final users = await getUsers();

    final index = users.indexWhere(
      (user) => user.id == id,
    );

    if (index == -1) {
      throw Exception('Không tìm thấy người dùng.');
    }

    users.removeAt(index);
    await _saveUsers(users);
  }

  Future<void> lockUser(String id) async {
    final users = await getUsers();

    final index = users.indexWhere(
      (user) => user.id == id,
    );

    if (index == -1) {
      throw Exception('Không tìm thấy người dùng.');
    }

    users[index] = users[index].copyWith(status: 'LOCKED');
    await _saveUsers(users);
  }

  Future<void> unlockUser(String id) async {
    final users = await getUsers();

    final index = users.indexWhere(
      (user) => user.id == id,
    );

    if (index == -1) {
      throw Exception('Không tìm thấy người dùng.');
    }

    users[index] = users[index].copyWith(status: 'ACTIVE');
    await _saveUsers(users);
  }
}
