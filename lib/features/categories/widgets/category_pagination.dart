import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Phân trang (hiện tối đa 5 số trang quanh trang hiện tại).
class CategoryPagination extends StatelessWidget {
  final int current;
  final int total;
  final ValueChanged<int> onPageChanged;

  const CategoryPagination({
    super.key,
    required this.current,
    required this.total,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    int start = current - 2;
    if (start > total - 4) start = total - 4;
    if (start < 1) start = 1;
    final end = (start + 4 > total) ? total : start + 4;

    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PageButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => onPageChanged(current - 1),
          ),
          if (start > 1) const _PageButton(label: '...'),
          for (int p = start; p <= end; p++)
            _PageButton(
              label: '$p',
              selected: p == current,
              onTap: () => onPageChanged(p),
            ),
          if (end < total) const _PageButton(label: '...'),
          _PageButton(
            icon: Icons.chevron_right_rounded,
            onTap: () => onPageChanged(current + 1),
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  const _PageButton({
    this.label,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.selectedBg : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: icon != null
              ? Icon(icon, size: 20, color: AppColors.textDark)
              : Text(
                  label ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.primary : AppColors.textDark,
                  ),
                ),
        ),
      ),
    );
  }
}
