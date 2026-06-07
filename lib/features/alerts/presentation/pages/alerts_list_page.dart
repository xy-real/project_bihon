import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_bihon/features/alerts/data/models/alert_sync_state.dart';
import 'package:project_bihon/features/alerts/data/models/cached_alert.dart';
import 'package:project_bihon/features/alerts/data/repositories/alerts_repository.dart';
import 'package:project_bihon/features/alerts/data/services/alert_sync_service.dart';
import 'package:project_bihon/features/alerts/domain/threat_classification.dart';
import 'package:project_bihon/features/alerts/presentation/widgets/alert_card_factory.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/crisync_bottom_navigation.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/crisync_main_app_bar.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/dashboard_design.dart';
import 'package:project_bihon/features/household/data/repositories/household_repository.dart';
import 'package:project_bihon/shared/models/household.dart';

class AlertsListPage extends StatefulWidget {
  const AlertsListPage({
    super.key,
    this.showBottomNavigation = true,
    this.onTabSelected,
    required this.alertsRepository,
    required this.alertSyncService,
    required this.householdRepository,
    this.syncStateBox,
  });

  final bool showBottomNavigation;
  final ValueChanged<int>? onTabSelected;
  final AlertsRepository alertsRepository;
  final AlertSyncService alertSyncService;
  final HouseholdRepository householdRepository;
  final Box<AlertSyncState>? syncStateBox;

  @override
  State<AlertsListPage> createState() => _AlertsListPageState();
}

