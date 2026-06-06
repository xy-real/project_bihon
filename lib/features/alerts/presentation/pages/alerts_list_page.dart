import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_bihon/features/alerts/data/models/cached_alert.dart';
import 'package:project_bihon/features/alerts/data/repositories/alerts_repository.dart';
import 'package:project_bihon/features/alerts/domain/threat_classification.dart';
import 'package:project_bihon/features/alerts/presentation/widgets/alert_card_factory.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/crisync_bottom_navigation.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/crisync_main_app_bar.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/dashboard_design.dart';
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
  const AlertsListPage({
    super.key,
    this.showBottomNavigation = true,
    this.onTabSelected,
  });

  final bool showBottomNavigation;
  final ValueChanged<int>? onTabSelected;

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
      const SnackBar(
        content: Text('Alert details are not available yet.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openTab(int index) {
    final onTabSelected = widget.onTabSelected;
    if (onTabSelected != null) {
      onTabSelected(index);
      return;
    }

    final navigator = Navigator.of(context);
    final routeName = switch (index) {
      0 => '/home',
      1 => null,
      2 => '/evacuation-centers',
      3 => '/supplies',
      4 => '/contacts',
      _ => null,
    };

    if (routeName == null) {
      return;
    }

    if (index == 0) {
      navigator.pushNamedAndRemoveUntil(routeName, (route) => false);
    } else {
      navigator.pushReplacementNamed(routeName);
    }
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
      return Container(
        constraints: const BoxConstraints(minHeight: 220),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DashboardDesign.surface(context),
          borderRadius: BorderRadius.circular(DashboardDesign.radius),
          border: Border.all(color: DashboardDesign.outline(context)),
          boxShadow: DashboardDesign.cardShadow(context),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DashboardDesign.statusBackground(
                  context,
                  DashboardDesign.info,
                ),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: DashboardDesign.info,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No active alerts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Cached alerts will appear here when they are available.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DashboardDesign.mutedText(context),
                  ),
            ),
          ],
        ),
      );
    }

    // Sort alerts using Step 2 logic (deterministic ordering)
    final sortedAlerts = sortAlerts(alerts, riskClassification);

    return Column(
      children: [
        for (var index = 0; index < sortedAlerts.length; index++) ...[
          Builder(
            builder: (context) {
              final alert = sortedAlerts[index];

              // Classify threat using Step 2 logic
              final threatBand = classifyThreat(alert, riskClassification);

              // Render using Step 4 factory (correct card type based on threat band)
              return buildAlertCard(
                alert: alert,
                threatBand: threatBand,
                onTap: threatBand == ThreatBand.direct
                    ? () => _onMoreDetails(alert)
                    : null,
                onMoreDetails: threatBand == ThreatBand.direct
                    ? () => _onMoreDetails(alert)
                    : null,
              );
            },
          ),
          if (index != sortedAlerts.length - 1)
            const SizedBox(height: DashboardDesign.gap),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alerts',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Stay updated with critical information in your area.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DashboardDesign.mutedText(context),
              ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = MediaQuery.sizeOf(context).width >= 600
        ? DashboardDesign.marginTablet
        : DashboardDesign.marginMobile;

    return Scaffold(
      backgroundColor: DashboardDesign.background(context),
      appBar: const CrisyncMainAppBar(),
      bottomNavigationBar: widget.showBottomNavigation
          ? CrisyncBottomNavigation(
              selectedIndex: 1,
              onDestinationSelected: _openTab,
            )
          : null,
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

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                DashboardDesign.gap,
                horizontalPadding,
                widget.showBottomNavigation ? 96 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: DashboardDesign.gap),
                      _buildAlertsList(alerts, riskClassification),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
