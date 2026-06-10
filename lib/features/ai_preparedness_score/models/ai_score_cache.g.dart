// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_score_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AIScoreCacheAdapter extends TypeAdapter<AIScoreCache> {
  @override
  final int typeId = 6;

  @override
  AIScoreCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AIScoreCache(
      overallScore: fields[0] as int,
      status: fields[1] as String,
      missingEssentialItems: (fields[2] as List).cast<String>(),
      customAdvice: fields[3] as String,
      calculatedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AIScoreCache obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.overallScore)
      ..writeByte(1)
      ..write(obj.status)
      ..writeByte(2)
      ..write(obj.missingEssentialItems)
      ..writeByte(3)
      ..write(obj.customAdvice)
      ..writeByte(4)
      ..write(obj.calculatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIScoreCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
