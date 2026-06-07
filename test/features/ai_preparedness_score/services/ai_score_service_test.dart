import 'package:flutter_test/flutter_test.dart';
import 'package:project_bihon/features/ai_preparedness_score/data/repositories/ai_score_repository.dart';
import 'package:project_bihon/features/ai_preparedness_score/models/ai_score_cache.dart';
import 'package:project_bihon/features/ai_preparedness_score/services/ai_score_service.dart';
import 'package:project_bihon/features/household/data/repositories/household_repository.dart';
import 'package:project_bihon/features/supply_tracker/data/models/supply_item.dart';
import 'package:project_bihon/features/supply_tracker/data/repositories/supply_repository.dart';
import 'package:project_bihon/shared/models/household.dart';

void main() {
  final calculatedAt = DateTime.utc(2026, 6, 6, 12);
  late _FakeHouseholdRepository householdRepository;
  late _FakeSupplyRepository supplyRepository;
  late _InMemoryAIScoreRepository scoreRepository;
  late _FakeConnectivity connectivity;
  late _FakeGenerator generator;

  setUp(() {
    householdRepository = _FakeHouseholdRepository(
      Household(
        id: HouseholdRepository.defaultHouseholdId,
        risk_classification: 'coastal',
      ),
    );
    supplyRepository = _FakeSupplyRepository([
      SupplyItem(
        id: 'water',
        name: 'Bottled Water',
        category: 'Water',
        quantity: 6,
        expirationDate: DateTime.utc(2027),
      ),
    ]);
    scoreRepository = _InMemoryAIScoreRepository();
    connectivity = _FakeConnectivity(isOnline: true);
    generator = _FakeGenerator(
      response: '''
{
  "score": 82,
  "status": "Prepared",
  "missing_items": ["First aid kit", "Radio"],
  "advice": "Add medical and communication supplies."
}''',
    );
  });

  AIScoreService buildService({
    AIScoreGenerator? scoreGenerator,
    String apiKey = 'test-api-key',
  }) {
    return AIScoreService(
      householdRepository: householdRepository,
      supplyRepository: supplyRepository,
      scoreRepository: scoreRepository,
      connectivity: connectivity,
      generator: scoreGenerator ?? generator,
      apiKey: apiKey,
      now: () => calculatedAt,
    );
  }

  test('parses valid Gemini JSON and saves the score', () async {
    final result = await buildService().recalculate();

    expect(result.isSuccess, isTrue);
    expect(result.score?.overallScore, 82);
    expect(result.score?.status, 'Prepared');
    expect(result.score?.missingEssentialItems, ['First aid kit', 'Radio']);
    expect(
      result.score?.customAdvice,
      'Add medical and communication supplies.',
    );
    expect(result.score?.calculatedAt, calculatedAt);
    expect(scoreRepository.savedScore, same(result.score));
    expect(generator.lastPrompt, contains('6x Bottled Water (Water)'));
  });

  test('loads newly added supplies when recalculation starts', () async {
    final service = buildService();
    supplyRepository.items.add(
      SupplyItem(
        id: 'first-aid',
        name: 'First Aid Kit',
        category: 'Medical',
        quantity: 2,
        expirationDate: DateTime.utc(2027),
      ),
    );
    supplyRepository.items.add(
      SupplyItem(
        id: 'expired-food',
        name: 'Expired Food',
        category: 'Food',
        quantity: 4,
        expirationDate: DateTime.utc(2020),
      ),
    );

    final result = await service.recalculate();

    expect(result.isSuccess, isTrue);
    expect(generator.lastPrompt, contains('2x First Aid Kit (Medical)'));
    expect(generator.lastPrompt, isNot(contains('Expired Food')));
    expect(scoreRepository.saveCalls, 1);
  });

  test('rejects invalid JSON without replacing a cached score', () async {
    final cached = _cachedScore();
    scoreRepository.savedScore = cached;
    generator.response = 'not-json';

    final result = await buildService().recalculate();

    expect(result.status, AIScoreCalculationStatus.failed);
    expect(result.score, same(cached));
    expect(scoreRepository.savedScore, same(cached));
    expect(scoreRepository.saveCalls, 0);
  });

  test('rejects out-of-range and non-integer scores', () {
    for (final invalidScore in [-1, 101, 42.0, 42.5, '"82"']) {
      expect(
        () => AIScoreService.parseResponse(
          '''
{
  "score": $invalidScore,
  "status": "Prepared",
  "missing_items": [],
  "advice": "Keep supplies current."
}''',
          calculatedAt: calculatedAt,
        ),
        throwsFormatException,
      );
    }
  });

  test(
    'offline result does not call Gemini and preserves cached score',
    () async {
      final cached = _cachedScore();
      scoreRepository.savedScore = cached;
      connectivity.isOnline = false;

      final result = await buildService().recalculate();

      expect(result.status, AIScoreCalculationStatus.offline);
      expect(result.score, same(cached));
      expect(
        result.message,
        'No internet connection. Showing your cached score from 2026-06-01.',
      );
      expect(generator.callCount, 0);
      expect(scoreRepository.saveCalls, 0);
    },
  );

  test('offline without cache asks the user to connect', () async {
    connectivity.isOnline = false;

    final result = await buildService().recalculate();

    expect(result.status, AIScoreCalculationStatus.offline);
    expect(result.score, isNull);
    expect(
      result.message,
      'No internet connection. Connect to the internet to calculate your score.',
    );
    expect(generator.callCount, 0);
  });

  test('accepts JSON returned inside a Markdown code fence', () {
    final score = AIScoreService.parseResponse(
      '''
```json
{
  "score": 74,
  "status": "Prepared",
  "missing_items": [],
  "advice": "Rotate stored water regularly."
}
```''',
      calculatedAt: calculatedAt,
    );

    expect(score.overallScore, 74);
    expect(score.customAdvice, 'Rotate stored water regularly.');
  });

  test('rejects missing required response fields safely', () {
    expect(
      () => AIScoreService.parseResponse(
        '{"score": 80, "status": "Prepared"}',
        calculatedAt: calculatedAt,
      ),
      throwsFormatException,
    );
  });

  test('missing API key returns a controlled configuration error', () async {
    final service = AIScoreService(
      householdRepository: householdRepository,
      supplyRepository: supplyRepository,
      scoreRepository: scoreRepository,
      connectivity: connectivity,
      apiKey: '',
      now: () => calculatedAt,
    );

    final result = await service.recalculate();

    expect(result.status, AIScoreCalculationStatus.configurationError);
    expect(result.message, contains('Gemini API key is not configured.'));
    expect(scoreRepository.saveCalls, 0);
  });

  test('API failure keeps the previous cached score', () async {
    final cached = _cachedScore();
    scoreRepository.savedScore = cached;
    generator.error = StateError('API unavailable');

    final result = await buildService().recalculate();

    expect(result.status, AIScoreCalculationStatus.failed);
    expect(result.score, same(cached));
    expect(scoreRepository.savedScore, same(cached));
    expect(scoreRepository.saveCalls, 0);
  });

  test('invalid API key returns a clear controlled error', () async {
    generator.error = StateError(
      'API key not valid. Please pass a valid API key.',
    );

    final result = await buildService().recalculate();

    expect(result.status, AIScoreCalculationStatus.failed);
    expect(
      result.message,
      contains('The Gemini API key is invalid.'),
    );
    expect(scoreRepository.saveCalls, 0);
  });
}

