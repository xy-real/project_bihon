import 'package:flutter/material.dart';
import 'package:project_bihon/shared/shared.dart';

class SupplyTrackerCard extends StatelessWidget {
  final int itemCount;
  final int expiringCount;
  final double progressPercent;

  const SupplyTrackerCard({
    super.key,
    this.itemCount = 14,
    this.expiringCount = 2,
    this.progressPercent = 70.0,
  });

  @override
  Widget build(BuildContext context) {
    return AppStatTile(
      leading: const Icon(
        Icons.inventory_2_outlined,
        color: BihonTheme.bihonOrange,
        size: 18,
      ),
      label: 'Emergency Supply Tracker',
      value: '$itemCount items tracked',
      progressPercent: progressPercent,
      subtitle: '⚠ $expiringCount expiring soon',
    );
  }
}
