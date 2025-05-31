import '../../domain/entities/biography_event_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'biography_event_model.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.none)
class BiographyEventModel extends BiographyEventEntity {
  // Explicitly declare fields again for json_serializable, even though they exist in superclass
  @override
  final String date;
  @override
  final String title;
  @override
  final String description;

  const BiographyEventModel({
    required this.date,
    required this.title,
    required this.description,
  }) : super(date: date, title: title, description: description);

  factory BiographyEventModel.fromJson(Map<String, dynamic> json) =>
      _$BiographyEventModelFromJson(json);

  Map<String, dynamic> toJson() => _$BiographyEventModelToJson(this);
} 