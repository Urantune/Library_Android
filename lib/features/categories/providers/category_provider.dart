import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/book_category.dart';
import '../services/category_storage_service.dart';

/// Kết quả của thao tác sửa.
enum UpdateResult { updated, unchanged, notFound }

/// Giữ toàn bộ trạng thái của trang Thể loại:
/// dữ liệu, tìm kiếm, phân trang và các thao tác C / U / D.
class CategoryProvider extends ChangeNotifier {
  CategoryProvider(this._service);

  static const pageSize = 5;

  final CategoryStorageService _service;

  List<BookCategory> _all = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  int _currentPage = 1;
  bool _disposed = false;

  // ── Trạng thái cho giao diện ──
  bool get loading => _loading;
  String? get error => _error;
  String get query => _query;

  List<BookCategory> get filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  int get totalPages {
    final count = filtered.length;
    return count == 0 ? 1 : (count + pageSize - 1) ~/ pageSize;
  }

  int get page => _currentPage.clamp(1, totalPages);
  int get startIndex => (page - 1) * pageSize;

  List<BookCategory> get pageItems =>
      filtered.skip(startIndex).take(pageSize).toList();

  /// Các tên đã tồn tại (bỏ qua [excludeId]) để form chặn trùng tên.
  List<String> takenNames({int? excludeId}) => [
        for (final c in _all)
          if (c.id != excludeId) c.name,
      ];

  BookCategory? findById(int id) {
    for (final c in _all) {
      if (c.id == id) return c;
    }
    return null;
  }

  // ── R: đọc dữ liệu từ tt.json ──
  Future<void> load({bool showSpinner = true}) async {
    if (showSpinner) {
      _loading = true;
      _error = null;
      _notify();
    }
    try {
      final data = await _service.load();
      debugPrint('tt.json: ${await _service.path()}');
      _all = data;
      _loading = false;
      _error = null;
      _currentPage = page; // kéo về trang hợp lệ
    } catch (e) {
      _error = 'Không đọc được dữ liệu: $e';
      _loading = false;
    }
    _notify();
  }

  // ── Tìm kiếm / phân trang ──
  void setQuery(String value) {
    _query = value;
    _currentPage = 1;
    _notify();
  }

  void goToPage(int target) {
    _currentPage = target.clamp(1, totalPages);
    _notify();
  }

  // ── C: thêm ──
  /// Ném lỗi nếu không lưu được (danh sách trong bộ nhớ không bị đổi).
  Future<void> add(String name, String description) async {
    final nextId = _all.isEmpty ? 1 : _all.map((c) => c.id).reduce(max) + 1;
    final updated = [
      ..._all,
      BookCategory(id: nextId, name: name, description: description),
    ];
    await _service.save(updated);
    _all = updated;
    _notify();
  }

  // ── U: sửa ──
  Future<UpdateResult> update(int id, String name, String description) async {
    final index = _all.indexWhere((c) => c.id == id);
    if (index == -1) return UpdateResult.notFound;

    final current = _all[index];
    if (current.name == name && current.description == description) {
      return UpdateResult.unchanged;
    }

    final updated = [..._all];
    updated[index] = current.copyWith(name: name, description: description);
    await _service.save(updated);
    _all = updated;
    _notify();
    return UpdateResult.updated;
  }

  // ── D: xóa ──
  Future<void> delete(int id) async {
    final updated = _all.where((c) => c.id != id).toList();
    await _service.save(updated);
    _all = updated;
    _currentPage = page;
    _notify();
  }

  // ── Tránh notify sau khi provider đã bị hủy (khi đang await) ──
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
