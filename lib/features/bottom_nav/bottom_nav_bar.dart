import 'package:flutter/material.dart';

import '../../core/auth/user_role.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final UserRole role;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.role,
    required this.onTap,
  });

  List<_NavItem> get _items => [
        const _NavItem(Icons.home_rounded, 'Trang chủ'),
        // ADMIN: quản lý người dùng; thủ thư: mượn trả; thành viên: đã mượn.
        if (role.canManageUsers)
          const _NavItem(Icons.people_outline_rounded, 'Người dùng')
        else if (role.canManageCatalog)
          const _NavItem(Icons.swap_horiz_rounded, 'Mượn trả')
        else
          const _NavItem(Icons.history_rounded, 'Đã mượn'),
        const _NavItem(Icons.notifications_none_rounded, 'Thông báo'),
        const _NavItem(Icons.person_outline_rounded, 'Hồ sơ'),
      ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < _items.length; i++)
                _NavTile(
                  item: _items[i],
                  selected: currentIndex == i,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _NavTile extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final hovering = _hovered && !selected;

    final Color textColor = selected
        ? const Color(0xFF2563EB)
        : hovering
            ? const Color(0xFF1E293B)
            : const Color(0xFF94A3B8);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFEFF6FF)
                : hovering
                    ? Colors.grey.shade50
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.item.icon,
                color: selected
                    ? const Color(0xFF2563EB)
                    : hovering
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF94A3B8),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
