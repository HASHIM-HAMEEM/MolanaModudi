// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_pin_operation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingPinOperationAdapter extends TypeAdapter<PendingPinOperation> {
  @override
  final int typeId = 102;

  @override
  PendingPinOperation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingPinOperation(
      operationType: fields[1] as PinOperationType,
      itemKey: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PendingPinOperation obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.operationType)
      ..writeByte(2)
      ..write(obj.itemKey)
      ..writeByte(3)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingPinOperationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PinOperationTypeAdapter extends TypeAdapter<PinOperationType> {
  @override
  final int typeId = 101;

  @override
  PinOperationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PinOperationType.pin;
      case 1:
        return PinOperationType.unpin;
      default:
        return PinOperationType.pin;
    }
  }

  @override
  void write(BinaryWriter writer, PinOperationType obj) {
    switch (obj) {
      case PinOperationType.pin:
        writer.writeByte(0);
        break;
      case PinOperationType.unpin:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PinOperationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
