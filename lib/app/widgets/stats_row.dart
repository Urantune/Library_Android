import 'package:flutter/material.dart';

import '../models/stat_item.dart';
import 'stat_card.dart';

class StatsRow extends StatelessWidget {
  final List<StatItem> stats;

  const StatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        // Màn hình rộng: đủ số cột; hẹp hơn: 2 cột; rất hẹp: 1 cột.
        final columns = constraints.maxWidth >= 840
            ? stats.length
            : constraints.maxWidth >= 520
                ? 2
                : 1;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final stat in stats)
              SizedBox(width: itemWidth, child: StatCard(item: stat)),
          ],
        );
      },
    );
  }
}
