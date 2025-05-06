import 'package:equatable/equatable.dart';

/// Entity representing a single event in the biography timeline.
class BiographyEventEntity extends Equatable {
  final String date; // e.g., "1903", "1941-1947", "Sep 22, 1979"
  final String title; // Short title for the event
  final String description; // Detailed description of the event

  const BiographyEventEntity({
    required this.date,
    required this.title,
    required this.description,
  });

  @override
  List<Object?> get props => [date, title, description];
} 