AIScoreCache _cachedScore() {
  return AIScoreCache(
    overallScore: 65,
    status: 'Needs Improvement',
    missingEssentialItems: const ['Radio'],
    customAdvice: 'Add a battery-powered radio.',
    calculatedAt: DateTime.utc(2026, 6),
  );
}

class _FakeHouseholdRepository extends HouseholdRepository {
  final Household household;

  _FakeHouseholdRepository(this.household);

  @override
  Future<Household> getOrCreateHousehold() async => household;
}

class _FakeSupplyRepository extends SupplyRepository {
  final List<SupplyItem> items;

  _FakeSupplyRepository(this.items);

  @override
  List<SupplyItem> getItemsForHousehold(String householdId) {
    return items
        .where((item) => item.householdId == householdId)
        .toList(growable: false);
  }
}

class _InMemoryAIScoreRepository extends AIScoreRepository {
  AIScoreCache? savedScore;
  int saveCalls = 0;

  @override
  AIScoreCache? getLatestScore() => savedScore;

  @override
  Future<void> saveScore(AIScoreCache score) async {
    saveCalls++;
    savedScore = score;
  }
}

class _FakeConnectivity implements AIScoreConnectivity {
  bool isOnline;

  _FakeConnectivity({required this.isOnline});

  @override
  Future<bool> hasInternetAccess() async => isOnline;
}

class _FakeGenerator implements AIScoreGenerator {
  String? response;
  Object? error;
  int callCount = 0;
  String? lastPrompt;

  _FakeGenerator({this.response});

  @override
  Future<String?> generate(String prompt) async {
    callCount++;
    lastPrompt = prompt;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return response;
  }
}
