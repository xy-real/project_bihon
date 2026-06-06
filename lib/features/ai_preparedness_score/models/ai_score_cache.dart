import 'package:hive/hive.dart';

part 'ai_score_cache.g.dart';

@HiveType(typeId: 6)
class AIScoreCache extends HiveObject {
  static const String boxName = 'ai_score_box';
  static const String latestScoreKey = 'latest_score';

  @HiveField(0)
  final int overallScore;

  @HiveField(1)
  final String status;

  @HiveField(2)
  final List<String> missingEssentialItems;

  @HiveField(3)
  final String customAdvice;

  @HiveField(4)
  final DateTime calculatedAt;

  AIScoreCache({
    required this.overallScore,
    required this.status,
    required this.missingEssentialItems,
    required this.customAdvice,
    required this.calculatedAt,
  });
}
