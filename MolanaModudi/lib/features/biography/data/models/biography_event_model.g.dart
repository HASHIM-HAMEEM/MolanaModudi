// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'biography_event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BiographyEventModel _$BiographyEventModelFromJson(Map<String, dynamic> json) =>
    BiographyEventModel(
      date: json['date'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
    );

Map<String, dynamic> _$BiographyEventModelToJson(
        BiographyEventModel instance) =>
    <String, dynamic>{
      'date': instance.date,
      'title': instance.title,
      'description': instance.description,
    };
