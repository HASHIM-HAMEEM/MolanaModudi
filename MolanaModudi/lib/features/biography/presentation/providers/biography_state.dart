import 'package:equatable/equatable.dart';
import '../../domain/entities/biography_event_entity.dart';

enum BiographyStatus { initial, loading, success, error }

class BiographyState extends Equatable {
  final BiographyStatus status;
  final List<BiographyEventEntity> events;
  final String? errorMessage;

  const BiographyState({
    this.status = BiographyStatus.initial,
    this.events = const [],
    this.errorMessage,
  });

  BiographyState copyWith({
    BiographyStatus? status,
    List<BiographyEventEntity>? events,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BiographyState(
      status: status ?? this.status,
      events: events ?? this.events,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, events, errorMessage];
} 