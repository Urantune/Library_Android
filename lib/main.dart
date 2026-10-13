
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/authors/screens/author_list_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AuthorApp(),
    ),
  );
}

class AuthorApp extends StatelessWidget {
  const AuthorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lore Dungeon Library',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3157B7),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      ),
      home: const AuthorListScreen(),
    );
  }
}
