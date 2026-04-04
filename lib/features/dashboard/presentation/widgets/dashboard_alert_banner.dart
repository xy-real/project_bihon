import 'package:flutter/material.dart';
import 'package:project_bihon/shared/shared.dart';

class DashboardAlertBanner extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const DashboardAlertBanner({
    super.key,
    this.title = 'Active Typhoon Alert in your area — Tap to view',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppAlertBanner(
      variant: AppAlertBannerVariant.primary,
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: BihonTheme.bihonOrange,
      ),
      title: title,
      onTap: onTap,
    );
  }
}
