import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project_bihon/features/evacuation/data/models/cached_evac_center.dart';

/// Service for handling geolocation and sorting of evacuation centers.
///
/// Responsibilities:
/// - Request and check location permissions
/// - Fetch current user position
/// - Sort evacuation centers by distance or alphabetically
class EvacLocationService {
  /// Gets the current user position after requesting location permission.
  ///
  /// Returns null if permission is denied. Does not throw exceptions.
  Future<Position?> getCurrentPosition() async {
    // Request location permission
    final status = await Permission.location.request();

    // Return null if permission is denied or permanently denied
    if (!status.isGranted) {
      return null;
    }

    try {
      // Get current position with a timeout
      final position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 30),
      );
      return position;
    } catch (e) {
      // If unable to get position, return null gracefully
      return null;
    }
  }

  /// Sorts evacuation centers by distance from the user's position.
  ///
  /// Uses [Geolocator.distanceBetween] to calculate distances.
  /// Returns a new list sorted from nearest to furthest.
  /// Does not mutate the input list.
  List<CachedEvacCenter> sortByDistance(
    List<CachedEvacCenter> centers,
    Position userPosition,
  ) {
    // Create a copy to avoid mutating the input list
    final sortedCenters = List<CachedEvacCenter>.from(centers);

    // Calculate distances and sort
    sortedCenters.sort((a, b) {
      final distanceA = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        a.latitude,
        a.longitude,
      );

      final distanceB = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        b.latitude,
        b.longitude,
      );

      return distanceA.compareTo(distanceB);
    });

    return sortedCenters;
  }

  /// Sorts evacuation centers alphabetically by name.
  ///
  /// Used as fallback when location permission is denied.
  /// Returns a new list sorted A-Z by name.
  /// Does not mutate the input list.
  List<CachedEvacCenter> sortAlphabetically(
    List<CachedEvacCenter> centers,
  ) {
    // Create a copy to avoid mutating the input list
    final sortedCenters = List<CachedEvacCenter>.from(centers);

    // Sort alphabetically by name
    sortedCenters.sort((a, b) => a.name.compareTo(b.name));

    return sortedCenters;
  }

  /// Gets sorted evacuation centers with automatic fallback logic.
  ///
  /// - If location permission is granted: returns centers sorted by distance
  /// - If location permission is denied: returns centers sorted alphabetically
  ///
  /// This is the main entry point for consumers of this service.
  Future<List<CachedEvacCenter>> getSortedCenters(
    List<CachedEvacCenter> centers,
  ) async {
    // Try to get user's current position
    final userPosition = await getCurrentPosition();

    // If permission granted and position obtained, sort by distance
    if (userPosition != null) {
      return sortByDistance(centers, userPosition);
    }

    // Fallback: sort alphabetically if location is unavailable
    return sortAlphabetically(centers);
  }
}
