import 'package:flutter/material.dart';

class StatItem {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String change;

  const StatItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.change,
  });
}
