import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/navigation_provider.dart';
import 'screens/dashboard_page.dart';
import 'theme/app_colors.dart';

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NavigationProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Thư viện số',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          colorSchemeSeed: AppColors.primary,
        ),
        home: const DashboardPage(),
      ),
    );
  }
}
