import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/crisync_bottom_navigation.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/crisync_main_app_bar.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/dashboard_design.dart';
import 'package:project_bihon/features/evacuation_centers/data/models/cached_evac_center.dart';
import 'package:project_bihon/features/evacuation_centers/data/repositories/evacuation_center_repository.dart';
import 'package:project_bihon/features/evacuation_centers/domain/evacuation_center_service.dart';
import 'package:project_bihon/features/evacuation_centers/presentation/widgets/evac_center_card.dart';
import 'package:project_bihon/features/evacuation_centers/presentation/widgets/evacuation_map_view.dart';
import 'package:project_bihon/main.dart' show getEvacuationCenterRepository;
import 'package:url_launcher/url_launcher.dart';

enum _ViewMode { list, map }

class EvacuationCenterPage extends StatefulWidget {
  const EvacuationCenterPage({
    super.key,
    this.showBottomNavigation = true,
    this.onTabSelected,
    this.onMapInteractionChanged,
  });

  final bool showBottomNavigation;
  final ValueChanged<int>? onTabSelected;
  final ValueChanged<bool>? onMapInteractionChanged;

  @override
  State<EvacuationCenterPage> createState() => _EvacuationCenterPageState();
}

class _EvacuationCenterPageState extends State<EvacuationCenterPage> {
  late final EvacuationCenterRepository _repository;

  _ViewMode _viewMode = _ViewMode.list;
  bool _isLoading = true;
  bool _isOffline = false;

  List<CachedEvacCenter> _centers = [];
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _repository = getEvacuationCenterRepository();
    _loadCenters();
  }

  Future<void> _loadCenters() async {
    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      final allCenters = _repository.getAll();
      final sortedCenters =
          await EvacuationCenterService.getSortedCenters(allCenters);
      _userPosition = EvacuationCenterService.lastKnownPosition;

      try {
        await _repository.syncFromSupabase();
        final refreshedCenters = _repository.getAll();
        final refreshedSorted =
            await EvacuationCenterService.getSortedCenters(refreshedCenters);

        if (!mounted) {
          return;
        }

        setState(() {
          _centers = refreshedSorted;
          _isOffline = false;
        });
      } catch (_) {
        if (!mounted) {
          return;
        }

        setState(() {
          _centers = sortedCenters;
          _isOffline = true;
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _centers = [];
        _isOffline = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
      1 => '/alerts',
      2 => null,
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

  Future<void> _openDirections(CachedEvacCenter center) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${center.latitude},${center.longitude}',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showSnackBar('Directions are unavailable on this device.');
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('Failed to open directions.');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  double? _distanceTo(CachedEvacCenter center) {
    final userPosition = _userPosition;
    if (userPosition == null) {
      return null;
    }

    return EvacuationCenterService.distanceTo(center, userPosition);
  }

  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DashboardDesign.statusBackground(context, DashboardDesign.info),
        borderRadius: BorderRadius.circular(DashboardDesign.compactRadius),
        border: Border.all(
          color: DashboardDesign.info.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off,
            size: 18,
            color: DashboardDesign.info,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Offline Mode - Showing cached data',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DashboardDesign.info,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final title = Text(
      'Evacuation Centers',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
    );
    final toggle = SegmentedButton<_ViewMode>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        selectedBackgroundColor: DashboardDesign.deepNavy,
        selectedForegroundColor: Colors.white,
        foregroundColor: DashboardDesign.mutedText(context),
        side: BorderSide(color: DashboardDesign.outline(context)),
      ),
      segments: const [
        ButtonSegment<_ViewMode>(
          value: _ViewMode.list,
          label: Text('List'),
        ),
        ButtonSegment<_ViewMode>(
          value: _ViewMode.map,
          label: Text('Map'),
        ),
      ],
      selected: <_ViewMode>{_viewMode},
      onSelectionChanged: (selection) {
        setState(() {
          _viewMode = selection.first;
        });
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: toggle),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: title),
            const SizedBox(width: 12),
            toggle,
          ],
        );
      },
    );
  }

  Widget _buildListContent() {
    if (_isLoading) {
      return const _LoadingCard();
    }

    if (_centers.isEmpty) {
      return const _EmptyCentersCard();
    }

    return Column(
      children: [
        for (var index = 0; index < _centers.length; index++) ...[
          EvacCenterCard(
            center: _centers[index],
            distanceMeters: _distanceTo(_centers[index]),
            onViewDirections: () => _openDirections(_centers[index]),
          ),
          if (index != _centers.length - 1)
            const SizedBox(height: DashboardDesign.gap),
        ],
      ],
    );
  }

  Widget _buildMapContent() {
    if (_isLoading) {
      return const _LoadingCard();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final mapHeight = constraints.maxWidth >= 700 ? 560.0 : 430.0;

        return Container(
          height: mapHeight,
          decoration: BoxDecoration(
            color: DashboardDesign.surface(context),
            borderRadius: BorderRadius.circular(DashboardDesign.radius),
            border: Border.all(color: DashboardDesign.outline(context)),
            boxShadow: DashboardDesign.cardShadow(context),
          ),
          clipBehavior: Clip.antiAlias,
          child: EvacuationMapView(
            centers: _centers,
            userPosition: _userPosition,
            onInteractionChanged: widget.onMapInteractionChanged,
          ),
        );
      },
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
              selectedIndex: 2,
              onDestinationSelected: _openTab,
            )
          : null,
      floatingActionButton: FloatingActionButton(
        heroTag: 'evacuation-centers-refresh',
        onPressed: _loadCenters,
        backgroundColor: DashboardDesign.deepNavy,
        foregroundColor: Colors.white,
        tooltip: 'Refresh evacuation centers',
        child: const Icon(Icons.refresh),
      ),
      body: SafeArea(
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
                  if (_isOffline) ...[
                    _buildOfflineBanner(),
                    const SizedBox(height: DashboardDesign.gap),
                  ],
                  _buildHeader(),
                  const SizedBox(height: DashboardDesign.gap),
                  _viewMode == _ViewMode.list
                      ? _buildListContent()
                      : _buildMapContent(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        color: DashboardDesign.surface(context),
        borderRadius: BorderRadius.circular(DashboardDesign.radius),
        border: Border.all(color: DashboardDesign.outline(context)),
        boxShadow: DashboardDesign.cardShadow(context),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: DashboardDesign.deepNavy,
        ),
      ),
    );
  }
}

class _EmptyCentersCard extends StatelessWidget {
  const _EmptyCentersCard();

  @override
  Widget build(BuildContext context) {
    return Container(
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
              LucideIcons.mapPin,
              color: DashboardDesign.info,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No evacuation centers found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Connect to the internet to sync center data, or try refreshing cached records.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DashboardDesign.mutedText(context),
                ),
          ),
        ],
      ),
    );
  }
}
