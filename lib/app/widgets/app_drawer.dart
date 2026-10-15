import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/navigation_provider.dart';
import '../theme/app_colors.dart';
import 'sidebar.dart';

/// Ngăn kéo bên trái chứa Sidebar.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();

    return Drawer(
      width: 250,
      backgroundColor: AppColors.sidebar,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Sidebar(
          selectedIndex: nav.selectedIndex,
          onSelected: (i) {
            nav.selectMenu(i);
            Navigator.of(context).pop(); // đóng menu sau khi chọn
          },
        ),
      ),
    );
  }
}
