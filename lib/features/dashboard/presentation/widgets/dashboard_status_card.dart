import 'package:flutter/material.dart';

import 'dashboard_design.dart';

class DashboardStatusCard extends StatelessWidget {
  const DashboardStatusCard({
    super.key,
    required this.title,
    required this.value,
    required this.description,
    required this.statusColor,
    required this.icon,
    this.onTap,
    this.footer,
  });

  final String title;
  final String value;
  final String description;
  final Color statusColor;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      constraints: const BoxConstraints(minHeight: 132),
      decoration: BoxDecoration(
        color: DashboardDesign.surface(context),
        borderRadius: BorderRadius.circular(DashboardDesign.radius),
        border: Border.all(color: DashboardDesign.outline(context)),
        boxShadow: DashboardDesign.cardShadow(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: ColoredBox(color: statusColor),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DashboardDesign.gap + 4,
              DashboardDesign.gap,
              DashboardDesign.gap,
              DashboardDesign.gap,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: DashboardDesign.statusBackground(
                          context,
                          statusColor,
                        ),
                        borderRadius: BorderRadius.circular(
                          DashboardDesign.compactRadius,
                        ),
                      ),
                      child: Icon(icon, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: DashboardDesign.mutedText(context),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DashboardDesign.mutedText(context),
                      ),
                ),
                if (footer != null) ...[
                  const SizedBox(height: 12),
                  footer!,
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DashboardDesign.radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
