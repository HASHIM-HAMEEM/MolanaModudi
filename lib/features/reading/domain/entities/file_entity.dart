import 'package:equatable/equatable.dart';

class FileEntity extends Equatable {
  final String id;
  final String bookId;
  final String url;
  final String? mimeType;
  final int? size;
  final String? name;

  const FileEntity({
    required this.id,
    required this.bookId,
    required this.url,
    this.mimeType,
    this.size,
    this.name,
  });

  @override
  List<Object?> get props => [
        id,
        bookId,
        url,
        mimeType,
        size,
        name,
      ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'url': url,
      'mimeType': mimeType,
      'size': size,
      'name': name,
    };
  }

  factory FileEntity.fromMap(Map<String, dynamic> map) {
    return FileEntity(
      id: map['id'] as String,
      bookId: map['bookId'] as String,
      url: map['url'] as String,
      mimeType: map['mimeType'] as String?,
      size: map['size'] as int?,
      name: map['name'] as String?,
    );
  }
}
