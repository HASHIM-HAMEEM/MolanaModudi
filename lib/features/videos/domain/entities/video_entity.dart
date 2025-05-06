import 'package:equatable/equatable.dart';

class VideoEntity extends Equatable {
  final String id; // YouTube video ID
  final String title;
  final String? description;
  final String thumbnailUrl;
  final String youtubeUrl;
  final String? publishedAt;
  final String? channelTitle;
  final String? duration;
  final String? viewCount;

  const VideoEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.youtubeUrl,
    this.publishedAt,
    this.channelTitle,
    this.duration,
    this.viewCount,
  });

  @override
  List<Object?> get props => [id, title, description, thumbnailUrl, youtubeUrl, publishedAt, channelTitle, duration, viewCount];
} 