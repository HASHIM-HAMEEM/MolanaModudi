import 'package:modudi/features/books/data/models/book_models.dart'; // Assuming Volume, Chapter, Heading models are here

class BookStructure {
  final List<Volume> volumes;
  final List<Chapter> standaloneChapters; // Chapters not under a volume

  BookStructure({required this.volumes, required this.standaloneChapters});

  // Optional: Add a factory constructor for fromMap/toMap if needed for caching complex structures,
  // though Hive can often store objects directly if adapters are registered.
  // For now, assuming direct object storage or that the repository will handle serialization.

  bool get isEmpty => volumes.isEmpty && standaloneChapters.isEmpty;
}
