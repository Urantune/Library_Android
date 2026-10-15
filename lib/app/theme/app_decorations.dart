import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Kiểu thẻ (card) dùng chung cho toàn app.
BoxDecoration cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
