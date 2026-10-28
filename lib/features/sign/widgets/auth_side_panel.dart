import 'package:flutter/material.dart';

class AuthSidePanel extends StatelessWidget {
  const AuthSidePanel({super.key});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF102D4A), Color(0xFF244D6B)])),
        padding: const EdgeInsets.all(36),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_library_outlined,
                  size: 40, color: Color(0xFFF5D5AA)),
              const SizedBox(height: 24),
              const Text('Mỗi cuốn sách,\nmột chân trời mới.',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      height: 1.3,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 18),
              const Text(
                  'Tìm tri thức bạn yêu thích.\nKết nối với thư viện của bạn.',
                  style: TextStyle(
                      color: Color(0xFFCFDDE8), height: 1.7, fontSize: 15)),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .07),
                    borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    for (var i = 0; i < 6; i++)
                      Expanded(
                          child: Container(
                        height: 95 + (i % 3) * 17,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                            color: const [
                              Color(0xFFD8B58B),
                              Color(0xFFA1B6A2),
                              Color(0xFFE8D4B8),
                              Color(0xFF7694AB),
                              Color(0xFFC98770),
                              Color(0xFFB8B3A5)
                            ][i],
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4))),
                        child: Center(
                            child: Container(
                                width: 2,
                                height: 40,
                                color: Colors.white.withValues(alpha: .45))),
                      )),
                  ]),
                  Container(height: 8, color: const Color(0xFFB78F69)),
                  const SizedBox(height: 18),
                ]),
              ),
              const SizedBox(height: 36),
              const Text('THƯ VIỆN SỐ',
                  style: TextStyle(
                      color: Color(0xFFF5D5AA),
                      fontSize: 12,
                      letterSpacing: 3)),
            ]),
      );
}
