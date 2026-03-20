import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AppThemeSwitcher extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;
  final bool showLabel;

  const AppThemeSwitcher({
    super.key,
    required this.themeMode,
    required this.onChanged,
    this.showLabel = true,
  });

  bool get _isDark => themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return ShadSwitch(
      value: _isDark,
      onChanged: (isDark) {
        onChanged(isDark ? ThemeMode.dark : ThemeMode.light);
      },
      label: showLabel
          ? Text(_isDark ? 'Dark mode' : 'Light mode')
          : null,
      sublabel: showLabel ? const Text('Tap to switch theme') : null,
    );
  }
}
