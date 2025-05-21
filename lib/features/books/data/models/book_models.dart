import 'package:collection/collection.dart'; // For DeepCollectionEquality
import 'package:flutter/foundation.dart'; // Add foundation.dart import
// We might need Firestore types if fromFirestore is used, but fromMap is primary here.
// import 'package:cloud_firestore/cloud_firestore.dart'; 

class Heading {
  final String firestoreDocId; // Document ID of this heading in Firestore
  final int? id; // Original numeric ID from JSON
  final int? chapterId;
  final int? volumeId;
  final int? bookId; // Original numeric book_id from JSON heading item
  final String? title;
  final List<String>? content; // Array of strings
  final List<String>? tags;
  final String? status;
  final int sequence; // Already present, ensure it's not nullable if always there
  final String? createdAt;
  final String? updatedAt;
  final dynamic audioId; // Could be int or String, keep as dynamic or make specific
  final List<dynamic>? translations; // Assuming list of complex objects or strings
  final dynamic audio; // Could be a URL string or a map
  final Map<String, dynamic> additionalFields;

  Heading({
    required this.firestoreDocId,
    this.id,
    this.chapterId,
    this.volumeId,
    this.bookId,
    this.title,
    this.content,
    this.tags,
    this.status,
    required this.sequence,
    this.createdAt,
    this.updatedAt,
    this.audioId,
    this.translations,
    this.audio,
    Map<String, dynamic>? additionalFields,
  }) : additionalFields = additionalFields ?? {};

