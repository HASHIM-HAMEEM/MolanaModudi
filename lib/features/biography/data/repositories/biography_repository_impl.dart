import 'dart:convert'; // For jsonDecode
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // Gemini package

import '../../domain/entities/biography_event_entity.dart';
import '../../domain/repositories/biography_repository.dart';
import '../models/biography_event_model.dart';
import '../../../../core/services/gemini_service.dart'; // Import GeminiService

class BiographyRepositoryImpl implements BiographyRepository {
  final GenerativeModel _geminiModel;
  final Logger _log = Logger('BiographyRepositoryImpl');

  BiographyRepositoryImpl(this._geminiModel);

  @override
  Future<List<BiographyEventEntity>> getBiographyEvents() async {
    _log.info('Fetching biography events from Gemini...');
    try {
      final prompt = _buildBiographyPrompt();
      final content = [Content.text(prompt)];
      final response = await _geminiModel.generateContent(content);

      if (response.text == null) {
        _log.warning('Gemini response text was null.');
        throw Exception('Failed to generate biography: No response text from AI.');
      }

      _log.fine('Received Gemini response: ${response.text!.substring(0, (response.text!.length > 200 ? 200 : response.text!.length))}...');

      // Attempt to parse the JSON response from Gemini
      final List<dynamic> jsonData = _parseJsonResponse(response.text!);

      // Convert JSON data to BiographyEventModel list
      final events = jsonData
          .map((item) => BiographyEventModel.fromJson(item as Map<String, dynamic>))
          .toList();
          
      _log.info('Successfully parsed ${events.length} biography events.');
      return events;

    } catch (e, stackTrace) {
      _log.severe('Error fetching or parsing biography: $e', e, stackTrace);
      // Rethrow a more specific exception or handle it as needed
      if (e is FormatException) {
        throw Exception('Failed to parse biography data from AI response.');
      } else if (e is GenerativeAIException) {
         throw Exception('AI service error: ${e.message}');
      }
      throw Exception('An unexpected error occurred while fetching the biography: $e');
    }
  }

  String _buildBiographyPrompt() {
    // This prompt requests a structured JSON output for easy parsing.
    return """
Generate a detailed, chronological biography of Maulana Abul A'la Maududi (1903-1979).
Focus on key life events, significant publications (like Tafhim-ul-Quran), the founding and development of Jamaat-e-Islami, his major intellectual contributions, legal challenges, and his role in the 20th-century Islamic revival movement.

Present the information as a JSON array of objects. Each object should represent a significant event or period and must contain the following keys:
1.  `"date"`: A string representing the year or date range (e.g., "1903", "1932-1933", "August 1941", "September 22, 1979").
2.  `"title"`: A concise string summarizing the event (e.g., "Birth and Early Life", "Editor of Tarjuman al-Quran", "Founding of Jamaat-e-Islami", "Completion of Tafhim-ul-Quran", "Death").
3.  `"description"`: A string (use Markdown for simple formatting like bolding key terms if helpful) providing details about the event and its significance, particularly emphasizing his positive impact and role in reviving Islamic thought and activism according to his followers' perspective.

Ensure the timeline is comprehensive, covering his entire life from birth to death, and that the JSON format is strictly adhered to.
""";
  }
  
  // Helper function to reliably parse JSON, potentially cleaning the response text
  List<dynamic> _parseJsonResponse(String responseText) {
    try {
      // Find the start and end of the JSON array
      final startIndex = responseText.indexOf('[');
      final endIndex = responseText.lastIndexOf(']');
      
      if (startIndex == -1 || endIndex == -1 || endIndex < startIndex) {
        _log.warning('Could not find valid JSON array markers [ ] in response.');
        throw FormatException('Invalid JSON format: Array markers not found.');
      }
      
      final jsonString = responseText.substring(startIndex, endIndex + 1);
      
      // Decode the extracted JSON string
      final decodedJson = jsonDecode(jsonString);
      
      if (decodedJson is List) {
        return decodedJson;
      } else {
         _log.warning('Decoded JSON is not a List.');
        throw FormatException('Invalid JSON format: Expected a List.');
      }
    } catch (e) {
      _log.severe('Error parsing JSON response: $e');
      _log.info('Raw response text was: $responseText'); // Log raw response for debugging
      throw FormatException('Failed to parse JSON from Gemini response: $e');
    }
  }
}

// Provider for the BiographyRepository implementation
final biographyRepositoryProvider = Provider<BiographyRepository>((ref) {
  final geminiService = ref.watch(geminiServiceProvider); // Get GeminiService instance
  return BiographyRepositoryImpl(geminiService.getModel()); // Pass the GenerativeModel
}); 