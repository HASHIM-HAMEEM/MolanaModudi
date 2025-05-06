import '../../domain/entities/video_entity.dart';

/// Model implementation of VideoEntity
class VideoModel extends VideoEntity {
  const VideoModel({
    required String id,
    required String title,
    String? thumbnailUrl,
    String? duration,
    String? source,
    String? url,
  }) : super(
         id: id,
         title: title,
         thumbnailUrl: thumbnailUrl,
         duration: duration,
         source: source,
         url: url,
       );
  
  // Factory constructor to parse data from API
  factory VideoModel.fromJson(Map<String, dynamic> json) {
    final String identifier = json['identifier'] as String? ?? '';
    final String title = json['title'] as String? ?? '';
    
    // Generate thumbnail URL if identifier is available
    String? thumbnailUrl;
    if (identifier.isNotEmpty) {
      thumbnailUrl = 'https://archive.org/services/get-item-image.php?identifier=$identifier';
    }
    
    // Default values for missing fields
    const String defaultDuration = 'Unknown';
    const String defaultSource = 'Archive.org';
    
    // Generate direct URL to the video on Archive.org
    String url = 'https://archive.org/details/$identifier';
    
    return VideoModel(
      id: identifier,
      title: title,
      thumbnailUrl: thumbnailUrl,
      duration: json['runtime'] as String? ?? defaultDuration,
      source: defaultSource,
      url: url,
    );
  }
  
  // Convert to JSON representation if needed
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'source': source,
      'url': url,
    };
  }
}
