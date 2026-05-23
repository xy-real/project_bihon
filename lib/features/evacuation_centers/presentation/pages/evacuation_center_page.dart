import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:project_bihon/features/evacuation_centers/data/models/cached_evac_center.dart';
import 'package:project_bihon/features/evacuation_centers/data/repositories/evacuation_center_repository.dart';
import 'package:project_bihon/features/evacuation_centers/domain/evacuation_center_service.dart';
import 'package:project_bihon/features/evacuation_centers/presentation/widgets/evacuation_map_view.dart';
import 'package:project_bihon/features/evacuation_centers/presentation/widgets/evac_center_card.dart';
import 'package:project_bihon/main.dart' show getEvacuationCenterRepository;
import 'package:project_bihon/shared/widgets/app_alert_banner.dart';

/// Enum for evacuation centers page view modes.
enum _ViewMode { list, map }

/// Evacuation Centers page with list and map view modes.
///
/// Features:
/// - Toggle between list and map views via AppBar icon button
/// - Displays evacuation centers sorted by distance from user
/// - Shows offline banner when in offline mode
/// - Loading indicator while fetching data
/// - Empty state message when no centers are cached
/// - Reuses user position for map view (no second GPS request)
class EvacuationCenterPage extends StatefulWidget {
  const EvacuationCenterPage({super.key});

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

  /// Load evacuation centers and handle offline detection.
  ///
  /// Process:
  /// 1. Fetch all centers from repository (cached data)
  /// 2. Sort centers by distance using service
  /// 3. Try to sync fresh data from Supabase
  /// 4. If sync fails, mark as offline
  /// 5. Cache user position for map view reuse
  Future<void> _loadCenters() async {
    try {
      setState(() => _isLoading = true);

      // Step 1: Get all cached centers
      final allCenters = _repository.getAll();

      // Step 2: Get sorted centers and user position
      final sortedCenters =
          await EvacuationCenterService.getSortedCenters(allCenters);
      _userPosition = EvacuationCenterService.lastKnownPosition;

      // Step 3: Try to sync fresh data from Supabase
      try {
        await _repository.syncFromSupabase();
        // If sync succeeds, re-fetch sorted centers with potentially new data
        final refreshedCenters = _repository.getAll();
        final refreshedSorted =
            await EvacuationCenterService.getSortedCenters(refreshedCenters);
        setState(() {
          _centers = refreshedSorted;
          _isOffline = false;
        });
      } catch (e) {
        // Sync failed: mark as offline and use cached sorted centers
        setState(() {
          _centers = sortedCenters;
          _isOffline = true;
        });
      }
    } catch (e) {
      // Fallback error handling
      setState(() {
        _centers = [];
        _isOffline = true;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Build list view of evacuation centers.
  Widget _buildListView() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (_centers.isEmpty) {
      return Center(
        child: AppAlertBanner(
          variant: AppAlertBannerVariant.primary,
          title: 'No evacuation centers found. Connect to the internet to sync data.',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _centers.length,
      itemBuilder: (context, index) {
        final center = _centers[index];
        // Calculate distance if user position is available
        final distance = _userPosition != null
            ? Geolocator.distanceBetween(
                _userPosition!.latitude,
                _userPosition!.longitude,
                center.latitude,
                center.longitude,
              )
            : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EvacCenterCard(
            center: center,
            distanceMeters: distance,
          ),
        );
      },
    );
  }

  /// Build map view of evacuation centers.
  Widget _buildMapView() {
    return EvacuationMapView(
      centers: _centers,
      userPosition: _userPosition,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evacuation Centers'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Toggle list/map view button
          IconButton(
            tooltip: _viewMode == _ViewMode.list ? 'Show Map' : 'Show List',
            icon: Icon(
              _viewMode == _ViewMode.list
                  ? LucideIcons.mapPin
                  : LucideIcons.list,
            ),
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == _ViewMode.list
                    ? _ViewMode.map
                    : _ViewMode.list;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline banner (if offline)
          if (_isOffline)
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppAlertBanner(
                variant: AppAlertBannerVariant.primary,
                title: 'Offline Mode: Showing pre-cached map and centers.',
              ),
            ),

          // Content (list or map)
          Expanded(
            child: _viewMode == _ViewMode.list
                ? _buildListView()
                : _buildMapView(),
          ),
        ],
      ),
      floatingActionButton: _viewMode == _ViewMode.list
          ? FloatingActionButton.extended(
              onPressed: _loadCenters,
              label: const Text('Refresh'),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh evacuation centers',
            )
          : null,
    );
  }
}
