import 'package:flutter/material.dart';

import '../models/book_category.dart';
import 'app_colors.dart';

class DeleteConfirmDialog extends StatelessWidget {
  final BookCategory category;
  const DeleteConfirmDialog({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Row(
        children: [
          Icon(Icons.delete_outline_rounded, color: AppColors.danger),
          SizedBox(width: 10),
          Text(
            'Xóa thể loại',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Text(
          'Bạn có chắc muốn xóa thể loại "${category.name}"?'
          '\nThể loại sẽ được chuyển sang trạng thái ngừng hoạt động.',
          style: const TextStyle(
              fontSize: 14, color: AppColors.textDark, height: 1.4),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Hủy', style: TextStyle(color: AppColors.textGrey)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Xóa'),
        ),
      ],
    );
  }
}
