import 'package:flutter/material.dart';
import 'package:project_bihon/shared/shared.dart';

class PagasaAlertsCard extends StatelessWidget {
  final int alertCount;
  final String signalLabel;

  const PagasaAlertsCard({
    super.key,
    this.alertCount = 1,
    this.signalLabel = 'Typhoon Signal No. 1',
  });

  @override
  Widget build(BuildContext context) {
    return AppStatTile(
      leading: const Icon(
        Icons.cloud_outlined,
        color: BihonTheme.bihonOrange,
        size: 18,
      ),
      label: 'PAGASA Alerts',
      value: '$alertCount Active Alert',
      chips: [
        AppBadge(variant: AppBadgeVariant.secondary, child: Text(signalLabel)),
      ],
    );
  }
}
