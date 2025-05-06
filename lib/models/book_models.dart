import 'package:collection/collection.dart'; // For DeepCollectionEquality
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
    List<T>? _safelyCastList<T>(dynamic list) {
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
      content: _safelyCastList<String>(map['content']),
      tags: _safelyCastList<String>(map['tags']),
      status: map['status'] as String?,
      sequence: map['sequence'] as int? ?? 0,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
      audioId: map['audio_id'],
      translations: map['translations'] as List<dynamic>?, // Keep dynamic if structure varies
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

  // Method to convert a Heading object to a map for Firestore
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
    // Remove null values if you prefer not to store them in Firestore
    map.removeWhere((key, value) => value == null);
    return map;
  }

  @override
  String toString() {
    return 'Heading(firestoreDocId: $firestoreDocId, id: $id, chapterId: $chapterId, volumeId: $volumeId, bookId: $bookId, title: $title, sequence: $sequence, status: $status, contentCount: ${content?.length ?? 0}, additionalFields: $additionalFields)';
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
  final int? sequence; // Book sequence
  final bool? isFeatured;
  final String? createdAt;
  final String? updatedAt;
  // languages and book_translations can be List<Map<String, dynamic>> if complex
  // For simplicity, if they are simple lists of strings or not always present:
  final List<dynamic>? languages;
  final List<dynamic>? bookTranslations;
  // volumes and chapters from JSON are NOT directly stored in the main Book doc by run.py
  // They would need separate models and fetching logic if run.py were to handle them.

  final Map<String, dynamic>
      additionalFields; // To capture any other dynamic fields

  List<Heading>? headings; // Populated after fetching from subcollection

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
    this.headings,
  }) : additionalFields = additionalFields ?? {};

  factory Book.fromMap(String docId, Map<String, dynamic> map) {
     // Helper to safely cast list elements
    List<T>? _safelyCastList<T>(dynamic list) {
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
      tags: _safelyCastList<String>(map['tags']),
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
      headings: null, // Headings fetched separately
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
    };
    map.addAll(additionalFields);
    map.removeWhere((key, value) => value == null);
    return map;
  }

  // Helper to set headings after fetching them
  void setHeadings(List<Heading> fetchedHeadings) {
    headings = fetchedHeadings;
  }

  @override
  String toString() {
    return 'Book(firestoreDocId: $firestoreDocId, id: $id, title: $title, author: $author, status: $status, headingsCount: ${headings?.length ?? 0}, additionalFields: $additionalFields)';
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
    List<Heading>? headings,
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
      headings: headings ?? this.headings,
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
        mapEquals(other.additionalFields, additionalFields) &&
        listEquals(other.headings, headings);
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
        additionalFields.hashCode ^
        headings.hashCode;
  }
} 