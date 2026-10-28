import 'package:flutter/material.dart';

import '../constants/auth_constants.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.menu_book_rounded,
            size: 48, color: AuthColors.primary),
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AuthColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AuthColors.textSecondary),
        ),
      ],
    );
  }
}
