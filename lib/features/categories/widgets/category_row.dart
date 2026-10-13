import 'package:flutter/material.dart';

import '../models/book_category.dart';
import 'action_icon.dart';
import 'app_colors.dart';
import 'category_columns.dart';

/// Một dòng dữ liệu trong bảng (có hiệu ứng hover).
class CategoryRow extends StatefulWidget {
  final int index;
  final BookCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onDetail;

  const CategoryRow({
    super.key,
    required this.index,
    required this.category,
    required this.onEdit,
    required this.onDelete,
    this.onDetail,
  });

  @override
  State<CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<CategoryRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 13, color: AppColors.textDark);
    final c = widget.category;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.rowHover : Colors.white,
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: CategoryColumns.index,
              child: Text('${widget.index}',
                  textAlign: TextAlign.center, style: style),
            ),
            Expanded(
              flex: CategoryColumns.nameFlex,
              child: Text(
                c.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: CategoryColumns.descFlex,
              child: Text(c.description,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
            ),
            Expanded(
              flex: CategoryColumns.countFlex,
              child: Text('${c.bookCount}',
                  textAlign: TextAlign.center, style: style),
            ),
            SizedBox(
              width: CategoryColumns.actions,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ActionIcon(
                    icon: Icons.edit_outlined,
                    tooltip: 'Sửa',
                    color: AppColors.primary,
                    onTap: widget.onEdit,
                  ),
                  ActionIcon(
                    icon: Icons.edit_note_rounded,
                    tooltip: 'Chi tiết',
                    color: AppColors.primary,
                    onTap: widget.onDetail ?? () {}, // chưa có chức năng
                  ),
                  ActionIcon(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Xóa',
                    color: AppColors.danger,
                    onTap: widget.onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
