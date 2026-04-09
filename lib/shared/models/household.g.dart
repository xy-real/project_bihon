// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HouseholdAdapter extends TypeAdapter<Household> {
  @override
  final int typeId = 4;

  @override
  Household read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Household(
      id: fields[0] as String,
      risk_classification: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Household obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.risk_classification);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HouseholdAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
