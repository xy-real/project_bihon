import 'package:hive/hive.dart';

part 'alert_sync_state.g.dart';

@HiveType(typeId: 7)
class AlertSyncState extends HiveObject {
  static const String boxName = 'sync_state_box';

  @HiveField(0)
  final DateTime? lastSuccessfulSyncAt;

  @HiveField(1)
  final DateTime? lastAttemptedSyncAt;

  @HiveField(2)
  final String? lastError;

  @HiveField(3)
  final int lastSyncedCount;

  AlertSyncState({
    this.lastSuccessfulSyncAt,
    this.lastAttemptedSyncAt,
    this.lastError,
    required this.lastSyncedCount,
  });
}
