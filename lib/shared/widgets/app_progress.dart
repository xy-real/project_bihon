import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AppProgress extends StatelessWidget {
  /// Value from 0 to 100.
  final double percent;
  final double? minHeight;
  final BorderRadius? borderRadius;

  const AppProgress({
    super.key,
    required this.percent,
    this.minHeight,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = (percent.clamp(0, 100)) / 100;

    return ShadProgress(
      value: normalized,
      minHeight: minHeight,
      borderRadius: borderRadius,
      semanticsLabel: 'Progress',
      semanticsValue: '${percent.toStringAsFixed(0)}%',
    );
  }
}
