import 'package:flutter/material.dart';

import 'dashboard_design.dart';

class DashboardActionTile extends StatelessWidget {
  const DashboardActionTile({
    super.key,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DashboardDesign.radius),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: DashboardDesign.surface(context),
            borderRadius: BorderRadius.circular(DashboardDesign.radius),
            border: Border.all(color: DashboardDesign.outline(context)),
            boxShadow: DashboardDesign.cardShadow(context),
          ),
          child: SizedBox(
            height: 132,
            child: Padding(
              padding: const EdgeInsets.all(DashboardDesign.gap),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: DashboardDesign.touchTarget,
                    height: DashboardDesign.touchTarget,
                    decoration: BoxDecoration(
                      color: DashboardDesign.statusBackground(context, color),
                      borderRadius: BorderRadius.circular(
                        DashboardDesign.compactRadius,
                      ),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DashboardDesign.mutedText(context),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
