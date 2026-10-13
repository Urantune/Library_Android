import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import '../models/book_category.dart';

// ───────────────────────── Đọc / ghi trongtungcanh.json ─────────────────────────
/// Lưu danh sách thể loại vào file trongtungcanh.json.
///
/// - Lần chạy đầu: chép dữ liệu mẫu từ asset `assets/categories/trongtungcanh.json` sang file thật
///   (nằm trong thư mục dữ liệu của ứng dụng).
/// - Các lần sau: đọc/ghi thẳng file thật đó.
/// Asset trong app là chỉ-đọc nên không thể ghi trực tiếp vào nó.
class CategoryStorageService {
  static const _assetPath = 'assets/data/categories/trongtungcanh.json';
  static const _fileName = 'trongtungcanh.json';

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  /// Đường dẫn file trongtungcanh.json thật đang được dùng (để bạn mở ra xem).
  Future<String> path() async => (await _file()).path;

  Future<List<BookCategory>> load() async {
    final file = await _file();
    String content;
    if (await file.exists()) {
      content = await file.readAsString();
    } else {
      content = await _readSeed();
      await file.create(recursive: true);
      await file.writeAsString(content);
    }
    return _parse(content);
  }

  Future<void> save(List<BookCategory> categories) async {
    final file = await _file();
    const encoder = JsonEncoder.withIndent('  ');
    final text = encoder.convert(categories.map((c) => c.toJson()).toList());
    await file.writeAsString(text);
  }

  Future<String> _readSeed() async {
    try {
      return await rootBundle.loadString(_assetPath);
    } catch (_) {
      return '[]';
    }
  }

  List<BookCategory> _parse(String content) {
    if (content.trim().isEmpty) return [];
    final decoded = jsonDecode(content);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(BookCategory.fromJson)
        .toList();
  }
}
