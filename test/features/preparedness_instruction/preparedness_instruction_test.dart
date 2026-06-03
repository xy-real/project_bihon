import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:project_bihon/features/preparedness_instruction/models/instruction_guide.dart';
import 'package:project_bihon/features/preparedness_instruction/repositories/instruction_guide_repository.dart';
import 'package:project_bihon/features/preparedness_instruction/ui/category_grid.dart';
import 'package:project_bihon/features/preparedness_instruction/ui/guide_viewer.dart';

void main() {
  late Directory hiveDir;
  late InstructionGuideRepository repository;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('preparedness_hive_test_');
    Hive.init(hiveDir.path);
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(InstructionGuideAdapter());
    }
    repository = InstructionGuideRepository();
    await repository.initBox();
  });

  tearDown(() async {
    await repository.closeBox();
    await Hive.close();
    await hiveDir.delete(recursive: true);
  });

  InstructionGuide buildGuide({
    required String id,
    required String title,
    required String category,
    bool isRead = false,
  }) {
    return InstructionGuide(
      id: id,
      title: title,
      category: category,
      contentSteps: const [
        'Prepare early.',
        'Review the plan.',
      ],
      imageAssetPaths: const [],
      isRead: isRead,
    );
  }

  test('InstructionGuide serializes through Hive round trip', () async {
    final box = await Hive.openBox<InstructionGuide>('round_trip_box');
    final guide = InstructionGuide(
      id: 'typhoon_01',
      title: 'Before a Typhoon',
      category: 'Typhoon',
      contentSteps: const ['Step one', 'Step two'],
      imageAssetPaths: const ['assets/images/guides/typhoon_01_01.png'],
    );

    await box.put(guide.id, guide);
    final stored = box.get(guide.id);

    expect(stored, isNotNull);
    expect(stored!.id, 'typhoon_01');
    expect(stored.title, 'Before a Typhoon');
    expect(stored.category, 'Typhoon');
    expect(stored.contentSteps, ['Step one', 'Step two']);
    expect(stored.imageAssetPaths, ['assets/images/guides/typhoon_01_01.png']);
    expect(stored.isRead, isFalse);
  });

  test('seedIfNeeded writes only when guide box is empty', () async {
    await repository.seedIfNeeded();
    final seededGuides = repository.getAllGuides();

    expect(seededGuides, isNotEmpty);
    expect(seededGuides.map((guide) => guide.id), contains('typhoon_01'));

    await repository.clearAll();
    final customGuide = buildGuide(
      id: 'custom_01',
      title: 'Custom Guide',
      category: 'Custom',
    );
    await repository.saveGuide(customGuide);

    await repository.seedIfNeeded();
    final guidesAfterSeedAttempt = repository.getAllGuides();

    expect(guidesAfterSeedAttempt, hasLength(1));
    expect(guidesAfterSeedAttempt.single.id, 'custom_01');
  });

  testWidgets('category grid shows categories and unread counts', (tester) async {
    final guides = ValueNotifier<List<InstructionGuide>>([
      buildGuide(
        id: 'typhoon_01',
        title: 'Typhoon Guide',
        category: 'Typhoon',
      ),
      buildGuide(
        id: 'typhoon_02',
        title: 'Typhoon Recovery',
        category: 'Typhoon',
        isRead: true,
      ),
      buildGuide(
        id: 'flood_01',
        title: 'Flood Guide',
        category: 'Flood',
        isRead: true,
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: PreparednessCategoryGridPage(
          repository: repository,
          guidesListenable: guides,
        ),
      ),
    );

    expect(find.text('Typhoon'), findsOneWidget);
    expect(find.text('Flood'), findsOneWidget);
    expect(find.text('2 guides'), findsOneWidget);
    expect(find.text('1 unread'), findsOneWidget);
    expect(find.text('All read'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    guides.dispose();
  });

  testWidgets('guide viewer marks guide as read after final page', (tester) async {
    final guide = buildGuide(
      id: 'viewer_01',
      title: 'Viewer Guide',
      category: 'Test',
    );
    final guides = ValueNotifier<List<InstructionGuide>>([guide]);
    var markedGuideId = '';

    await tester.pumpWidget(
      MaterialApp(
        home: PreparednessGuideViewerPage(
          repository: repository,
          guideId: guide.id,
          guidesListenable: guides,
          onMarkGuideRead: (guideId) async {
            markedGuideId = guideId;
            guides.value = [
              for (final currentGuide in guides.value)
                currentGuide.id == guideId
                    ? currentGuide.copyWith(isRead: true)
                    : currentGuide,
            ];
          },
        ),
      ),
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(markedGuideId, guide.id);
    expect(guides.value.single.isRead, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    guides.dispose();
  });
}