class _AlertsListPageState extends State<AlertsListPage> {
  late final AlertsRepository _alertsRepository;
  late final AlertSyncService _alertSyncService;
  late final HouseholdRepository _householdRepository;
  late final Box<AlertSyncState> _syncStateBox;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _alertsRepository = widget.alertsRepository;
    _alertSyncService = widget.alertSyncService;
    _householdRepository = widget.householdRepository;
    _syncStateBox =
        widget.syncStateBox ?? Hive.box<AlertSyncState>(AlertSyncState.boxName);
  }

  Future<void> _refreshAlerts() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    var succeeded = false;
    try {
      succeeded = await _alertSyncService.syncAlerts();
    } catch (_) {
      succeeded = false;
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }

    if (!succeeded && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to refresh. Showing cached alerts.'),
        ),
      );
    }
  }

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

  String _getRiskClassification(Household? household) {
    if (household == null) return 'unknown';
    final riskClassification = household.risk_classification;
    if (riskClassification.isEmpty) return 'unknown';
    return riskClassification;
  }

  Widget _buildAlertsList(
    List<CachedAlert> alerts,
    String riskClassification,
    AlertSyncState? syncState,
  ) {
    if (alerts.isEmpty) {
      return _EmptyAlertsState(
        hasSyncError: _hasSyncError(syncState),
        isRefreshing: _isRefreshing,
        onRefresh: _refreshAlerts,
      );
    }

    final sortedAlerts = sortAlerts(alerts, riskClassification);

    return Column(
      children: [
        for (var index = 0; index < sortedAlerts.length; index++) ...[
          Builder(
            builder: (context) {
              final alert = sortedAlerts[index];
              final threatBand = classifyThreat(alert, riskClassification);
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

  Widget _buildFreshnessBanner({
    required AlertSyncState? syncState,
    required bool hasCachedAlerts,
  }) {
    final state = _freshnessState(syncState, hasCachedAlerts);
    final statusColor = switch (state.kind) {
      _FreshnessKind.ok => DashboardDesign.success,
      _FreshnessKind.warning => DashboardDesign.warning,
      _FreshnessKind.error => DashboardDesign.danger,
      _FreshnessKind.empty => DashboardDesign.info,
    };
    final statusIcon = switch (state.kind) {
      _FreshnessKind.ok => Icons.check_circle_outline_rounded,
      _FreshnessKind.warning => Icons.wifi_off_rounded,
      _FreshnessKind.error => Icons.error_outline_rounded,
      _FreshnessKind.empty => Icons.notifications_none_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DashboardDesign.surface(context),
        borderRadius: BorderRadius.circular(DashboardDesign.radius),
        border: Border.all(color: DashboardDesign.outline(context)),
        boxShadow: DashboardDesign.cardShadow(context),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: DashboardDesign.statusBackground(context, statusColor),
              borderRadius: BorderRadius.circular(
                DashboardDesign.compactRadius,
              ),
            ),
            child: Icon(statusIcon, color: statusColor, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                if (state.subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    state.subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DashboardDesign.mutedText(context),
                          height: 1.35,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (_isRefreshing) ...[
            const SizedBox(width: 10),
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ],
      ),
    );
  }

  _FreshnessState _freshnessState(
    AlertSyncState? syncState,
    bool hasCachedAlerts,
  ) {
    final hasError = _hasSyncError(syncState);
    if (hasError && hasCachedAlerts) {
      return const _FreshnessState(
        kind: _FreshnessKind.warning,
        title: 'Offline: showing cached alerts',
        subtitle: 'Last refresh failed. Pull down to try again.',
      );
    }

    if (hasError && !hasCachedAlerts) {
      return const _FreshnessState(
        kind: _FreshnessKind.error,
        title: 'No cached alerts yet',
        subtitle: 'Unable to refresh alerts. Pull down to try again.',
      );
    }

    final updatedAt = syncState?.lastSuccessfulSyncAt;
    if (updatedAt != null) {
      return _FreshnessState(
        kind: _FreshnessKind.ok,
        title: 'Updated ${_formatElapsed(updatedAt)} ago',
        subtitle: 'Alerts are loaded from the local cache.',
      );
    }

    if (!hasCachedAlerts) {
      return const _FreshnessState(
        kind: _FreshnessKind.empty,
        title: 'No cached alerts yet',
        subtitle: 'Pull down to fetch alerts when connected.',
      );
    }

    return const _FreshnessState(
      kind: _FreshnessKind.warning,
      title: 'Offline: showing cached alerts',
      subtitle: 'Cached alerts are available without a recent sync timestamp.',
    );
  }

  static bool _hasSyncError(AlertSyncState? syncState) {
    final error = syncState?.lastError;
    return error != null && error.trim().isNotEmpty;
  }

  String _formatElapsed(DateTime updatedAt) {
    final now = DateTime.now().toUtc();
    final elapsed = now.difference(updatedAt.toUtc());
    if (elapsed.inMinutes < 1) {
      return 'just now';
    }
    if (elapsed.inHours < 1) {
      final minutes = elapsed.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'}';
    }
    if (elapsed.inDays < 1) {
      final hours = elapsed.inHours;
      return '$hours hour${hours == 1 ? '' : 's'}';
    }
    final days = elapsed.inDays;
    return '$days day${days == 1 ? '' : 's'}';
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
      body: RefreshIndicator(
        onRefresh: _refreshAlerts,
        child: ValueListenableBuilder<Box<CachedAlert>>(
          valueListenable: _alertsRepository.getAlertsListenable(),
          builder: (context, alertsBox, _) {
            return ValueListenableBuilder<Box<AlertSyncState>>(
              valueListenable: _syncStateBox.listenable(),
              builder: (context, syncStateBox, _) {
                final household = _householdRepository.getHousehold();
                final riskClassification = _getRiskClassification(household);
                final alerts = alertsBox.values
                    .where((alert) => alert.isActive)
                    .toList(growable: false);
                final syncState =
                    syncStateBox.get(AlertSyncService.syncStateKey);

                return SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                            _buildFreshnessBanner(
                              syncState: syncState,
                              hasCachedAlerts: alerts.isNotEmpty,
                            ),
                            const SizedBox(height: DashboardDesign.gap),
                            _buildAlertsList(
                              alerts,
                              riskClassification,
                              syncState,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

enum _FreshnessKind { ok, warning, error, empty }

class _FreshnessState {
  const _FreshnessState({
    required this.kind,
    required this.title,
    this.subtitle,
  });

  final _FreshnessKind kind;
  final String title;
  final String? subtitle;
}

class _EmptyAlertsState extends StatelessWidget {
  const _EmptyAlertsState({
    required this.hasSyncError,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final bool hasSyncError;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 240),
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
                hasSyncError ? DashboardDesign.danger : DashboardDesign.info,
              ),
            ),
            child: Icon(
              hasSyncError
                  ? Icons.error_outline_rounded
                  : Icons.notifications_none_rounded,
              color:
                  hasSyncError ? DashboardDesign.danger : DashboardDesign.info,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No cached alerts yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            hasSyncError
                ? 'Unable to refresh alerts. Connect to the internet and try again.'
                : 'Pull down to fetch alerts when connected.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DashboardDesign.mutedText(context),
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: isRefreshing ? null : onRefresh,
            icon: isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            label: Text(isRefreshing ? 'Refreshing' : 'Refresh'),
          ),
        ],
      ),
    );
  }
}
