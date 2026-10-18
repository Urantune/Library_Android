import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_router.dart';
import 'providers/navigation_provider.dart';
import 'theme/app_colors.dart';

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NavigationProvider(),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Thư viện số',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          colorSchemeSeed: AppColors.primary,
        ),
        routerConfig: appRouter,
      ),
    );
  }
}