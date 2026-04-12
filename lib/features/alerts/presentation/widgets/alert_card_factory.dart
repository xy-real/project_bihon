import 'package:flutter/material.dart';
import 'package:project_bihon/features/alerts/data/models/cached_alert.dart';
import 'package:project_bihon/features/alerts/domain/threat_classification.dart';
import 'package:project_bihon/features/alerts/presentation/widgets/direct_threat_alert_card.dart';
import 'package:project_bihon/features/alerts/presentation/widgets/general_advisory_alert_card.dart';

/// Factory function to build the appropriate alert card widget based on threat classification.
///
/// Usage:
/// ```dart
/// final card = buildAlertCard(
///   alert: myAlert,
///   threatBand: ThreatBand.direct,
///   onTap: () => handleAlertTap(myAlert),
/// );
/// ```
///
/// Parameters:
/// - [alert]: The alert to display
/// - [threatBand]: The threat classification (direct or general)
/// - [onTap]: Optional callback when the card is tapped
/// - [onMoreDetails]: Optional callback for the "More Details" button
///
/// Returns:
/// - [DirectThreatAlertCard] if threatBand is ThreatBand.direct
/// - [GeneralAdvisoryAlertCard] if threatBand is ThreatBand.general
Widget buildAlertCard({
  required CachedAlert alert,
  required ThreatBand threatBand,
  VoidCallback? onTap,
  VoidCallback? onMoreDetails,
}) {
  return threatBand == ThreatBand.direct
      ? DirectThreatAlertCard(
          alert: alert,
          onTap: onTap,
          onMoreDetails: onMoreDetails,
        )
      : GeneralAdvisoryAlertCard(
          alert: alert,
          onTap: onTap,
          onMoreDetails: onMoreDetails,
        );
}

/// Alternative widget-based factory for building alert cards.
///
/// Useful when you want to pass the factory as a widget builder callback.
///
/// Usage:
/// ```dart
/// final card = AlertCardFactory(
///   alert: myAlert,
///   threatBand: ThreatBand.direct,
///   onTap: () => handleTap(myAlert),
/// );
/// ```
class AlertCardFactory extends StatelessWidget {
  /// The alert to display.
  final CachedAlert alert;

  /// The threat classification.
  final ThreatBand threatBand;

  /// Optional callback when the card is tapped.
  final VoidCallback? onTap;

  /// Optional callback for the "More Details" button.
  final VoidCallback? onMoreDetails;

  const AlertCardFactory({
    super.key,
    required this.alert,
    required this.threatBand,
    this.onTap,
    this.onMoreDetails,
  });

  @override
  Widget build(BuildContext context) {
    return buildAlertCard(
      alert: alert,
      threatBand: threatBand,
      onTap: onTap,
      onMoreDetails: onMoreDetails,
    );
  }
}
