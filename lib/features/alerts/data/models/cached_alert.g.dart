// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_alert.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedAlertAdapter extends TypeAdapter<CachedAlert> {
  @override
  final int typeId = 2;

  @override
  CachedAlert read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedAlert(
      id: fields[0] as String,
      title: fields[1] as String,
      severity: fields[2] as String,
      source: fields[3] as String,
      advisoryType: fields[4] as String,
      content: fields[5] as String,
      publishedAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
      expiresAt: fields[8] as DateTime?,
      isActive: fields[9] as bool,
      riskTags: (fields[10] as List?)?.cast<String>(),
      region: fields[11] as String?,
      affectedAreas: (fields[12] as List?)?.cast<String>(),
      latitude: fields[13] as double?,
      longitude: fields[14] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, CachedAlert obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.severity)
      ..writeByte(3)
      ..write(obj.source)
      ..writeByte(4)
      ..write(obj.advisoryType)
      ..writeByte(5)
      ..write(obj.content)
      ..writeByte(6)
      ..write(obj.publishedAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.expiresAt)
      ..writeByte(9)
      ..write(obj.isActive)
      ..writeByte(10)
      ..write(obj.riskTags)
      ..writeByte(11)
      ..write(obj.region)
      ..writeByte(12)
      ..write(obj.affectedAreas)
      ..writeByte(13)
      ..write(obj.latitude)
      ..writeByte(14)
      ..write(obj.longitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedAlertAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
