// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_metadata.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CacheMetadataAdapter extends TypeAdapter<CacheMetadata> {
  @override
  final int typeId = 0;

  @override
  CacheMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CacheMetadata(
      originalKey: fields[0] as String,
      boxName: fields[1] as String,
      timestamp: fields[2] as int,
      ttlMillis: fields[3] as int?,
      dataSizeBytes: fields[4] as int?,
      language: fields[5] as String?,
      direction: fields[6] as String?,
      source: fields[7] as String?,
      hash: fields[8] as String?,
      accessCount: fields[9] as int,
      lastAccessTimestamp: fields[10] as int?,
      properties: (fields[11] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, CacheMetadata obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.originalKey)
      ..writeByte(1)
      ..write(obj.boxName)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.ttlMillis)
      ..writeByte(4)
      ..write(obj.dataSizeBytes)
      ..writeByte(5)
      ..write(obj.language)
      ..writeByte(6)
      ..write(obj.direction)
      ..writeByte(7)
      ..write(obj.source)
      ..writeByte(8)
      ..write(obj.hash)
      ..writeByte(9)
      ..write(obj.accessCount)
      ..writeByte(10)
      ..write(obj.lastAccessTimestamp)
      ..writeByte(11)
      ..write(obj.properties);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CacheMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
