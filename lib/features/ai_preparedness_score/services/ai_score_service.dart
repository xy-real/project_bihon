import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:project_bihon/features/ai_preparedness_score/data/repositories/ai_score_repository.dart';
import 'package:project_bihon/features/ai_preparedness_score/models/ai_score_cache.dart';
import 'package:project_bihon/features/ai_preparedness_score/services/ai_score_prompt_builder.dart';
import 'package:project_bihon/features/household/data/repositories/household_repository.dart';
import 'package:project_bihon/features/supply_tracker/data/repositories/supply_repository.dart';

enum AIScoreCalculationStatus {
  success,
  offline,
  configurationError,
  failed,
}

class AIScoreCalculationResult {
  final AIScoreCalculationStatus status;
  final AIScoreCache? score;
  final String message;

  const AIScoreCalculationResult._({
    required this.status,
    required this.score,
    required this.message,
  });

  bool get isSuccess => status == AIScoreCalculationStatus.success;

  factory AIScoreCalculationResult.success(AIScoreCache score) {
    return AIScoreCalculationResult._(
      status: AIScoreCalculationStatus.success,
      score: score,
      message: 'Preparedness score updated.',
    );
  }

  factory AIScoreCalculationResult.offline({
    required AIScoreCache? cachedScore,
  }) {
    return AIScoreCalculationResult._(
      status: AIScoreCalculationStatus.offline,
      score: cachedScore,
      message: cachedScore == null
          ? 'No internet connection. Connect to the internet to calculate your score.'
          : 'No internet connection.${_cachedScoreMessage(cachedScore)}',
    );
  }

  factory AIScoreCalculationResult.configurationError({
    required AIScoreCache? cachedScore,
  }) {
    return AIScoreCalculationResult._(
      status: AIScoreCalculationStatus.configurationError,
      score: cachedScore,
      message:
          'Gemini API key is not configured.'
          '${_cachedScoreMessage(cachedScore)}',
    );
  }

  factory AIScoreCalculationResult.failed({
    required AIScoreCache? cachedScore,
    String message = 'Unable to refresh the preparedness score right now.',
  }) {
    return AIScoreCalculationResult._(
      status: AIScoreCalculationStatus.failed,
      score: cachedScore,
      message: '$message${_cachedScoreMessage(cachedScore)}',
    );
  }
}

abstract interface class AIScoreConnectivity {
  Future<bool> hasInternetAccess();
}

class DnsAIScoreConnectivity implements AIScoreConnectivity {
  static const Duration _timeout = Duration(seconds: 5);

  @override
  Future<bool> hasInternetAccess() async {
    try {
      final addresses = await InternetAddress.lookup(
        'generativelanguage.googleapis.com',
      ).timeout(_timeout);
      return addresses.isNotEmpty && addresses.any((address) {
        return address.rawAddress.isNotEmpty;
      });
    } on Object {
      return false;
    }
  }
}

abstract interface class AIScoreGenerator {
  Future<String?> generate(String prompt);
}

class GeminiAIScoreGenerator implements AIScoreGenerator {
  final GenerativeModel _model;

  GeminiAIScoreGenerator({
    required String apiKey,
    required String modelName,
  }) : _model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );

  @override
  Future<String?> generate(String prompt) async {
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text;
  }
}

class AIScoreService {
  static const String defaultModelName = 'gemini-2.5-flash';

  final HouseholdRepository _householdRepository;
  final SupplyRepository _supplyRepository;
  final AIScoreRepository _scoreRepository;
  final AIScoreConnectivity _connectivity;
  final AIScoreGenerator? _generator;
  final String _apiKey;
  final String _modelName;
  final DateTime Function() _now;

  AIScoreService({
    required HouseholdRepository householdRepository,
    required SupplyRepository supplyRepository,
    required AIScoreRepository scoreRepository,
    AIScoreConnectivity? connectivity,
    AIScoreGenerator? generator,
    String apiKey = const String.fromEnvironment('GEMINI_API_KEY'),
    String modelName = const String.fromEnvironment(
      'GEMINI_MODEL',
      defaultValue: defaultModelName,
    ),
    DateTime Function()? now,
  })  : _householdRepository = householdRepository,
        _supplyRepository = supplyRepository,
        _scoreRepository = scoreRepository,
        _connectivity = connectivity ?? DnsAIScoreConnectivity(),
        _generator = generator,
        _apiKey = apiKey,
        _modelName = modelName,
        _now = now ?? DateTime.now;

