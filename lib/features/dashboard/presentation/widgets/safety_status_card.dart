import 'package:flutter/material.dart';
import 'package:project_bihon/shared/shared.dart';

class SafetyStatusCard extends StatelessWidget {
  final String status;
  final String sentLabel;

  const SafetyStatusCard({
    super.key,
    this.status = 'I\'m Safe',
    this.sentLabel = '✓ Sent 2 days ago',
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: BihonTheme.bihonOrange,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Safety Status',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            status,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: BihonTheme.bihonOrange,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sentLabel,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
