// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FlashcardAdapter extends TypeAdapter<Flashcard> {
  @override
  final typeId = 1;

  @override
  Flashcard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Flashcard(
      id: fields[0] as String,
      deckId: fields[1] as String,
      front: fields[2] as String,
      back: fields[3] as String,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      starCount: fields[6] == null ? 0 : (fields[6] as num).toInt(),
      archived: fields[7] == null ? false : fields[7] as bool,
      easeFactor: (fields[8] as num?)?.toDouble(),
      intervalDays: (fields[9] as num?)?.toInt(),
      repetitions: (fields[10] as num?)?.toInt(),
      nextReviewAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Flashcard obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.deckId)
      ..writeByte(2)
      ..write(obj.front)
      ..writeByte(3)
      ..write(obj.back)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.starCount)
      ..writeByte(7)
      ..write(obj.archived)
      ..writeByte(8)
      ..write(obj.easeFactor)
      ..writeByte(9)
      ..write(obj.intervalDays)
      ..writeByte(10)
      ..write(obj.repetitions)
      ..writeByte(11)
      ..write(obj.nextReviewAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlashcardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
