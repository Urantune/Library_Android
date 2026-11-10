import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/book_copy.dart';
import '../providers/book_provider.dart';

class BookCopiesSection extends ConsumerWidget {
  const BookCopiesSection({super.key, required this.bookId});
  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copies = ref.watch(bookCopiesProvider(bookId));
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE6EAF0))),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 12, runSpacing: 8, children: [
            const Text('Các cuốn trong thư viện', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            OutlinedButton.icon(onPressed: () => _add(context, ref), icon: const Icon(Icons.add), label: const Text('Thêm cuốn')),
          ]),
          const SizedBox(height: 8),
          const Text('Mỗi cuốn có một mã riêng. Cuốn đang mượn hoặc được giữ sẽ do hệ thống mượn trả quản lý.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          copies.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
            error: (_, __) => Row(children: [const Expanded(child: Text('Không tải được danh sách cuốn.')), TextButton(onPressed: () => ref.invalidate(bookCopiesProvider(bookId)), child: const Text('Thử lại'))]),
            data: (items) => items.isEmpty
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Chưa có cuốn nào.'))
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${items.length} cuốn · ${items.where((c) => c.status == 'AVAILABLE').length} có sẵn', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...items.map((copy) => _tile(context, ref, copy)),
                  ]),
          ),
        ]),
      ),
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref, BookCopy copy) {
    final status = switch (copy.status) {
      'AVAILABLE' => 'Có sẵn', 'BORROWED' => 'Đang mượn', 'RESERVED' => 'Đang giữ',
      'DAMAGED' => 'Hư hỏng', 'LOST' => 'Đã mất', _ => copy.status,
    };
    final canEdit = {'AVAILABLE', 'DAMAGED', 'LOST'}.contains(copy.status);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: const Color(0xFFE8EFFF), child: Icon(Icons.qr_code, color: Colors.blue.shade700)),
      title: Text(copy.code, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${copy.shelfLocation?.isNotEmpty == true ? 'Kệ ${copy.shelfLocation}' : 'Chưa có vị trí'} · $status'),
      trailing: canEdit ? PopupMenuButton<String>(
        tooltip: 'Đổi trạng thái',
        onSelected: (value) => _status(context, ref, copy, value),
        itemBuilder: (_) => [
          if (copy.status != 'AVAILABLE') const PopupMenuItem(value: 'AVAILABLE', child: Text('Đánh dấu có sẵn')),
          if (copy.status != 'DAMAGED') const PopupMenuItem(value: 'DAMAGED', child: Text('Báo hư hỏng')),
          if (copy.status != 'LOST') const PopupMenuItem(value: 'LOST', child: Text('Báo mất')),
        ],
      ) : const Icon(Icons.lock_outline, color: Colors.grey),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final code = TextEditingController();
    final shelf = TextEditingController();
    final values = await showDialog<List<String>>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Thêm cuốn sách'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: code, decoration: const InputDecoration(labelText: 'Mã cuốn / mã vạch *', hintText: 'VD: SACH-0001')),
        TextField(controller: shelf, decoration: const InputDecoration(labelText: 'Vị trí kệ', hintText: 'VD: A1-02')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
        FilledButton(onPressed: () { if (code.text.trim().isNotEmpty) Navigator.pop(dialogContext, [code.text.trim(), shelf.text.trim()]); }, child: const Text('Thêm'))],
    ));
    code.dispose(); shelf.dispose();
    if (values == null || !context.mounted) return;
    try {
      await ref.read(bookCopyDataSourceProvider).create(bookId, values[0], values[1]);
      _refresh(ref);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm cuốn sách.')));
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thêm được cuốn. Kiểm tra mã đã tồn tại hoặc kết nối.')));
    }
  }

  Future<void> _status(BuildContext context, WidgetRef ref, BookCopy copy, String status) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Đổi trạng thái cuốn sách'),
      content: Text('Xác nhận cập nhật cuốn ${copy.code}?'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Xác nhận'))],
    ));
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(bookCopyDataSourceProvider).setStatus(bookId, copy.id, status);
      _refresh(ref);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật trạng thái.')));
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không cập nhật được. Cuốn có thể đang được mượn hoặc giữ.')));
    }
  }

  void _refresh(WidgetRef ref) {
    ref.invalidate(bookCopiesProvider(bookId));
    ref.invalidate(bookDetailProvider(bookId));
    ref.invalidate(bookPagedProvider);
    ref.invalidate(bookListProvider);
  }
}
