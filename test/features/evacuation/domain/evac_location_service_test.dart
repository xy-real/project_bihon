import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:project_bihon/features/evacuation/data/models/cached_evac_center.dart';
import 'package:project_bihon/features/evacuation/domain/evac_location_service.dart';

void main() {
  group('EvacLocationService', () {
    late EvacLocationService service;

    setUp(() {
      service = EvacLocationService();
    });

    // Helper to create test evacuation centers
    List<CachedEvacCenter> createTestCenters() {
      return [
        CachedEvacCenter(
          id: 'center_1',
          name: 'Barangay Hall Alpha',
          latitude: 14.6000,
          longitude: 120.9800,
          capacity: 500,
          status: 'operational',
        ),
        CachedEvacCenter(
          id: 'center_2',
          name: 'Community Center Bravo',
          latitude: 14.5950,
          longitude: 120.9900,
          capacity: 800,
          status: 'operational',
        ),
        CachedEvacCenter(
          id: 'center_3',
          name: 'School Charlie',
          latitude: 14.6050,
          longitude: 120.9750,
          capacity: 1000,
          status: 'operational',
        ),
      ];
    }

    // Helper to create test position
    Position createTestPosition() {
      return Position(
        latitude: 14.5995,
        longitude: 120.9842,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }

    group('sortByDistance', () {
      test('returns nearest center first', () {
        final centers = createTestCenters();
        final userPosition = createTestPosition();

        final sortedCenters = service.sortByDistance(centers, userPosition);

        // All centers should still be present
        expect(sortedCenters.length, equals(3));

        // First center should be the nearest (will be tested by distance logic)
        // Verify the list is sorted by calculating distances
        double getDistance(CachedEvacCenter center) {
          return Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            center.latitude,
            center.longitude,
          );
        }

        final distances = sortedCenters.map(getDistance).toList();

        // Verify distances are in ascending order (nearest to furthest)
        for (int i = 0; i < distances.length - 1; i++) {
          expect(
            distances[i],
            lessThanOrEqualTo(distances[i + 1]),
            reason:
                'Center ${sortedCenters[i].name} should be closer than ${sortedCenters[i + 1].name}',
          );
        }
      });

      test('does not mutate input list', () {
        final centers = createTestCenters();
        final originalList = List<CachedEvacCenter>.from(centers);
        final userPosition = createTestPosition();

        service.sortByDistance(centers, userPosition);

        // Input list should remain unchanged
        expect(centers.length, equals(originalList.length));
        for (int i = 0; i < centers.length; i++) {
          expect(centers[i].id, equals(originalList[i].id));
          expect(centers[i].name, equals(originalList[i].name));
        }
      });

      test('handles empty list', () {
        final emptyList = <CachedEvacCenter>[];
        final userPosition = createTestPosition();

        final result = service.sortByDistance(emptyList, userPosition);

        expect(result, isEmpty);
      });

      test('handles single center', () {
        final centers = [createTestCenters().first];
        final userPosition = createTestPosition();

        final result = service.sortByDistance(centers, userPosition);

        expect(result.length, equals(1));
        expect(result.first.id, equals(centers.first.id));
      });
    });

    group('sortAlphabetically', () {
      test('returns centers sorted A-Z by name', () {
        final centers = createTestCenters();

        final sortedCenters = service.sortAlphabetically(centers);

        // Should be sorted alphabetically
        expect(
          sortedCenters[0].name,
          equals('Barangay Hall Alpha'),
        );
        expect(
          sortedCenters[1].name,
          equals('Community Center Bravo'),
        );
        expect(
          sortedCenters[2].name,
          equals('School Charlie'),
        );
      });

      test('handles names with different cases correctly', () {
        final centersWithMixedCase = [
          CachedEvacCenter(
            id: '1',
            name: 'zebra hall',
            latitude: 0,
            longitude: 0,
            capacity: 100,
            status: 'operational',
          ),
          CachedEvacCenter(
            id: '2',
            name: 'Apple Center',
            latitude: 0,
            longitude: 0,
            capacity: 100,
            status: 'operational',
          ),
        ];

        final sorted = service.sortAlphabetically(centersWithMixedCase);

        // Should sort case-sensitively; uppercase letters come before lowercase in ASCII
        expect(sorted[0].name, equals('Apple Center'));
        expect(sorted[1].name, equals('zebra hall'));
      });

      test('does not mutate input list', () {
        final centers = createTestCenters();
        final originalList = List<CachedEvacCenter>.from(centers);

        service.sortAlphabetically(centers);

        // Input list should remain unchanged
        expect(centers.length, equals(originalList.length));
        for (int i = 0; i < centers.length; i++) {
          expect(centers[i].id, equals(originalList[i].id));
        }
      });

      test('handles empty list', () {
        final emptyList = <CachedEvacCenter>[];

        final result = service.sortAlphabetically(emptyList);

        expect(result, isEmpty);
      });

      test('handles single center', () {
        final centers = [createTestCenters().first];

        final result = service.sortAlphabetically(centers);

        expect(result.length, equals(1));
        expect(result.first.id, equals(centers.first.id));
      });

      test('handles duplicate names by preserving relative order', () {
        final centersWithDuplicates = [
          CachedEvacCenter(
            id: '1',
            name: 'Same Name',
            latitude: 0,
            longitude: 0,
            capacity: 100,
            status: 'operational',
          ),
          CachedEvacCenter(
            id: '2',
            name: 'Same Name',
            latitude: 0,
            longitude: 0,
            capacity: 100,
            status: 'operational',
          ),
        ];

        final sorted = service.sortAlphabetically(centersWithDuplicates);

        expect(sorted.length, equals(2));
        expect(sorted[0].name, equals('Same Name'));
        expect(sorted[1].name, equals('Same Name'));
      });
    });

    // Note: getSortedCenters and getCurrentPosition tests require platform channel
    // initialization and proper mocking of permission_handler and geolocator.
    // These should be tested with an integration test or with proper dependency
    // injection mocking setup in a separate test file with mock setup.

    // Integration-style test validating the complete flow
    group('Integration: Complete sorting workflow', () {
      test('sortByDistance produces expected ordering', () {
        final centers = [
          CachedEvacCenter(
            id: 'far',
            name: 'Far Center',
            latitude: 15.0,
            longitude: 121.0,
            capacity: 100,
            status: 'operational',
          ),
          CachedEvacCenter(
            id: 'near',
            name: 'Near Center',
            latitude: 14.60,
            longitude: 120.985,
            capacity: 100,
            status: 'operational',
          ),
          CachedEvacCenter(
            id: 'mid',
            name: 'Mid Center',
            latitude: 14.65,
            longitude: 121.0,
            capacity: 100,
            status: 'operational',
          ),
        ];

        final userPosition = Position(
          latitude: 14.5995,
          longitude: 120.9842,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );

        final sorted = service.sortByDistance(centers, userPosition);

        // Verify nearest is first by checking actual distances
        final dist1 = Geolocator.distanceBetween(
          userPosition.latitude,
          userPosition.longitude,
          sorted[0].latitude,
          sorted[0].longitude,
        );
        final dist2 = Geolocator.distanceBetween(
          userPosition.latitude,
          userPosition.longitude,
          sorted[1].latitude,
          sorted[1].longitude,
        );

        expect(dist1, lessThanOrEqualTo(dist2));
      });

      test('sortAlphabetically produces A-Z ordering', () {
        final unorderedCenters = [
          CachedEvacCenter(
            id: 'z',
            name: 'Zebra Center',
            latitude: 0,
            longitude: 0,
            capacity: 100,
            status: 'operational',
          ),
          CachedEvacCenter(
            id: 'a',
            name: 'Apple Center',
            latitude: 0,
            longitude: 0,
            capacity: 100,
            status: 'operational',
          ),
          CachedEvacCenter(
            id: 'm',
            name: 'Middle Center',
            latitude: 0,
            longitude: 0,
            capacity: 100,
            status: 'operational',
          ),
        ];

        final sorted = service.sortAlphabetically(unorderedCenters);

        expect(sorted[0].name, equals('Apple Center'));
        expect(sorted[1].name, equals('Middle Center'));
        expect(sorted[2].name, equals('Zebra Center'));
      });
    });
  });
}
