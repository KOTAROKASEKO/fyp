// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StreakDataAdapter extends TypeAdapter<StreakData> {
  @override
  final int typeId = 0;

  @override
  StreakData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StreakData(
      currentStreak: fields[0] as int,
      lastStreakDate: fields[1] as DateTime?,
      totalPoints: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, StreakData obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.currentStreak)
      ..writeByte(1)
      ..write(obj.lastStreakDate)
      ..writeByte(2)
      ..write(obj.totalPoints);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
