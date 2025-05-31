import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:modudi/features/home/domain/repositories/home_repository.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/video_entity.dart';

final _log = Logger('FirestoreHomeRepository');

// Provider for the HomeRepository implementation
final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  return FirestoreHomeRepository(firestore);
});

class FirestoreHomeRepository implements HomeRepository {
  @override
  Future<Book?> getBookById(String bookId) async {
    final doc = await _firestore.collection('books').doc(bookId).get();
    if (!doc.exists) return null;
    return Book.fromMap(bookId, doc.data()!);
  }
  final FirebaseFirestore _firestore;
  
  FirestoreHomeRepository(this._firestore);
  
  @override
  Future<List<Book>> getFeaturedBooks({int perPage = 500}) async {
    try {
      _log.info('Fetching featured books from Firestore');
      // First try to get books marked as featured
      var snapshot = await _firestore.collection('books')
          .where('is_featured', isEqualTo: true)
          .limit(perPage)
          .get();
      
      // If no featured books found, get all books
      if (snapshot.docs.isEmpty) {
        _log.info('No featured books found, fetching all books instead');
        snapshot = await _firestore.collection('books')
            .limit(perPage)
            .get();
      }
      
      _log.info('Found ${snapshot.docs.length} books for featured section');
      
      return snapshot.docs
          .map((doc) => Book.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      _log.severe('Error fetching featured books: $e');
      throw Exception('Failed to fetch featured books');
    }
  }

  @override
  Future<List<CategoryEntity>> getCategories() async {
    try {
      _log.info('Fetching categories from Firestore');
      final snapshot = await _firestore.collection('categories')
          .orderBy('sequence')
          .get();
      
      List<CategoryEntity> categories = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        categories.add(CategoryEntity(
          id: doc.id,
          name: data['name'] as String,
          count: data['count'] as int? ?? 0,
        ));
      }
      return categories;
    } catch (e) {
      _log.severe('Error fetching categories: $e');
      throw Exception('Failed to fetch categories');
    }
  }

  @override
  Future<List<VideoEntity>> getVideoLectures({int perPage = 5}) async {
    try {
      _log.info('Fetching video lectures from Firestore');
      final snapshot = await _firestore.collection('videos')
          .where('featured', isEqualTo: true)
          .limit(perPage)
          .get();
      
      List<VideoEntity> videos = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        videos.add(VideoEntity(
          id: doc.id,
          title: data['title'] as String,
          thumbnailUrl: data['thumbnailUrl'] as String?,
          duration: data['duration']?.toString(),
          source: data['source'] as String?,
          url: data['url'] as String?,
        ));
      }
      return videos;
    } catch (e) {
      _log.severe('Error fetching video lectures: $e');
      throw Exception('Failed to fetch video lectures');
    }
  }
} 