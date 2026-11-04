import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as legacy;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';
import 'providers/navigation_provider.dart';
import 'theme/app_colors.dart';

class LibraryApp extends ConsumerWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return legacy.ChangeNotifierProvider(
      create: (_) => NavigationProvider(),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Thư viện số',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          colorSchemeSeed: AppColors.primary,
        ),
        routerConfig: ref.watch(appRouterProvider),
      ),
    );
  }
}
