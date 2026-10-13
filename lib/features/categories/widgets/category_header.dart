import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tiêu đề: nút quay lại, "Thể loại", nút làm mới.
class CategoryHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const CategoryHeader({
    super.key,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onBack,
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.chevron_left_rounded,
                size: 26, color: AppColors.textDark),
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'Thể loại',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Làm mới',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textGrey),
        ),
      ],
    );
  }
}