  Future<AIScoreCalculationResult> recalculate() async {
    final cachedScore = _scoreRepository.getLatestScore();
    final hasApiConfiguration =
        _generator != null || _apiKey.trim().isNotEmpty;

    debugPrint('[AIScoreService] Recalculation started.');
    debugPrint(
      '[AIScoreService] Gemini API key configured: $hasApiConfiguration.',
    );

    bool isOnline;
    try {
      isOnline = await _connectivity.hasInternetAccess();
    } on Object catch (error) {
      debugPrint('[AIScoreService] Connectivity check failed: $error');
      isOnline = false;
    }

    if (!isOnline) {
      debugPrint('[AIScoreService] Offline; recalculation blocked.');
      return AIScoreCalculationResult.offline(cachedScore: cachedScore);
    }

    if (!hasApiConfiguration) {
      debugPrint('[AIScoreService] Missing Gemini API configuration.');
      return AIScoreCalculationResult.configurationError(
        cachedScore: cachedScore,
      );
    }

    try {
      final household = await _householdRepository.getOrCreateHousehold();
      final supplies = _supplyRepository.getItemsForHousehold(household.id);
      final validSupplies =
          supplies.where((item) => !item.isExpired).toList(growable: false);
      final categories = validSupplies
          .map((item) => item.category.trim())
          .where((category) => category.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      debugPrint(
        '[AIScoreService] Loaded ${supplies.length} supplies; '
        '${validSupplies.length} unexpired included. '
        'Risk: ${household.risk_classification}. '
        'Categories: ${categories.join(', ')}.',
      );

      final prompt = buildSanitizedPrompt(household, supplies);
      final generator = _generator ??
          GeminiAIScoreGenerator(
            apiKey: _apiKey,
            modelName: _modelName,
          );
      final responseText = await generator.generate(prompt);
      debugPrint('[AIScoreService] Gemini response received.');

      if (responseText == null || responseText.trim().isEmpty) {
        throw const FormatException('Gemini returned an empty response.');
      }

      final score = parseResponse(
        responseText,
        calculatedAt: _now().toUtc(),
      );
      await _scoreRepository.saveScore(score);
      debugPrint(
        '[AIScoreService] Score ${score.overallScore} saved to '
        '${AIScoreCache.boxName}/${AIScoreCache.latestScoreKey}.',
      );
      return AIScoreCalculationResult.success(score);
    } on FormatException catch (error) {
      debugPrint('[AIScoreService] Invalid Gemini response: $error');
      return AIScoreCalculationResult.failed(
        cachedScore: cachedScore,
        message:
            'Gemini returned an invalid score response. Please try again.',
      );
    } on Object catch (error) {
      debugPrint('[AIScoreService] Recalculation failed: $error');
      return AIScoreCalculationResult.failed(
        cachedScore: cachedScore,
        message: _geminiFailureMessage(error),
      );
    }
  }

  @visibleForTesting
  static AIScoreCache parseResponse(
    String responseText, {
    required DateTime calculatedAt,
  }) {
    final decoded = jsonDecode(_stripCodeFence(responseText));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Response must be a JSON object.');
    }

    final score = _parseScore(decoded['score']);
    final status = _requiredString(decoded, 'status');
    final advice = _requiredString(decoded, 'advice');
    final missingItemsValue = decoded['missing_items'];
    if (missingItemsValue is! List ||
        missingItemsValue.any((item) => item is! String)) {
      throw const FormatException(
        'missing_items must be an array of strings.',
      );
    }

    return AIScoreCache(
      overallScore: score,
      status: status,
      missingEssentialItems: missingItemsValue
          .cast<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      customAdvice: advice,
      calculatedAt: calculatedAt,
    );
  }
}

int _parseScore(Object? value) {
  if (value is! int) {
    throw const FormatException('score must be an integer.');
  }

  if (value < 0 || value > 100) {
    throw const FormatException('score must be between 0 and 100.');
  }
  return value;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value.trim();
}

String _stripCodeFence(String responseText) {
  final trimmed = responseText.trim();
  if (!trimmed.startsWith('```')) {
    return trimmed;
  }

  final firstLineEnd = trimmed.indexOf('\n');
  final lastFenceStart = trimmed.lastIndexOf('```');
  if (firstLineEnd == -1 || lastFenceStart <= firstLineEnd) {
    return trimmed;
  }
  return trimmed.substring(firstLineEnd + 1, lastFenceStart).trim();
}

String _cachedScoreMessage(AIScoreCache? cachedScore) {
  if (cachedScore == null) {
    return ' No cached score is available.';
  }

  final cachedDate =
      cachedScore.calculatedAt.toLocal().toIso8601String().split('T').first;
  return ' Showing your cached score from $cachedDate.';
}

String _geminiFailureMessage(Object error) {
  final normalized = error.toString().toLowerCase();
  if (normalized.contains('api key not valid') ||
      normalized.contains('invalid api key')) {
    return 'The Gemini API key is invalid. Generate a new key, restart the app with GEMINI_API_KEY, and try again.';
  }
  if (normalized.contains('quota') ||
      normalized.contains('resource exhausted')) {
    return 'The Gemini API quota has been reached. Check the project quota and try again later.';
  }
  if (normalized.contains('model') &&
      (normalized.contains('not found') ||
          normalized.contains('not supported'))) {
    return 'The configured Gemini model is unavailable. Check GEMINI_MODEL and try again.';
  }
  return 'Gemini could not calculate a score. Check the API key, model access, and quota, then try again.';
}
