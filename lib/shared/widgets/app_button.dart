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
  final Color? lightBackgroundColor;
  final Color? darkBackgroundColor;
  final Color? lightForegroundColor;
  final Color? darkForegroundColor;
  final Color? lightBorderColor;
  final Color? darkBorderColor;

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
    this.lightBackgroundColor,
    this.darkBackgroundColor,
    this.lightForegroundColor,
    this.darkForegroundColor,
    this.lightBorderColor,
    this.darkBorderColor,
  });

  bool get _hasCustomThemeColors =>
      lightBackgroundColor != null ||
      darkBackgroundColor != null ||
      lightForegroundColor != null ||
      darkForegroundColor != null ||
      lightBorderColor != null ||
      darkBorderColor != null;

  double get _height => switch (size) {
        AppButtonSize.small => 34,
        AppButtonSize.regular => 40,
        AppButtonSize.large => 46,
      };

  EdgeInsetsGeometry get _padding => switch (size) {
        AppButtonSize.small => const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        AppButtonSize.regular => const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        AppButtonSize.large => const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      };

  Widget _buildButtonChild() {
    final content = child ?? const SizedBox.shrink();

    if (leading == null && trailing == null) {
      return content;
    }

    return Row(
      mainAxisSize: expands ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 8),
        ],
        Flexible(child: content),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveChild = child ?? const SizedBox.shrink();
    final effectiveSize = switch (size) {
      AppButtonSize.regular => ShadButtonSize.regular,
      AppButtonSize.small => ShadButtonSize.sm,
      AppButtonSize.large => ShadButtonSize.lg,
    };

    if (!_hasCustomThemeColors) {
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedBackground = isDark ? darkBackgroundColor : lightBackgroundColor;
    final resolvedForeground = isDark ? darkForegroundColor : lightForegroundColor;
    final resolvedBorder = isDark ? darkBorderColor : lightBorderColor;

    final disabledOnPressed = enabled ? onPressed : null;
    final commonStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(Size(expands ? double.infinity : 0, _height)),
      padding: WidgetStateProperty.all(_padding),
      foregroundColor:
          resolvedForeground != null ? WidgetStateProperty.all(resolvedForeground) : null,
      backgroundColor:
          resolvedBackground != null ? WidgetStateProperty.all(resolvedBackground) : null,
      side: resolvedBorder != null ? WidgetStateProperty.all(BorderSide(color: resolvedBorder)) : null,
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    return switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: disabledOnPressed,
          style: FilledButton.styleFrom().merge(commonStyle),
          child: _buildButtonChild(),
        ),
      AppButtonVariant.secondary => FilledButton.tonal(
          onPressed: disabledOnPressed,
          style: FilledButton.styleFrom().merge(commonStyle),
          child: _buildButtonChild(),
        ),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: disabledOnPressed,
          style: OutlinedButton.styleFrom().merge(commonStyle),
          child: _buildButtonChild(),
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: disabledOnPressed,
          style: TextButton.styleFrom().merge(commonStyle),
          child: _buildButtonChild(),
        ),
      AppButtonVariant.destructive => FilledButton(
          onPressed: disabledOnPressed,
          style: FilledButton.styleFrom().merge(commonStyle),
          child: _buildButtonChild(),
        ),
      AppButtonVariant.link => TextButton(
          onPressed: disabledOnPressed,
          style: TextButton.styleFrom().merge(commonStyle),
          child: _buildButtonChild(),
        ),
    };
  }
}
