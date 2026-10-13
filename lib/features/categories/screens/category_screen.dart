import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book_category.dart';
import '../providers/category_provider.dart';
import '../services/category_storage_service.dart';
import '../widgets/app_colors.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/category_header.dart';
import '../widgets/category_pagination.dart';
import '../widgets/category_table.dart';
import '../widgets/category_toolbar.dart';
import '../widgets/delete_confirm_dialog.dart';

// ───────────────────────── Màn hình Thể loại ─────────────────────────
/// Tự tạo [CategoryProvider] bên trong nên chỉ cần dùng `CategoryScreen()`
/// ở chỗ trước đây dùng `CategoryPage()`.
class CategoryScreen extends StatelessWidget {
  /// Gọi khi bấm nút quay lại. Nếu null thì dùng Navigator.maybePop.
  final VoidCallback? onBack;

  const CategoryScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CategoryProvider(CategoryStorageService())..load(),
      child: _CategoryView(onBack: onBack),
    );
  }
}

class _CategoryView extends StatelessWidget {
  final VoidCallback? onBack;
  const _CategoryView({this.onBack});

  // ── C: thêm ──
  Future<void> _onCreate(BuildContext context) async {
    final provider = context.read<CategoryProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final result = await showDialog<CategoryFormResult>(
      context: context,
      builder: (_) => CategoryFormDialog(
        title: 'Thêm thể loại',
        submitLabel: 'Thêm',
        takenNames: provider.takenNames(),
      ),
    );
    if (result == null) return;

    try {
      await provider.add(result.name, result.description);
      messenger.showSnackBar(
        SnackBar(content: Text('Đã thêm thể loại "${result.name}"')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Không thêm được thể loại: $e')),
      );
    }
  }

  // ── U: sửa ──
  Future<void> _onEdit(BuildContext context, BookCategory category) async {
    final provider = context.read<CategoryProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final current = provider.findById(category.id);
    if (current == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thể loại này nữa')),
      );
      await provider.load(showSpinner: false);
      return;
    }

    final result = await showDialog<CategoryFormResult>(
      context: context,
      builder: (_) => CategoryFormDialog(
        title: 'Sửa thể loại',
        submitLabel: 'Lưu',
        initialName: current.name,
        initialDescription: current.description,
        // Chặn trùng với các thể loại khác (không tính chính nó)
        takenNames: provider.takenNames(excludeId: current.id),
      ),
    );
    if (result == null) return;

    try {
      final status = await provider.update(
        current.id,
        result.name,
        result.description,
      );
      switch (status) {
        case UpdateResult.updated:
          messenger.showSnackBar(
            SnackBar(content: Text('Đã cập nhật thể loại "${result.name}"')),
          );
        case UpdateResult.notFound:
          messenger.showSnackBar(
            const SnackBar(content: Text('Không tìm thấy thể loại này nữa')),
          );
          await provider.load(showSpinner: false);
        case UpdateResult.unchanged:
          break;
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Không sửa được thể loại: $e')),
      );
    }
  }

  // ── D: xóa ──
  Future<void> _onDelete(BuildContext context, BookCategory category) async {
    final provider = context.read<CategoryProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteConfirmDialog(category: category),
    );
    if (confirmed != true) return;

    try {
      await provider.delete(category.id);
      messenger.showSnackBar(
        SnackBar(content: Text('Đã xóa thể loại "${category.name}"')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Không xóa được thể loại: $e')),
      );
    }
  }

  Widget _buildContent(BuildContext context, CategoryProvider p) {
    if (p.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (p.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Text(p.error!, style: const TextStyle(color: AppColors.danger)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => p.load(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    return CategoryTable(
      categories: p.pageItems,
      startIndex: p.startIndex,
      emptyMessage: p.query.trim().isEmpty
          ? 'Chưa có thể loại nào'
          : 'Không tìm thấy thể loại phù hợp',
      onEdit: (c) => _onEdit(context, c),
      onDelete: (c) => _onDelete(context, c),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CategoryProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000), // đen, độ mờ ~3%
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CategoryHeader(
              onBack: onBack ?? () => Navigator.maybePop(context),
              onRefresh: () => p.load(),
            ),
            const SizedBox(height: 20),
            CategoryToolbar(
              onSearchChanged: p.setQuery,
              onCreate: () => _onCreate(context),
            ),
            const SizedBox(height: 20),
            _buildContent(context, p),
            const SizedBox(height: 16),
            if (!p.loading && p.error == null)
              CategoryPagination(
                current: p.page,
                total: p.totalPages,
                onPageChanged: p.goToPage,
              ),
          ],
        ),
      ),
    );
  }
}
