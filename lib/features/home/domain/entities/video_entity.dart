import 'package:equatable/equatable.dart';

/// Represents core data for a video lecture.
class VideoEntity extends Equatable {
  final String id;
  final String title;
  final String? thumbnailUrl;
  final String? duration; // e.g., "12:45"
  final String? source; // e.g., "YouTube", "Archive.org"
  final String? url; // Direct URL to the video

  const VideoEntity({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    this.duration,
    this.source,
    this.url,
  });

  @override
  List<Object?> get props => [id, title, thumbnailUrl, duration, source, url];
}
