// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_sync_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlertSyncStateAdapter extends TypeAdapter<AlertSyncState> {
  @override
  final int typeId = 7;

  @override
  AlertSyncState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlertSyncState(
      lastSuccessfulSyncAt: fields[0] as DateTime?,
      lastAttemptedSyncAt: fields[1] as DateTime?,
      lastError: fields[2] as String?,
      lastSyncedCount: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AlertSyncState obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.lastSuccessfulSyncAt)
      ..writeByte(1)
      ..write(obj.lastAttemptedSyncAt)
      ..writeByte(2)
      ..write(obj.lastError)
      ..writeByte(3)
      ..write(obj.lastSyncedCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertSyncStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
