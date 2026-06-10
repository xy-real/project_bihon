import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:project_bihon/features/evacuation_centers/data/models/cached_evac_center.dart';
import 'package:project_bihon/features/evacuation_centers/data/repositories/evacuation_center_repository.dart';

void main() {
  late Directory hiveDirectory;
  late List<Map<String, dynamic>> remoteRows;
  late EvacuationCenterRepository repository;

  setUp(() async {
    hiveDirectory =
        await Directory.systemTemp.createTemp('evacuation_center_test_');
    Hive.init(hiveDirectory.path);
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(CachedEvacCenterAdapter());
    }

    remoteRows = [];
    repository = EvacuationCenterRepository(
      rowsFetcher: () async => remoteRows,
    );
    await repository.initBox();
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('parses canonical numeric coordinate values', () {
    final center = EvacuationCenterRepository.parseRow({
      'center_id': 'center-1',
      'name': 'Baybay City Gym',
      'latitude': 10.684,
      'longitude': 124.8,
      'capacity': 75,
      'status': 'Open',
    });

    expect(center, isNotNull);
    expect(center!.latitude, 10.684);
    expect(center.longitude, 124.8);
    expect(center.capacity, 75);
    expect(center.hasValidCoordinates, isTrue);
  });

  test('parses numeric strings and compatible column aliases', () {
    final center = EvacuationCenterRepository.parseRow({
      'id': 42,
      'center_name': 'Barangay Hall',
      'lat': '10.7012',
      'lng': '124.8123',
      'capacity_percent': '60',
      'availability_status': 'near_capacity',
    });

    expect(center, isNotNull);
    expect(center!.id, '42');
    expect(center.name, 'Barangay Hall');
    expect(center.latitude, 10.7012);
    expect(center.longitude, 124.8123);
    expect(center.capacity, 60);
    expect(center.status, 'Near Capacity');
  });

  test('keeps centers with missing coordinates list-safe', () {
    final center = EvacuationCenterRepository.parseRow({
      'center_id': 'center-2',
      'name': 'Coordinate Pending Center',
      'capacity': 20,
      'status': 'open',
    });

    expect(center, isNotNull);
    expect(center!.hasValidCoordinates, isFalse);
  });

  test('sync caches parsed Supabase rows in Hive', () async {
    remoteRows = [
      {
        'center_id': 'center-3',
        'name': 'Eastern School',
        'latitude': '10.69',
        'longitude': '124.81',
        'capacity': 45,
        'status': 'Open',
      },
    ];

    final succeeded = await repository.syncFromSupabase();

    expect(succeeded, isTrue);
    expect(repository.getAll(), hasLength(1));
    expect(repository.getAll().single.name, 'Eastern School');
  });

  test('sync preserves cache when all remote rows are unusable', () async {
    remoteRows = [
      {
        'center_id': 'cached-center',
        'name': 'Cached Center',
        'latitude': 10.69,
        'longitude': 124.81,
      },
    ];
    expect(await repository.syncFromSupabase(), isTrue);

    remoteRows = [
      {
        'name': 'Missing identifier',
        'latitude': 10.7,
        'longitude': 124.82,
      },
    ];

    final succeeded = await repository.syncFromSupabase();

    expect(succeeded, isFalse);
    expect(repository.getAll(), hasLength(1));
    expect(repository.getAll().single.id, 'cached-center');
  });

  test('empty remote response preserves cache and reports failure', () async {
    remoteRows = [
      {
        'center_id': 'cached-center',
        'name': 'Cached Center',
        'latitude': 10.69,
        'longitude': 124.81,
      },
    ];
    expect(await repository.syncFromSupabase(), isTrue);

    remoteRows = [];
    final succeeded = await repository.syncFromSupabase();

    expect(succeeded, isFalse);
    expect(repository.getAll(), hasLength(1));
  });

}
