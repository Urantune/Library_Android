import 'package:flutter/material.dart';

/// Nút icon nhỏ ở cột "Thao tác".
class ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const ActionIcon({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}
