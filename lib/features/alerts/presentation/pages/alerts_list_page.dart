import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_bihon/features/alerts/data/models/cached_alert.dart';
import 'package:project_bihon/features/alerts/data/repositories/alerts_repository.dart';
import 'package:project_bihon/features/alerts/domain/threat_classification.dart';
import 'package:project_bihon/features/alerts/presentation/widgets/alert_card_factory.dart';
import 'package:project_bihon/features/household/data/repositories/household_repository.dart';
import 'package:project_bihon/main.dart'
    show getAlertsRepository, getHouseholdRepository;
import 'package:project_bihon/shared/models/household.dart';

/// Alerts list screen with location-specific threat classification.
///
/// ## Design Notes:
/// - Reads Household profile from Hive (local only, no network calls)
/// - Reads CachedAlerts from Hive (local only, no network calls)
/// - Applies sortAlerts() to enforce deterministic ordering
/// - Uses buildAlertCard() factory to render direct vs. general threats
/// - Fully functional in airplane mode with cached data only
/// - Handles all null/missing cases gracefully (no crashes)
///
/// ## QA Scenarios (manual verification after app runs):
/// 1. Set profile risk to `coastal`:
///    → Coastal-tagged alerts should be pinned at top with HIGH RISK styling
/// 2. Change risk to `flood_prone`:
///    → Close/reopen alerts screen; list should reprioritize automatically
/// 3. Alert with empty riskTags:
///    → Should render as GeneralAdvisoryAlertCard (not highlighted)
/// 4. Delete/reset household profile:
///    → No crash; all alerts render as general advisories (safe fallback)
/// 5. Airplane mode test:
///    → Same ordering, highlighting, and functionality from cached data only
class AlertsListPage extends StatefulWidget {
  const AlertsListPage({super.key});

  @override
  State<AlertsListPage> createState() => _AlertsListPageState();
}

class _AlertsListPageState extends State<AlertsListPage> {
  late final AlertsRepository _alertsRepository;
  late final HouseholdRepository _householdRepository;

  @override
  void initState() {
    super.initState();
    _alertsRepository = getAlertsRepository();
    _householdRepository = getHouseholdRepository();
  }

  /// Handle "More Details" tap on an alert card.
  ///
  /// Currently shows a snackbar; later can navigate to detail page.
  void _onMoreDetails(CachedAlert alert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Details for: ${alert.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Calculate the risk classification from household, with safe fallback.
  ///
  /// Returns 'unknown' if household is null or risk_classification is empty.
  String _getRiskClassification(Household? household) {
    if (household == null) return 'unknown';
    final riskClassification = household.risk_classification;
    if (riskClassification.isEmpty) return 'unknown';
    return riskClassification;
  }

  /// Render the alert list or empty state.
  ///
  /// Applies threat classification and sorting (Steps 2 + 3).
  /// Uses buildAlertCard factory to render correct card type (Steps 1 + 4).
  Widget _buildAlertsList(
    List<CachedAlert> alerts,
    String riskClassification,
  ) {
    // Handle empty alerts (offline resilience: no crash)
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No active alerts',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap below to check for new alerts',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
            ),
          ],
        ),
      );
    }

    // Sort alerts using Step 2 logic (deterministic ordering)
    final sortedAlerts = sortAlerts(alerts, riskClassification);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: sortedAlerts.length,
      itemBuilder: (context, index) {
        final alert = sortedAlerts[index];

        // Classify threat using Step 2 logic
        final threatBand = classifyThreat(alert, riskClassification);

        // Render using Step 4 factory (correct card type based on threat band)
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: buildAlertCard(
            alert: alert,
            threatBand: threatBand,
            onMoreDetails: () => _onMoreDetails(alert),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
      ),
      body: ValueListenableBuilder<Box<CachedAlert>>(
        valueListenable: _alertsRepository.getAlertsListenable(),
        builder: (context, alertsBox, _) {
          // Task A: Read household from Hive (local only, no network)
          final household = _householdRepository.getHousehold();
          final riskClassification = _getRiskClassification(household);

          // Task A: Read alerts from Hive (local only, no network)
          final alerts = _alertsRepository.getActiveAlerts();

          // Task B: Apply resilience:
          // - Household is null (handled by _getRiskClassification → 'unknown')
          // - risk_classification is empty or 'unknown' (handled by _getRiskClassification)
          // - alert.riskTags can be null/empty (sortAlerts/classifyThreat handle it)
          // - alerts list is empty (handled by empty state widget above)
          // → No crash paths; all cases render safely

          // Task C: No network dependency in render path (verified below)
          // - _alertsRepository.getActiveAlerts() → pure Hive read
          // - _householdRepository.getHousehold() → pure Hive read
          // - sortAlerts() → pure function, no side effects
          // - classifyThreat() → pure function, no side effects
          // - buildAlertCard() → pure widget, no network calls
          // → Fully functional in airplane mode

          return _buildAlertsList(alerts, riskClassification);
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Refresh alerts',
        onPressed: () {
          // Placeholder for future sync logic (not in render path)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Alert sync would happen here (future feature)'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
