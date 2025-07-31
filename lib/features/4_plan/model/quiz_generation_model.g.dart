// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_generation_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GeneratedQuizAdapter extends TypeAdapter<GeneratedQuiz> {
  @override
  final int typeId = 2;

  @override
  GeneratedQuiz read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GeneratedQuiz(
      question: fields[0] as String,
      options: (fields[1] as List).cast<String>(),
      correctOptionIndex: fields[2] as int,
      explanation: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, GeneratedQuiz obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.question)
      ..writeByte(1)
      ..write(obj.options)
      ..writeByte(2)
      ..write(obj.correctOptionIndex)
      ..writeByte(3)
      ..write(obj.explanation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeneratedQuizAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
