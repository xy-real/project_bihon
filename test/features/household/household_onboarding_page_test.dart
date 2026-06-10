import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:project_bihon/features/household/data/repositories/household_repository.dart';
import 'package:project_bihon/shared/models/household.dart';

void main() {
  late Directory hiveDir;
  late HouseholdRepository repository;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('household_onboarding_');
    Hive.init(hiveDir.path);
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(HouseholdAdapter());
    }
    repository = HouseholdRepository();
    await repository.initBox();
  });

  tearDown(() async {
    await Hive.close();
    await hiveDir.delete(recursive: true);
  });

  test('first launch is detected when onboarding flag is missing', () {
    expect(repository.hasCompletedOnboarding(), isFalse);
  });

  test('continue flow persists selected risk and completion flag', () async {
    await repository.updateRiskClassification('coastal');
    await repository.setOnboardingCompleted();

    expect(repository.getRiskClassification(), equals('coastal'));
    expect(repository.hasCompletedOnboarding(), isTrue);
  });

  test('mountainous onboarding category maps to landslide-prone risk',
      () async {
    await repository.updateRiskClassification('landslide_prone');
    await repository.setOnboardingCompleted();

    expect(repository.getRiskClassification(), equals('landslide_prone'));
    expect(repository.hasCompletedOnboarding(), isTrue);
  });

  test('skip flow persists unknown risk and completion flag', () async {
    await repository.updateRiskClassification('unknown');
    await repository.setOnboardingCompleted();

    expect(repository.getRiskClassification(), equals('unknown'));
    expect(repository.hasCompletedOnboarding(), isTrue);
  });

  test('completed onboarding flag survives repository re-instantiation',
      () async {
    await repository.setOnboardingCompleted();

    final secondRepository = HouseholdRepository();
    await secondRepository.initBox();

    expect(secondRepository.hasCompletedOnboarding(), isTrue);
  });
}
