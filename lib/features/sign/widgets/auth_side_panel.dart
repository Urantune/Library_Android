import 'package:flutter/material.dart';

import '../constants/auth_constants.dart';

class AuthSidePanel extends StatelessWidget {
  const AuthSidePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(flex: 11, child: _ImagePlaceholder()),
        Expanded(
          flex: 8,
          child: Container(
            width: double.infinity,
            color: AuthColors.sidePanelBottom,
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AuthStrings.sideTitle,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AuthColors.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  AuthStrings.sideSlogan,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AuthColors.textPrimary,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  AuthStrings.sideDescription,
                  style: TextStyle(
                    fontSize: 13,
                    color: AuthColors.textSecondary,
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

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD9B98F), Color(0xFFB98B5E), Color(0xFF8E643E)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_library_rounded,
          size: 120,
          color: Colors.white.withOpacity(0.85),
        ),
      ),
    );
  }
}
