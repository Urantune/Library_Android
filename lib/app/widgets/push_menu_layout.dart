import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Menu nằm cố định phía dưới, nội dung trượt sang phải khi menu mở.
class PushMenuLayout extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final Widget menu;
  final Widget child;
  final double menuWidth;

  const PushMenuLayout({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.menu,
    required this.child,
    this.menuWidth = 250,
  });

  static const _duration = Duration(milliseconds: 300);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: menuWidth,
          child: menu,
        ),
        AnimatedPositioned(
          duration: _duration,
          curve: _curve,
          top: 0,
          bottom: 0,
          left: isOpen ? menuWidth : 0,
          right: isOpen ? -menuWidth : 0,
          child: AnimatedContainer(
            duration: _duration,
            curve: _curve,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(isOpen ? 24 : 0),
              boxShadow: isOpen
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 24,
                        offset: const Offset(-4, 0),
                      ),
                    ]
                  : const [],
            ),
            child: Stack(
              children: [
                IgnorePointer(ignoring: isOpen, child: child),
                if (isOpen)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onClose,
                      onHorizontalDragEnd: (details) {
                        if ((details.primaryVelocity ?? 0) < 0) onClose();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
