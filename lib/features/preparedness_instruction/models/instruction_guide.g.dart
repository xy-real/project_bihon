// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'instruction_guide.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InstructionGuideAdapter extends TypeAdapter<InstructionGuide> {
  @override
  final int typeId = 5;

  @override
  InstructionGuide read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InstructionGuide(
      id: fields[0] as String,
      title: fields[1] as String,
      category: fields[2] as String,
      contentSteps: (fields[3] as List).cast<String>(),
      imageAssetPaths: (fields[4] as List).cast<String>(),
      isRead: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, InstructionGuide obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.contentSteps)
      ..writeByte(4)
      ..write(obj.imageAssetPaths)
      ..writeByte(5)
      ..write(obj.isRead);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstructionGuideAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
