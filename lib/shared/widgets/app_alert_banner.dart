import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

enum AppAlertBannerVariant {
  primary,
  destructive,
}

class AppAlertBanner extends StatelessWidget {
  final Widget? icon;
  final String title;
  final String? description;
  final VoidCallback? onTap;
  final AppAlertBannerVariant variant;

  const AppAlertBanner({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.onTap,
    this.variant = AppAlertBannerVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    final alert = switch (variant) {
      AppAlertBannerVariant.primary => ShadAlert(
          icon: icon,
          title: Text(title),
          description: description != null ? Text(description!) : null,
        ),
      AppAlertBannerVariant.destructive => ShadAlert.destructive(
          icon: icon,
          title: Text(title),
          description: description != null ? Text(description!) : null,
        ),
    };

    if (onTap == null) {
      return alert;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: alert,
    );
  }
}
