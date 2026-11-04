import 'package:flutter/material.dart';

import '../models/stat_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import 'skeleton.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.item,
    required this.value,
    required this.hasError,
    required this.onTap,
    required this.onRetry,
  });

  final StatItem item;

  final int? value;
  final bool hasError;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  static const _errorColor = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final failed = value == null && hasError;
    final loading = value == null && !hasError;

    return Container(
      decoration: cardDecoration(),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: loading ? null : (failed ? onRetry : onTap),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: item.color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 36,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: loading
                        ? const Skeleton(width: 64, height: 26)
                        : failed
                            ? const Text(
                                'Không tải được',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _errorColor,
                                ),
                              )
                            : FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _format(value!),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 16,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: loading
                        ? const Skeleton(width: 80, height: 12)
                        : Text(
                            failed ? 'Chạm để tải lại' : 'Xem danh sách',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: failed ? _errorColor : AppColors.primary,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _format(int n) => n.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );
}
