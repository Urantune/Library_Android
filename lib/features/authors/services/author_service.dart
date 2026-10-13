
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/author.dart';

class AuthorService {
  static const String _storageKey = 'authors_data';
  static const String _jsonPath = 'lib/data/trikycuc.json';

  Future<List<Author>> getAuthors() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString(_storageKey);

    // Nếu đã có dữ liệu được lưu, sử dụng dữ liệu đó.
    if (savedJson != null) {
      return _decodeAuthors(savedJson);
    }

    // Lần đầu chạy: đọc danh sách từ file JSON.
    final jsonString = await rootBundle.loadString(_jsonPath);
    final authors = _decodeAuthors(jsonString);

    // Lưu bản dữ liệu ban đầu vào SharedPreferences.
    await _saveAuthors(authors);

    return authors;
  }

  List<Author> _decodeAuthors(String jsonString) {
    final decoded = jsonDecode(jsonString);

    if (decoded is! List) {
      throw const FormatException(
        'File JSON phải chứa danh sách tác giả.',
      );
    }

    return decoded.map((item) {
      return Author.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
    }).toList();
  }

  Future<void> _saveAuthors(List<Author> authors) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = jsonEncode(
      authors.map((author) => author.toJson()).toList(),
    );

    await prefs.setString(_storageKey, jsonString);
  }

  Future<Author> getAuthorById(String id) async {
    final authors = await getAuthors();

    return authors.firstWhere(
      (author) => author.id == id,
      orElse: () => throw Exception('Không tìm thấy tác giả.'),
    );
  }

  Future<void> createAuthor(Author author) async {
    final authors = await getAuthors();

    if (authors.any((item) => item.id == author.id)) {
      throw Exception('ID tác giả đã tồn tại.');
    }

    authors.add(author);
    await _saveAuthors(authors);
  }

  Future<void> updateAuthor(Author updatedAuthor) async {
    final authors = await getAuthors();

    final index = authors.indexWhere(
      (author) => author.id == updatedAuthor.id,
    );

    if (index == -1) {
      throw Exception('Không tìm thấy tác giả.');
    }

    authors[index] = updatedAuthor;
    await _saveAuthors(authors);
  }

  Future<void> deleteAuthor(String id) async {
    final authors = await getAuthors();

    final index = authors.indexWhere(
      (author) => author.id == id,
    );

    if (index == -1) {
      throw Exception('Không tìm thấy tác giả.');
    }

    authors.removeAt(index);
    await _saveAuthors(authors);
  }
}
