import 'package:equatable/equatable.dart';

class PlaylistEntity extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl; // Optional: Could fetch first video's thumbnail
  final int videoCount;

  const PlaylistEntity({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.videoCount,
  });

  @override
  List<Object?> get props => [id, title, description, thumbnailUrl, videoCount];
} 