import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  destructive,
  link,
}

enum AppButtonSize {
  regular,
  small,
  large,
}

class AppButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final Widget? leading;
  final Widget? trailing;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool enabled;
  final bool expands;

  const AppButton({
    super.key,
    this.onPressed,
    this.child,
    this.leading,
    this.trailing,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.enabled = true,
    this.expands = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveChild = child ?? const SizedBox.shrink();
    final effectiveSize = switch (size) {
      AppButtonSize.regular => ShadButtonSize.regular,
      AppButtonSize.small => ShadButtonSize.sm,
      AppButtonSize.large => ShadButtonSize.lg,
    };

    return switch (variant) {
      AppButtonVariant.primary => ShadButton(
          onPressed: onPressed,
          child: effectiveChild,
          leading: leading,
          trailing: trailing,
          enabled: enabled,
          expands: expands,
          size: effectiveSize,
        ),
      AppButtonVariant.secondary => ShadButton.secondary(
          onPressed: onPressed,
          child: effectiveChild,
          leading: leading,
          trailing: trailing,
          enabled: enabled,
          expands: expands,
          size: effectiveSize,
        ),
      AppButtonVariant.outline => ShadButton.outline(
          onPressed: onPressed,
          child: effectiveChild,
          leading: leading,
          trailing: trailing,
          enabled: enabled,
          expands: expands,
          size: effectiveSize,
        ),
      AppButtonVariant.ghost => ShadButton.ghost(
          onPressed: onPressed,
          child: effectiveChild,
          leading: leading,
          trailing: trailing,
          enabled: enabled,
          expands: expands,
          size: effectiveSize,
        ),
      AppButtonVariant.destructive => ShadButton.destructive(
          onPressed: onPressed,
          child: effectiveChild,
          leading: leading,
          trailing: trailing,
          enabled: enabled,
          expands: expands,
          size: effectiveSize,
        ),
      AppButtonVariant.link => ShadButton.link(
          onPressed: onPressed,
          child: effectiveChild,
          leading: leading,
          trailing: trailing,
          enabled: enabled,
          expands: expands,
          size: effectiveSize,
        ),
    };
  }
}
