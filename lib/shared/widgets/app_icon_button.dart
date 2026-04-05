import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

enum AppIconButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  destructive,
}

class AppIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final AppIconButtonVariant variant;
  final double? iconSize;
  final bool enabled;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = AppIconButtonVariant.ghost,
    this.iconSize,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      AppIconButtonVariant.primary => ShadIconButton(
          icon: icon,
          onPressed: onPressed,
          iconSize: iconSize,
          enabled: enabled,
        ),
      AppIconButtonVariant.secondary => ShadIconButton.secondary(
          icon: icon,
          onPressed: onPressed,
          iconSize: iconSize,
          enabled: enabled,
        ),
      AppIconButtonVariant.outline => ShadIconButton.outline(
          icon: icon,
          onPressed: onPressed,
          iconSize: iconSize,
          enabled: enabled,
        ),
      AppIconButtonVariant.ghost => ShadIconButton.ghost(
          icon: icon,
          onPressed: onPressed,
          iconSize: iconSize,
          enabled: enabled,
        ),
      AppIconButtonVariant.destructive => ShadIconButton.destructive(
          icon: icon,
          onPressed: onPressed,
          iconSize: iconSize,
          enabled: enabled,
        ),
    };
  }
}
