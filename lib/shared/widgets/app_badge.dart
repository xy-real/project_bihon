import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

enum AppBadgeVariant {
  primary,
  secondary,
  outline,
  destructive,
}

class AppBadge extends StatelessWidget {
  final Widget child;
  final AppBadgeVariant variant;
  final VoidCallback? onPressed;

  const AppBadge({
    super.key,
    required this.child,
    this.variant = AppBadgeVariant.primary,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      AppBadgeVariant.primary => ShadBadge(
          onPressed: onPressed,
          child: child,
        ),
      AppBadgeVariant.secondary => ShadBadge.secondary(
          onPressed: onPressed,
          child: child,
        ),
      AppBadgeVariant.outline => ShadBadge.outline(
          onPressed: onPressed,
          child: child,
        ),
      AppBadgeVariant.destructive => ShadBadge.destructive(
          onPressed: onPressed,
          child: child,
        ),
    };
  }
}
