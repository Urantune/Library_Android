import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Trang tạm cho các mục chưa làm.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Trang này đang được phát triển',
        style: TextStyle(color: AppColors.textGrey, fontSize: 14),
      ),
    );
  }
}
