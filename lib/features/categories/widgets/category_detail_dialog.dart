import 'package:flutter/material.dart';

import '../models/book_category.dart';
import 'app_colors.dart';

class CategoryDetailDialog extends StatelessWidget {
  final BookCategory category;
  final Future<String?> Function()? loadParentName;

  const CategoryDetailDialog({
    super.key,
    required this.category,
    this.loadParentName,
  });

  static String _formatDate(DateTime? d) {
    if (d == null) return '—';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final c = category;
    final isActive = c.status == CategoryStatus.active;

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primary),
          SizedBox(width: 10),
          Text(
            'Chi tiết thể loại',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(label: 'Mã', child: _value(c.id)),
              _InfoRow(label: 'Tên thể loại', child: _value(c.name, bold: true)),
              _InfoRow(
                label: 'Mô tả',
                child: _value(
                  c.description.trim().isEmpty
                      ? 'Chưa có mô tả'
                      : c.description,
                  muted: c.description.trim().isEmpty,
                ),
              ),
              _InfoRow(label: 'Danh mục cha', child: _parent()),
              _InfoRow(
                label: 'Trạng thái',
                child: _StatusChip(active: isActive),
              ),
              _InfoRow(label: 'Ngày tạo', child: _value(_formatDate(c.createdAt))),
              _InfoRow(
                label: 'Cập nhật lần cuối',
                child: _value(_formatDate(c.updatedAt)),
                isLast: true,
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Đóng'),
        ),
      ],
    );
  }

  Widget _parent() {
    if (category.parentId == null) {
      return _value('Danh mục gốc', muted: true);
    }
    if (loadParentName == null) return _value('Mã ${category.parentId}');

    return FutureBuilder<String?>(
      future: loadParentName!(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _value('Đang tải...', muted: true);
        }
        final name = snap.data;
        return _value(name ?? 'Mã ${category.parentId}');
      },
    );
  }

  static Widget _value(String text, {bool bold = false, bool muted = false}) =>
      Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          color: muted ? AppColors.textGrey : AppColors.textDark,
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final Widget child;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.child,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool active;
  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF16A34A) : AppColors.danger;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          active ? 'Đang hoạt động' : 'Ngừng hoạt động',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
