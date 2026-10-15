import 'package:flutter/material.dart';

import '../models/menu_item.dart';
import '../theme/app_colors.dart';

class SidebarTile extends StatefulWidget {
  final MenuItem item;
  final bool selected;
  final VoidCallback onTap;
  const SidebarTile({
    super.key,
    required this.item,
    required this.onTap,
    this.selected = false,
  });

  @override
  State<SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<SidebarTile> {
  static const _hoverColor = Color(0xFFDEE034);
  static const _duration = Duration(milliseconds: 220);
  static const _curve = Curves.easeOutCubic;

  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final hovering = _hovered && !selected; // chỉ áp dụng cho thẻ chưa chọn

    final textColor = selected
        ? AppColors.primary
        : hovering
            ? _hoverColor
            : Colors.white;
    final iconColor = selected
        ? AppColors.primary
        : hovering
            ? _hoverColor
            : Colors.white70;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: _duration,
        curve: _curve,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        // Thẻ nổi lên nhẹ khi hover
        transform: Matrix4.translationValues(0, hovering ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : hovering
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0),
          borderRadius: BorderRadius.circular(10),
          boxShadow: hovering
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: iconColor),
                    duration: _duration,
                    curve: _curve,
                    builder: (context, color, _) =>
                        Icon(widget.item.icon, size: 20, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: _duration,
                      curve: _curve,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color: textColor,
                      ),
                      child: Text(
                        widget.item.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
