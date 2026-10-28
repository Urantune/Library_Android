import 'package:flutter/material.dart';
import '../constants/auth_constants.dart';
import 'auth_side_panel.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child, this.cardHeight = 620});
  final Widget child;
  final double cardHeight;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AuthColors.pageBackground,
        body: SafeArea(child: LayoutBuilder(builder: (context, viewport) {
          final wide = viewport.maxWidth >= 800;
          final form = Material(
              color: Colors.transparent,
              child: Padding(
                  padding: EdgeInsets.all(wide ? 40 : 24), child: child));
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: wide ? 32 : 16, vertical: wide ? 48 : 24),
            child: Center(
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: DecoratedBox(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF12243A).withValues(alpha: .07),
                          blurRadius: 40,
                          offset: const Offset(0, 12))
                    ]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: wide
                      ? IntrinsicHeight(
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                              const Expanded(flex: 9, child: AuthSidePanel()),
                              Expanded(
                                  flex: 11,
                                  child: ConstrainedBox(
                                      constraints:
                                          BoxConstraints(minHeight: cardHeight),
                                      child: Center(child: form))),
                            ]))
                      : Column(children: [
                          const Padding(
                              padding: EdgeInsets.only(top: 28),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.local_library_outlined,
                                        color: AuthColors.primary),
                                    SizedBox(width: 10),
                                    Text('Thư viện số',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AuthColors.textPrimary)),
                                  ])),
                          form,
                        ]),
                ),
              ),
            )),
          );
        })),
      );
}
