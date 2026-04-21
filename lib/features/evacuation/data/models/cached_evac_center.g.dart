// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_evac_center.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedEvacCenterAdapter extends TypeAdapter<CachedEvacCenter> {
  @override
  final int typeId = 4;

  @override
  CachedEvacCenter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedEvacCenter(
      id: fields[0] as String,
      name: fields[1] as String,
      latitude: fields[2] as double,
      longitude: fields[3] as double,
      capacity: fields[4] as int,
      status: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CachedEvacCenter obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.latitude)
      ..writeByte(3)
      ..write(obj.longitude)
      ..writeByte(4)
      ..write(obj.capacity)
      ..writeByte(5)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedEvacCenterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
