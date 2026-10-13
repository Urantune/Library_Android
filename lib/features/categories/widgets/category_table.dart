import 'package:flutter/material.dart';

import '../models/book_category.dart';
import 'app_colors.dart';
import 'category_columns.dart';
import 'category_row.dart';

/// Bảng danh sách thể loại (header + các dòng, hoặc thông báo rỗng).
class CategoryTable extends StatelessWidget {
  final List<BookCategory> categories;
  final int startIndex;
  final String emptyMessage;
  final ValueChanged<BookCategory> onEdit;
  final ValueChanged<BookCategory> onDelete;
  final ValueChanged<BookCategory>? onDetail;

  const CategoryTable({
    super.key,
    required this.categories,
    required this.startIndex,
    required this.emptyMessage,
    required this.onEdit,
    required this.onDelete,
    this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            const _HeaderRow(),
            if (categories.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Center(
                  child: Text(
                    emptyMessage,
                    style: const TextStyle(
                        color: AppColors.textGrey, fontSize: 13),
                  ),
                ),
              )
            else
              for (int i = 0; i < categories.length; i++)
                CategoryRow(
                  index: startIndex + i + 1,
                  category: categories[i],
                  onEdit: () => onEdit(categories[i]),
                  onDelete: () => onDelete(categories[i]),
                  onDetail: onDetail == null
                      ? null
                      : () => onDetail!(categories[i]),
                ),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      color: AppColors.textDark,
    );
    return Container(
      color: AppColors.headerBg,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: const Row(
        children: [
          SizedBox(
            width: CategoryColumns.index,
            child: Text('#', textAlign: TextAlign.center, style: style),
          ),
          Expanded(
            flex: CategoryColumns.nameFlex,
            child: Text('Tên thể loại', style: style),
          ),
          Expanded(
            flex: CategoryColumns.descFlex,
            child: Text('Mô tả', style: style),
          ),
          Expanded(
            flex: CategoryColumns.countFlex,
            child: Text('Số sách', textAlign: TextAlign.center, style: style),
          ),
          SizedBox(
            width: CategoryColumns.actions,
            child: Text('Thao tác', textAlign: TextAlign.center, style: style),
          ),
        ],
      ),
    );
  }
}
