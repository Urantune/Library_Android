import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/book_category.dart';
import '../services/category_api_service.dart';

class ParentOptions {
  final List<BookCategory> roots;
  final bool locked;
  const ParentOptions(this.roots, {this.locked = false});
}

enum UpdateResult { updated, unchanged, notFound }

class CategoryProvider extends ChangeNotifier {
  CategoryProvider(this._api);

  static const pageSize = 5;
  static const _searchDebounce = Duration(milliseconds: 400);

  final CategoryApiService _api;

  List<BookCategory> _items = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  int _page = 1; // tính từ 1
  int _totalPages = 1;
  int _totalElements = 0;
  bool _disposed = false;

  Timer? _debounce;
  int _requestSeq = 0;

  bool get loading => _loading;
  String? get error => _error;
  String get query => _query;
  int get page => _page;
  int get totalPages => _totalPages;
  int get totalElements => _totalElements;
  int get startIndex => (_page - 1) * pageSize;
  List<BookCategory> get pageItems => _items;

  BookCategory? findById(String id) {
    for (final c in _items) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> load({bool showSpinner = true}) async {
    final seq = ++_requestSeq;
    if (showSpinner) {
      _loading = true;
      _error = null;
      _notify();
    }
    try {
      final result = await _api.search(
        keyword: _query,
        page: _page,
        size: pageSize,
      );
      if (seq != _requestSeq) return;

      if (result.content.isEmpty && _page > 1 && result.totalPages > 0) {
        _page = result.totalPages;
        return load(showSpinner: false);
      }

      _items = result.content;
      _totalPages = result.totalPages == 0 ? 1 : result.totalPages;
      _totalElements = result.totalElements;
      _loading = false;
      _error = null;
    } on ApiException catch (e) {
      if (seq != _requestSeq) return;
      _error = e.message;
      _loading = false;
    } catch (e) {
      if (seq != _requestSeq) return;
      _error = 'Không tải được dữ liệu: $e';
      _loading = false;
    }
    _notify();
  }

  Future<ParentOptions> loadParentOptions({String? excludeId}) async {
    final all = await _api.listActive();
    final hasChildren =
        excludeId != null && all.any((c) => c.parentId == excludeId);
    final roots = all
        .where((c) => c.parentId == null && c.id != excludeId)
        .toList();
    return ParentOptions(roots, locked: hasChildren);
  }

  Future<String?> parentNameOf(String? parentId) async {
    if (parentId == null) return null;
    final local = findById(parentId);
    if (local != null) return local.name;
    try {
      return (await _api.getById(parentId)).name;
    } catch (_) {
      return null;
    }
  }

  void setQuery(String value) {
    _query = value;
    _page = 1;
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () => load(showSpinner: false));
  }

  void goToPage(int target) {
    final next = target.clamp(1, _totalPages);
    if (next == _page) return;
    _page = next;
    load(showSpinner: false);
  }

  Future<void> add(String name, String description, {String? parentId}) async {
    await _api.create(
      name: name,
      description: description,
      parentId: parentId,
    );
    await load(showSpinner: false);
  }

  Future<UpdateResult> update(
    String id,
    String name,
    String description, {
    String? parentId,
  }) async {
    final current = findById(id);
    if (current == null) return UpdateResult.notFound;
    if (current.name == name &&
        current.description == description &&
        current.parentId == parentId) {
      return UpdateResult.unchanged;
    }
    try {
      await _api.update(
        id,
        name: name,
        description: description,
        parentId: parentId,
      );
    } on ApiException catch (e) {
      if (e.isNotFound) return UpdateResult.notFound;
      rethrow;
    }
    await load(showSpinner: false);
    return UpdateResult.updated;
  }

  Future<void> delete(String id) async {
    await _api.delete(id);
    await load(showSpinner: false);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
