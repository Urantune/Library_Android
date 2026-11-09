import 'package:flutter/material.dart';

class StatItem {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String change;

  /// Màu của dòng thay đổi (mặc định là màu xanh "tích cực").
  final Color? changeColor;

  const StatItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.change,
    this.changeColor,
  });
}
