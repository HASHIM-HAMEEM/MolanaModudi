import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/features/home/data/providers/home_data_providers.dart'; // To access home repo
import 'package:modudi/features/home/domain/entities/book_entity.dart';
import 'package:modudi/features/home/domain/repositories/home_repository.dart';

// Provider that fetches the list of books for the library
// For now, it reuses getFeaturedBooks with a potentially larger limit
final libraryBooksProvider = FutureProvider<List<BookEntity>>((ref) async {
  final homeRepository = ref.watch(homeRepositoryProvider);
  // Fetch a larger number of books for the library view
  // We can adjust the query or method later if needed
  return await homeRepository.getFeaturedBooks(perPage: 100); // Fetch 100 books for library
}); 