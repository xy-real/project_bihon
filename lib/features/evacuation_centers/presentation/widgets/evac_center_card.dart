import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/dashboard_design.dart';
import 'package:project_bihon/features/evacuation_centers/data/models/cached_evac_center.dart';

/// Card widget displaying evacuation center information.
class EvacCenterCard extends StatelessWidget {
  const EvacCenterCard({
    super.key,
    required this.center,
    this.distanceMeters,
    this.onViewDirections,
    this.onCall,
  });

  final CachedEvacCenter center;
  final double? distanceMeters;
  final VoidCallback? onViewDirections;
  final VoidCallback? onCall;

  String _formatDistance() {
    if (distanceMeters == null) {
      return 'Distance unavailable';
    }

    final km = distanceMeters! / 1000;
    return '${km.toStringAsFixed(1)} km away';
  }

  _EvacStatusStyle _statusStyle() {
    final status = center.status.toLowerCase().trim();

    switch (status) {
      case 'open':
        return const _EvacStatusStyle(color: DashboardDesign.success);
      case 'near capacity':
        return const _EvacStatusStyle(color: DashboardDesign.warning);
      case 'full':
      case 'closed':
        return const _EvacStatusStyle(
          color: DashboardDesign.danger,
          muted: true,
        );
      default:
        return const _EvacStatusStyle(color: DashboardDesign.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusStyle();
    final surface = DashboardDesign.surface(context);
    final textColor = status.muted
        ? DashboardDesign.mutedText(context)
        : Theme.of(context).colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: status.muted
            ? Color.alphaBlend(
                DashboardDesign.danger.withValues(alpha: 0.03),
                surface,
              )
            : surface,
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
            width: 5,
            child: ColoredBox(color: status.color),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(21, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  center.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      LucideIcons.car,
                      size: 17,
                      color: DashboardDesign.mutedText(context),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        _formatDistance(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DashboardDesign.mutedText(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ActionRow(onViewDirections: onViewDirections, onCall: onCall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvacStatusStyle {
  const _EvacStatusStyle({required this.color, this.muted = false});

  final Color color;
  final bool muted;
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.onViewDirections, required this.onCall});

  final VoidCallback? onViewDirections;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CardActionButton(
          label: 'VIEW DIRECTIONS',
          icon: LucideIcons.navigation,
          onPressed: onViewDirections,
          primary: true,
        ),
        const SizedBox(height: 10),
        _CardActionButton(
          label: 'CALL',
          icon: LucideIcons.phone,
          onPressed: onCall,
        ),
      ],
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final style = primary
        ? FilledButton.styleFrom(
            backgroundColor: DashboardDesign.deepNavy,
            foregroundColor: Colors.white,
          )
        : OutlinedButton.styleFrom(
            foregroundColor: DashboardDesign.deepNavy,
            side: const BorderSide(color: DashboardDesign.deepNavy),
          );

    final buttonStyle = style.copyWith(
      minimumSize: WidgetStateProperty.all(
        const Size.fromHeight(DashboardDesign.touchTarget),
      ),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DashboardDesign.compactRadius),
        ),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 7),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );

    if (primary) {
      return FilledButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: child,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: buttonStyle,
      child: child,
    );
  }
}