  // Factory constructor to create a Heading from a Firestore DocumentSnapshot
  factory Heading.fromMap(String docId, Map<String, dynamic> map) {
    // Helper to safely cast list elements
    List<T>? safelyCastList<T>(dynamic list) {
      if (list is List) {
        return list.whereType<T>().toList();
      }
      return null;
    }

    return Heading(
      firestoreDocId: docId,
      id: map['id'] as int?,
      chapterId: map['chapter_id'] as int?,
      volumeId: map['volume_id'] as int?,
      bookId: map['book_id'] as int?,
      title: map['title'] as String?,
      content: safelyCastList<String>(map['content']),
      tags: safelyCastList<String>(map['tags']),
      status: map['status'] as String?,
      sequence: map['sequence'] as int? ?? 0, // Defaulting sequence to 0 if null
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
      audioId: map['audio_id'],
      translations: map['translations'] as List<dynamic>?, 
      audio: map['audio'],
      additionalFields: Map<String, dynamic>.fromEntries(
        map.entries.where((entry) => ![
          'id', 'chapter_id', 'volume_id', 'book_id', 'title', 'content', 'tags',
          'status', 'sequence', 'created_at', 'updated_at', 'audio_id',
          'translations', 'audio',
        ].contains(entry.key)),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'chapter_id': chapterId,
      'volume_id': volumeId,
      'book_id': bookId,
      'title': title,
      'content': content,
      'tags': tags,
      'status': status,
      'sequence': sequence,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'audio_id': audioId,
      'translations': translations,
      'audio': audio,
    };
    map.addAll(additionalFields);
    map.removeWhere((key, value) => value == null);
    return map;
  }

  @override
  String toString() {
    return 'Heading(firestoreDocId: $firestoreDocId, id: $id, title: $title, sequence: $sequence)';
  }

  Heading copyWith({
    String? firestoreDocId,
    int? id,
    int? chapterId,
    int? volumeId,
    int? bookId,
    String? title,
    List<String>? content,
    List<String>? tags,
    String? status,
    int? sequence,
    String? createdAt,
    String? updatedAt,
    dynamic audioId,
    List<dynamic>? translations,
    dynamic audio,
    Map<String, dynamic>? additionalFields,
  }) {
    return Heading(
      firestoreDocId: firestoreDocId ?? this.firestoreDocId,
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      volumeId: volumeId ?? this.volumeId,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      sequence: sequence ?? this.sequence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      audioId: audioId ?? this.audioId,
      translations: translations ?? this.translations,
      audio: audio ?? this.audio,
      additionalFields: additionalFields ?? this.additionalFields,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;
    final listEquals = const DeepCollectionEquality().equals;

    return other is Heading &&
        other.firestoreDocId == firestoreDocId &&
        other.id == id &&
        other.chapterId == chapterId &&
        other.volumeId == volumeId &&
        other.bookId == bookId &&
        other.title == title &&
        listEquals(other.content, content) &&
        listEquals(other.tags, tags) &&
        other.status == status &&
        other.sequence == sequence &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.audioId == audioId &&
        listEquals(other.translations, translations) &&
        other.audio == audio &&
        mapEquals(other.additionalFields, additionalFields);
  }

  @override
  int get hashCode {
    return firestoreDocId.hashCode ^
        id.hashCode ^
        chapterId.hashCode ^
        volumeId.hashCode ^
        bookId.hashCode ^
        title.hashCode ^
        content.hashCode ^
        tags.hashCode ^
        status.hashCode ^
        sequence.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        audioId.hashCode ^
        translations.hashCode ^
        audio.hashCode ^
        additionalFields.hashCode;
  }
}

class Book {
  final String firestoreDocId; // Document ID of this book in Firestore
  final int? id; // Original numeric ID from JSON
  final bool? unicode;
  final String? title;
  final String? author;
  final String? publisher;
  final String? publicationDate;
  final String? description;
  final String? audioUrl;
  final String? thumbnailUrl;
  final String? version;
  final String? link;
  final String? isbn;
  final List<String>? tags;
  final String? defaultLanguage;
  final String? status;
  final int? sequence; 
  final bool? isFeatured;
  final String? createdAt;
  final String? updatedAt;
  final List<dynamic>? languages;
  final List<dynamic>? bookTranslations;
  final Map<String, dynamic> additionalFields; 

  final String? languageCode; // Added languageCode
  final String? type; // Added type

  List<Heading>? headings; 
  List<Volume>? volumes; // Added field
  bool isFromCache = false; // Added to track cache source

  Book({
    required this.firestoreDocId,
    this.id,
    this.unicode,
    this.title,
    this.author,
    this.publisher,
    this.publicationDate,
    this.description,
    this.audioUrl,
    this.thumbnailUrl,
    this.version,
    this.link,
    this.isbn,
    this.tags,
    this.defaultLanguage,
    this.status,
    this.sequence,
    this.isFeatured,
    this.createdAt,
    this.updatedAt,
    this.languages,
    this.bookTranslations,
    Map<String, dynamic>? additionalFields,
    this.languageCode, // Added languageCode
    this.type, // Added type
    this.headings,
    this.volumes, // Added to constructor
  }) : additionalFields = additionalFields ?? {};

  factory Book.fromMap(String docId, Map<String, dynamic> map) {
    List<T>? safelyCastList<T>(dynamic list) {
      if (list is List) {
        return list.whereType<T>().toList();
      }
      return null;
    }

    return Book(
      firestoreDocId: docId,
      id: map['id'] as int?,
      unicode: map['unicode'] as bool?,
      title: map['title'] as String?,
      author: map['author'] as String?,
      publisher: map['publisher'] as String?,
      publicationDate: map['publication_date'] as String?,
      description: map['description'] as String?,
      audioUrl: map['audio_url'] as String?,
      thumbnailUrl: map['thumbnail_url'] as String?,
      version: map['version'] as String?,
      link: map['link'] as String?,
      isbn: map['isbn'] as String?,
      tags: safelyCastList<String>(map['tags']),
      defaultLanguage: map['default_language'] as String?,
      status: map['status'] as String?,
      sequence: map['sequence'] as int?,
      isFeatured: map['is_featured'] as bool?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
      languages: map['languages'] as List<dynamic>?,
      bookTranslations: map['book_translations'] as List<dynamic>?,
      additionalFields: Map<String, dynamic>.fromEntries(
        map.entries.where((entry) => ![
          'id', 'unicode', 'title', 'author', 'publisher', 'publication_date',
          'description', 'audio_url', 'thumbnail_url', 'version', 'link', 'isbn',
          'tags', 'default_language', 'status', 'sequence', 'is_featured',
          'created_at', 'updated_at', 'languages', 'book_translations',
        ].contains(entry.key)),
      ),
      languageCode: map['language_code'] as String?, // Added languageCode
      type: map['type'] as String?, // Added type
      headings: null, 
      volumes: null, // volumes initialized to null
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'unicode': unicode,
      'title': title,
      'author': author,
      'publisher': publisher,
      'publication_date': publicationDate,
      'description': description,
      'audio_url': audioUrl,
      'thumbnail_url': thumbnailUrl,
      'version': version,
      'link': link,
      'isbn': isbn,
      'tags': tags,
      'default_language': defaultLanguage,
      'status': status,
      'sequence': sequence,
      'is_featured': isFeatured,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'languages': languages,
      'book_translations': bookTranslations,
      'language_code': languageCode,
      'type': type,
      // Properly include headings and volumes for complete caching
      'headings': headings?.map((h) => h.toMap()).toList(),
      'volumes': volumes?.map((v) => v.toMap()).toList(),
    };
    
    // Add any additional fields
    map.addAll(additionalFields);
    
    // Remove null values to optimize storage
    map.removeWhere((key, value) => value == null);
    
    return map;
  }

  void setHeadings(List<Heading> fetchedHeadings) {
    headings = fetchedHeadings;
  }

  void setVolumes(List<Volume> fetchedVolumes) { // Added method
    volumes = fetchedVolumes;
  }

  @override
  String toString() {
    return 'Book(firestoreDocId: $firestoreDocId, id: $id, title: $title, author: $author, status: $status, headingsCount: ${headings?.length ?? 0}, volumesCount: ${volumes?.length ?? 0}, additionalFields: $additionalFields)'; // Updated toString
  }

  Book copyWith({
    String? firestoreDocId,
    int? id,
    bool? unicode,
    String? title,
    String? author,
    String? publisher,
    String? publicationDate,
    String? description,
    String? audioUrl,
    String? thumbnailUrl,
    String? version,
    String? link,
    String? isbn,
    List<String>? tags,
    String? defaultLanguage,
    String? status,
    int? sequence,
    bool? isFeatured,
    String? createdAt,
    String? updatedAt,
    List<dynamic>? languages,
    List<dynamic>? bookTranslations,
    Map<String, dynamic>? additionalFields,
    String? languageCode, // Added languageCode
    String? type, // Added type
    List<Heading>? headings,
    List<Volume>? volumes,
  }) {
    return Book(
      firestoreDocId: firestoreDocId ?? this.firestoreDocId,
      id: id ?? this.id,
      unicode: unicode ?? this.unicode,
      title: title ?? this.title,
      author: author ?? this.author,
      publisher: publisher ?? this.publisher,
      publicationDate: publicationDate ?? this.publicationDate,
      description: description ?? this.description,
      audioUrl: audioUrl ?? this.audioUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      version: version ?? this.version,
      link: link ?? this.link,
      isbn: isbn ?? this.isbn,
      tags: tags ?? this.tags,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      status: status ?? this.status,
      sequence: sequence ?? this.sequence,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      languages: languages ?? this.languages,
      bookTranslations: bookTranslations ?? this.bookTranslations,
      additionalFields: additionalFields ?? this.additionalFields,
      languageCode: languageCode ?? this.languageCode, // Added languageCode
      type: type ?? this.type, // Added type
      headings: headings ?? this.headings,
      volumes: volumes ?? this.volumes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;
    final listEquals = const DeepCollectionEquality().equals;

    return other is Book &&
        other.firestoreDocId == firestoreDocId &&
        other.id == id &&
        other.unicode == unicode &&
        other.title == title &&
        other.author == author &&
        other.publisher == publisher &&
        other.publicationDate == publicationDate &&
        other.description == description &&
        other.audioUrl == audioUrl &&
        other.thumbnailUrl == thumbnailUrl &&
        other.version == version &&
        other.link == link &&
        other.isbn == isbn &&
        listEquals(other.tags, tags) &&
        other.defaultLanguage == defaultLanguage &&
        other.status == status &&
        other.sequence == sequence &&
        other.isFeatured == isFeatured &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        listEquals(other.languages, languages) &&
        listEquals(other.bookTranslations, bookTranslations) &&
        other.languageCode == languageCode && // Added languageCode
        other.type == type && // Added type
        mapEquals(other.additionalFields, additionalFields) &&
        listEquals(other.headings, headings) &&
        listEquals(other.volumes, volumes); // Added to ==
  }

  @override
  int get hashCode {
    return firestoreDocId.hashCode ^
        id.hashCode ^
        unicode.hashCode ^
        title.hashCode ^
        author.hashCode ^
        publisher.hashCode ^
        publicationDate.hashCode ^
        description.hashCode ^
        audioUrl.hashCode ^
        thumbnailUrl.hashCode ^
        version.hashCode ^
        link.hashCode ^
        isbn.hashCode ^
        tags.hashCode ^
        defaultLanguage.hashCode ^
        status.hashCode ^
        sequence.hashCode ^
        isFeatured.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        languages.hashCode ^
        bookTranslations.hashCode ^
        languageCode.hashCode ^ // Added languageCode
        type.hashCode ^ // Added type
        additionalFields.hashCode ^
        headings.hashCode ^
        volumes.hashCode; // Added to hashCode
  }
} 

// ---- New Classes Appended Below ----

class Volume {
  final String firestoreDocId;
  final int? id;
  final String? title;
  final int? bookId;  // Reference to parent book
  final int? sequence;
  final String? description;
  final String? status;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic> additionalFields;
  List<Chapter>? chapters;

  Volume({
    required this.firestoreDocId,
    this.id,
    this.title,
    this.bookId,
    this.sequence,
    this.description,
    this.status,
    this.createdAt,
    this.updatedAt,
    Map<String, dynamic>? additionalFields,
    this.chapters,
  }) : additionalFields = additionalFields ?? {};

  factory Volume.fromMap(String docId, Map<String, dynamic> map) {
    return Volume(
      firestoreDocId: docId,
      id: map['id'] as int?,
      title: map['title'] as String?,
      bookId: map['book_id'] as int?,
      sequence: map['sequence'] as int?,
      description: map['description'] as String?,
      status: map['status'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
      additionalFields: Map<String, dynamic>.fromEntries(
        map.entries.where((entry) => ![
          'id', 'title', 'book_id', 'sequence', 'description',
          'status', 'created_at', 'updated_at'
        ].contains(entry.key)),
      ),
      chapters: null, // Chapters fetched separately
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'book_id': bookId,
      'sequence': sequence,
      'description': description,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
    map.addAll(additionalFields);
    map.removeWhere((key, value) => value == null);
    return map;
  }

  Volume copyWith({
    String? firestoreDocId,
    int? id,
    String? title,
    int? bookId,
    int? sequence,
    String? description,
    String? status,
    String? createdAt,
    String? updatedAt,
    Map<String, dynamic>? additionalFields,
    List<Chapter>? chapters,
  }) {
    return Volume(
      firestoreDocId: firestoreDocId ?? this.firestoreDocId,
      id: id ?? this.id,
      title: title ?? this.title,
      bookId: bookId ?? this.bookId,
      sequence: sequence ?? this.sequence,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalFields: additionalFields ?? this.additionalFields,
      chapters: chapters ?? this.chapters,
    );
  }

  @override
  String toString() {
    return 'Volume(firestoreDocId: $firestoreDocId, id: $id, title: $title, bookId: $bookId, sequence: $sequence, chaptersCount: ${chapters?.length ?? 0})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;
    final listEquals = const DeepCollectionEquality().equals;

    return other is Volume &&
        other.firestoreDocId == firestoreDocId &&
        other.id == id &&
        other.title == title &&
        other.bookId == bookId &&
        other.sequence == sequence &&
        other.description == description &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        mapEquals(other.additionalFields, additionalFields) &&
        listEquals(other.chapters, chapters);
  }

  @override
  int get hashCode {
    return firestoreDocId.hashCode ^
        id.hashCode ^
        title.hashCode ^
        bookId.hashCode ^
        sequence.hashCode ^
        description.hashCode ^
        status.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        additionalFields.hashCode ^
        chapters.hashCode;
  }
}

class Chapter {
  final dynamic id;
  final String? firestoreDocId;
  final String? title;
  final String? description;
  final int? sequence;
  final int? volumeId;
  final int? bookId; // Added for cache service
  final String? status; // Added for cache service
  final String? createdAt; // Added for cache service
  final String? updatedAt; // Added for cache service
  final List<String>? content; // Added for content storage
  List<Heading>? headings;

  Chapter({
    required this.id,
    this.firestoreDocId,
    this.title,
    this.description,
    this.sequence,
    this.volumeId,
    this.bookId,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.content,
    this.headings,
  });

  factory Chapter.fromMap(String docId, Map<String, dynamic> map) {
    return Chapter(
      id: map['id'] ?? 0,
      firestoreDocId: docId,
      title: map['title'],
      description: map['description'],
      sequence: map['sequence'],
      volumeId: map['volume_id'],
      bookId: map['book_id'],
      status: map['status'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      content: map['content'] != null ? List<String>.from(map['content']) : null,
      headings: null, // Will be populated separately
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firestoreDocId': firestoreDocId,
      'title': title,
      'description': description,
      'sequence': sequence,
      'volume_id': volumeId,
      'book_id': bookId,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'content': content,
      'headings': headings?.map((h) => h.toMap()).toList(), // Assuming Heading has toMap
    }..removeWhere((key, value) => value == null);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chapter &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          firestoreDocId == other.firestoreDocId &&
          title == other.title &&
          description == other.description &&
          sequence == other.sequence &&
          volumeId == other.volumeId &&
          bookId == other.bookId &&
          status == other.status &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          listEquals(content, other.content) &&
          listEquals(headings, other.headings);

  @override
  int get hashCode =>
      id.hashCode ^
      firestoreDocId.hashCode ^
      title.hashCode ^
      description.hashCode ^
      sequence.hashCode ^
      volumeId.hashCode ^
      bookId.hashCode ^
      status.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      content.hashCode ^
      headings.hashCode;
} 