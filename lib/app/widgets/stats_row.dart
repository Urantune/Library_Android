import 'package:flutter/material.dart';

import '../services/dashboard_service.dart';
import 'stat_card.dart';

class StatsRow extends StatelessWidget {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = DashboardService.getStats();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: StatCard(item: stats[i])),
        ],
      ],
    );
  }
}
