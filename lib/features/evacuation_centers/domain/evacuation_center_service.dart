import 'dart:developer' as developer;

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project_bihon/features/evacuation_centers/data/models/cached_evac_center.dart';

/// Service for location-based operations on evacuation centers.
///
/// Provides methods to:
/// - Sort evacuation centers by distance from user location
/// - Request location permissions
/// - Calculate distances between points
/// - Cache the last known user position for map view reuse
///
/// All operations are designed with graceful fallbacks:
/// - If location permission is denied, returns centers sorted alphabetically
/// - If GPS fails, returns centers sorted alphabetically
/// - Never throws exceptions; always returns a sorted list
class EvacuationCenterService {
  EvacuationCenterService._();

  /// The user's last known position from a successful getSortedCenters() call.
  ///
  /// Useful for map views and other features that need the user's location
  /// without making a second GPS request.
  static Position? _lastKnownPosition;

  /// Get the last known user position, or null if never successfully determined.
  static Position? get lastKnownPosition => _lastKnownPosition;

  /// Sort evacuation centers by distance from the user's current location.
  ///
  /// Process:
  /// 1. Requests location permission (if not already granted)
  /// 2. If permission is granted: fetches current GPS position and calculates
  ///    distance to each center, returning centers sorted by distance (nearest first)
  /// 3. If permission is denied OR GPS fails: returns centers sorted alphabetically
  ///    by name (graceful fallback for offline/permission-denied scenarios)
  ///
  /// Parameters:
  /// - [centers]: List of evacuation centers to sort. If empty, returns empty list.
  ///
  /// Returns:
  /// - Sorted list of centers (never null, never throws)
  /// - If location available: sorted by distance (ascending)
  /// - If location unavailable: sorted alphabetically by name
  ///
  /// Side effect:
  /// - On successful GPS fetch, [lastKnownPosition] is cached for later reuse
  static Future<List<CachedEvacCenter>> getSortedCenters(
    List<CachedEvacCenter> centers,
  ) async {
    if (centers.isEmpty) {
      return [];
    }

    // Try to get user location
    final userPosition = await _requestLocationAndGetPosition();

    if (userPosition != null) {
      // Cache the position for map view reuse
      _lastKnownPosition = userPosition;

      // Sort by distance from user
      final centersWithDistance = centers.map((center) {
        final distance = _calculateDistance(
          userPosition.latitude,
          userPosition.longitude,
          center.latitude,
          center.longitude,
        );
        return (center: center, distance: distance);
      }).toList();

      centersWithDistance.sort((a, b) => a.distance.compareTo(b.distance));
      return centersWithDistance.map((e) => e.center).toList();
    }

    // Fallback: sort alphabetically by name
    developer.log('Location unavailable; sorting evacuation centers alphabetically');
    final sorted = List<CachedEvacCenter>.from(centers);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  /// Calculate distance between two geographic coordinates in meters.
  ///
  /// Parameters:
  /// - [startLatitude], [startLongitude]: Starting point
  /// - [endLatitude], [endLongitude]: End point
  ///
  /// Returns: Distance in meters (using haversine formula via Geolocator)
  static double _calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Calculate distance from a user position to an evacuation center.
  ///
  /// Parameters:
  /// - [center]: The evacuation center
  /// - [userPosition]: The user's current position
  ///
  /// Returns:
  /// - Distance in meters if both coordinates are valid
  /// - `null` if calculation fails or inputs are invalid
  ///
  /// Example:
  /// ```dart
  /// final position = await Geolocator.getCurrentPosition();
  /// final distance = EvacuationCenterService.distanceTo(center, position);
  /// if (distance != null) {
  ///   print('Distance: ${(distance / 1000).toStringAsFixed(2)} km');
  /// }
  /// ```
  static double? distanceTo(CachedEvacCenter center, Position userPosition) {
    try {
      return _calculateDistance(
        userPosition.latitude,
        userPosition.longitude,
        center.latitude,
        center.longitude,
      );
    } catch (e) {
      developer.log('Error calculating distance to evacuation center: $e');
      return null;
    }
  }

  /// Request location permission and return the user's current position.
  ///
  /// Returns:
  /// - [Position] if permission is granted and GPS is available
  /// - `null` if permission is denied, GPS is unavailable, or any error occurs
  ///
  /// Never throws; logs errors for debugging.
  static Future<Position?> _requestLocationAndGetPosition() async {
    try {
      // Check current permission status
      PermissionStatus status = await Permission.location.request();

      if (status.isDenied) {
        developer.log('Location permission denied');
        return null;
      }

      if (status.isPermanentlyDenied) {
        developer.log('Location permission permanently denied; opening app settings');
        openAppSettings();
        return null;
      }

      // Permission granted; get current position
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        developer.log('Got user position: ${position.latitude}, ${position.longitude}');
        return position;
      } catch (e) {
        developer.log('Error getting GPS position: $e');
        return null;
      }
    } catch (e) {
      developer.log('Error requesting location permission: $e');
      return null;
    }
  }
}
