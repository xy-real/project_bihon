import 'package:flutter/material.dart';

import 'app_badge.dart';
import 'app_card.dart';
import 'app_progress.dart';

class AppStatTile extends StatelessWidget {
  final Widget leading;
  final String label;
  final String value;
  final String? subtitle;
  final double? progressPercent;
  final List<Widget>? chips;

  const AppStatTile({
    super.key,
    required this.leading,
    required this.label,
    required this.value,
    this.subtitle,
    this.progressPercent,
    this.chips,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: leading,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (progressPercent != null) ...[
            const SizedBox(height: 8),
            AppProgress(
              percent: progressPercent!,
              minHeight: 5,
              borderRadius: BorderRadius.circular(999),
            ),
          ],
          if (chips != null && chips!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: chips!,
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class AppDotBadge extends StatelessWidget {
  final String text;

  const AppDotBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      variant: AppBadgeVariant.secondary,
      child: Text(text),
    );
  }
}
