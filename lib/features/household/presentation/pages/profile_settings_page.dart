import 'package:flutter/material.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/crisync_bottom_navigation.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/dashboard_design.dart';
import 'package:project_bihon/features/evacuation_centers/presentation/widgets/download_map_button.dart';
import 'package:project_bihon/features/household/data/repositories/household_repository.dart';
import 'package:project_bihon/features/household/presentation/widgets/risk_classification_picker.dart'
    as rcp;

/// Profile settings page for household configuration.
///
/// Allows users to view and edit their household profile, including
/// the home location type (risk classification).
///
/// Changes are saved immediately to Hive.
class ProfileSettingsPage extends StatefulWidget {
  /// The household repository for reading/writing data.
  final HouseholdRepository householdRepository;

  const ProfileSettingsPage({
    super.key,
    required this.householdRepository,
  });

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  static const String _appVersion = 'v1.0.0';

  late Future<void> _loadingFuture;
  String _currentRiskClassification = 'unknown';

  @override
  void initState() {
    super.initState();
    _loadingFuture = _loadHouseholdData();
  }

  /// Load household data from Hive.
  Future<void> _loadHouseholdData() async {
    try {
      final household =
          await widget.householdRepository.getOrCreateHousehold();
      if (!mounted) return;
      setState(() {
        _currentRiskClassification = household.risk_classification;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentRiskClassification = 'unknown';
      });
    }
  }

  String _getLabelForClassification(String classification) {
    return switch (classification) {
      'coastal' => 'Coastal area',
      'flood_prone' => 'Near river or low-lying area',
      'landslide_prone' => 'Mountainous / landslide-prone area',
      'urban' => 'Urban area',
      _ => 'Unknown / Not sure',
    };
  }

  void _handleBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacementNamed('/home');
  }

  void _openTab(int index) {
    final navigator = Navigator.of(context);
    final routeName = switch (index) {
      0 => '/home',
      1 => '/alerts',
      2 => '/evacuation-centers',
      3 => '/supplies',
      4 => '/contacts',
      _ => null,
    };

    if (routeName == null) {
      return;
    }

    if (routeName == '/home') {
      navigator.pushNamedAndRemoveUntil(routeName, (route) => false);
      return;
    }

    navigator.pushReplacementNamed(routeName);
  }

  Future<void> _showRiskPicker() async {
    final initialValue =
        rcp.riskClassificationOptions.containsKey(_currentRiskClassification)
            ? _currentRiskClassification
            : null;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: DashboardDesign.surface(context),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Home location type',
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose the category that best matches your household risk profile.',
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                        color: DashboardDesign.mutedText(sheetContext),
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 18),
                rcp.RiskClassificationPicker(
                  householdRepository: widget.householdRepository,
                  initialValue: initialValue,
                  onChanged: () async {
                    Navigator.of(sheetContext).pop();
                    await _loadHouseholdData();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showUnavailable(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label is not available yet.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardDesign.background(context),
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: DashboardDesign.surface(context),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: _handleBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Profile Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: const [
          SizedBox(width: 56),
        ],
      ),
      bottomNavigationBar: CrisyncBottomNavigation(
        selectedIndex: null,
        onDestinationSelected: _openTab,
      ),
      body: FutureBuilder<void>(
        future: _loadingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 104),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 768),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionTitle('Household'),
                      _SettingsCard(
                        child: _SettingsRow(
                          title: 'Home location type',
                          subtitle: _getLabelForClassification(
                            _currentRiskClassification,
                          ),
                          trailing: const Icon(Icons.expand_more),
                          onTap: _showRiskPicker,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle('Offline Maps'),
                      const DownloadOfflineMapButton(),
                      const SizedBox(height: 10),
                      Text(
                        'Download the Baybay City map for offline use during emergencies.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DashboardDesign.mutedText(context),
                              height: 1.35,
                            ),
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle('App Information'),
                      _SettingsCard(
                        child: Column(
                          children: [
                            _SettingsRow(
                              title: 'Privacy Policy',
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showUnavailable('Privacy Policy'),
                            ),
                            const _SettingsDivider(),
                            _SettingsRow(
                              title: 'Terms of Service',
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showUnavailable('Terms of Service'),
                            ),
                            const _SettingsDivider(),
                            const _SettingsRow(
                              title: 'App Version',
                              trailing: Text(
                                _appVersion,
                                style: TextStyle(
                                  color: Color(0xFF49454F),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
            ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DashboardDesign.surface(context),
        borderRadius: BorderRadius.circular(DashboardDesign.radius),
        border: Border.all(color: DashboardDesign.outline(context)),
        boxShadow: DashboardDesign.cardShadow(context),
      ),
      child: child,
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DashboardDesign.mutedText(context),
                        height: 1.35,
                      ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          IconTheme(
            data: IconThemeData(
              color: DashboardDesign.mutedText(context),
              size: 24,
            ),
            child: trailing!,
          ),
        ],
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DashboardDesign.radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: content,
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: DashboardDesign.outline(context),
    );
  }
}
