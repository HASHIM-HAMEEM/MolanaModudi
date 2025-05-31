import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'pending_pin_operation.g.dart'; // For Hive TypeAdapter generation

@HiveType(typeId: 101) // Ensure this typeId is unique across your Hive models
enum PinOperationType {
  @HiveField(0)
  pin,
  @HiveField(1)
  unpin,
}

@HiveType(typeId: 102) // Ensure this typeId is unique
class PendingPinOperation extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final PinOperationType operationType;

  @HiveField(2)
  final String itemKey; // The key of the item (e.g., 'book_123')

  @HiveField(3)
  final int timestamp;

  PendingPinOperation({
    required this.operationType,
    required this.itemKey,
  })  : id = const Uuid().v4(),
        timestamp = DateTime.now().millisecondsSinceEpoch;

  // For potential manual serialization if not directly storing HiveObject, or for debugging
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operationType': operationType.name, // Storing enum as string
      'itemKey': itemKey,
      'timestamp': timestamp,
    };
  }

  factory PendingPinOperation.fromMap(Map<String, dynamic> map) {
    final operation = PendingPinOperation(
      operationType: PinOperationType.values.firstWhere((e) => e.name == map['operationType']),
      itemKey: map['itemKey'] as String,
    );
    // Note: 'id' and 'timestamp' are set in constructor, but if map contains them, you might want to use them.
    // For this factory, we are assuming it's for creating a new object from a map representation
    // that might not have 'id' or 'timestamp' if they were auto-generated.
    // If you are re-hydrating an existing object, ensure 'id' and 'timestamp' from map are used.
    return operation; // Simplified, assuming id and timestamp are always new or handled by HiveObject
  }

  @override
  String toString() {
    return 'PendingPinOperation(id: $id, type: $operationType, key: $itemKey, timestamp: $timestamp)';
  }
}
