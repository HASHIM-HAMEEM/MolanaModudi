import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static final _log = Logger('GeminiService');
  final GenerativeModel _model; // Store the model instance
  final String _apiKey; // Store the API key

  // Constructor to accept the model
  GeminiService(this._model, this._apiKey);

  // Getter for the model
  GenerativeModel getModel() => _model;

  // General method to call Gemini API with retry logic
  Future<String?> _callGemini(String prompt, {bool usePro = false, int maxRetries = 2}) async {
    int attempts = 0;
    while (attempts <= maxRetries) {
      try {
        // Use the stored model name and API key
        final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$_apiKey';
        
        _log.info('Calling Gemini API: gemini-1.5-pro (attempt ${attempts + 1}/${maxRetries + 1})');
        _log.fine('Prompt preview: ${prompt.substring(0, (prompt.length > 100 ? 100 : prompt.length))}...');
        
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [{
              'parts': [{'text': prompt}]
            }],
            'generationConfig': {
              'temperature': 0.2, // Lower temperature for more deterministic outputs
              'topP': 0.9,
              'topK': 40,
              'maxOutputTokens': 2048,
            }
          }),
        );

        if (response.statusCode == 200) {
          _log.info('Gemini API call successful (200 OK)');
          
          final data = jsonDecode(response.body);
          
          // Enhanced response parsing with detailed logging
          if (!data.containsKey('candidates') || (data['candidates'] as List).isEmpty) {
            _log.warning('Gemini API returned 200 OK but no candidates in response');
            return null;
          }
          
          final candidates = data['candidates'] as List;
          final firstCandidate = candidates[0];
          
          if (!firstCandidate.containsKey('content')) {
            _log.warning('First candidate missing content field');
            return null;
          }
          
          final content = firstCandidate['content'];
          
          if (!content.containsKey('parts') || (content['parts'] as List).isEmpty) {
            _log.warning('Content missing parts field or parts is empty');
            return null;
          }
          
          final parts = content['parts'] as List;
          final firstPart = parts[0];
          
          if (!firstPart.containsKey('text')) {
            _log.warning('First part missing text field');
            return null;
          }
          
          final text = firstPart['text'] as String;
          
          if (text.trim().isEmpty) {
            _log.warning('Received empty text from Gemini API');
            return null;
          }
          
          _log.fine('Successfully extracted text (length: ${text.length})');
          return text;
        } else if (response.statusCode == 400) {
          // Bad request - likely an issue with our prompt or parameters
          _log.severe('Gemini API bad request (400): ${response.body}');
          
          // Parse error response to get more details
          try {
            final errorData = jsonDecode(response.body);
            final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
            _log.severe('Error details: $errorMessage');
            
            // If error is related to the model, we should not retry
            if (errorMessage.contains('not found') || errorMessage.contains('not supported')) {
              _log.severe('Model error detected, aborting retry');
              return null;
            }
          } catch (e) {
            _log.severe('Failed to parse error response: $e');
          }
          
          // Some 400 errors are worth retrying with backoff
          attempts++;
          if (attempts <= maxRetries) {
            _log.warning('Retrying Gemini API call (${attempts}/${maxRetries})');
            await Future.delayed(Duration(seconds: 2 * attempts)); // Exponential backoff
            continue;
          }
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          // Authentication or authorization error
          _log.severe('Gemini API auth error (${response.statusCode}): ${response.body}');
          return null; // No retry for auth errors
        } else if (response.statusCode == 404) {
          // Resource not found - likely a model name issue
          _log.severe('Gemini API 404 error (resource not found): ${response.body}');
          
          // Try to extract specific error details
          try {
            final errorData = jsonDecode(response.body);
            final errorMessage = errorData['error']?['message'] ?? 'Resource not found';
            _log.severe('Error details: $errorMessage');
          } catch (e) {
            _log.severe('Failed to parse 404 error response: $e');
          }
          
          return null; // No retry for 404 errors
        } else if (response.statusCode == 429 || response.statusCode >= 500) {
          // Retry on rate limiting or server errors
          final errorType = response.statusCode == 429 ? "rate limit" : "server";
          _log.warning('Gemini API $errorType error (${response.statusCode}): ${response.body}');
          
          attempts++;
          if (attempts <= maxRetries) {
            final backoffSeconds = 2 * attempts;
            _log.warning('Retrying Gemini API call in $backoffSeconds seconds (${attempts}/${maxRetries})');
            await Future.delayed(Duration(seconds: backoffSeconds)); // Exponential backoff
            continue;
          }
        }
        
        _log.severe('Gemini API error: ${response.statusCode} - ${response.body}');
        return null;
      } catch (e, stackTrace) {
        _log.severe('Error calling Gemini API: $e', e, stackTrace);
        attempts++;
        if (attempts <= maxRetries) {
          final backoffSeconds = 1 * attempts;
          _log.warning('Retrying Gemini API call in $backoffSeconds seconds (${attempts}/${maxRetries})');
          await Future.delayed(Duration(seconds: backoffSeconds));
          continue;
        }
        return null;
      }
    }
    
    _log.severe('All Gemini API attempts failed after ${maxRetries + 1} tries');
    return null;
  }

  // 1. CHAPTER EXTRACTION - Enhanced with book format detection
  Future<List<Map<String, dynamic>>> extractChapters(String text, {int maxLength = 8000, String? bookType, String? title, bool isTableOfContents = false}) async {
    try {
      // For PDFs with table of contents, use a specialized prompt
      if (bookType == 'pdf' && (isTableOfContents || title?.toLowerCase().contains('content') == true)) {
        return await _extractChaptersFromTableOfContents(text, title);
      }

      // Trim the text to avoid exceeding token limits
      final trimmedText = text.length > maxLength ? text.substring(0, maxLength) : text;
      
      String bookTypePrompt = '';
      if (bookType != null) {
        bookTypePrompt = 'This is a $bookType book. ';
      }
      
      String titlePrompt = '';
      if (title != null && title.isNotEmpty) {
        titlePrompt = 'The book title is "$title". ';
      }
      
      final prompt = '''
${bookTypePrompt}${titlePrompt}Analyze the following text and identify a structured table of contents with chapters and sections.

Instructions:
1. Identify chapter titles, headings, and subheadings
2. Determine page numbers or relative positions (percentage through the text)
3. Create a hierarchical structure matching the document organization
4. If the document is in Arabic or Urdu, recognize right-to-left formatting and chapter indicators
5. For religious texts, identify standard divisions (surahs, verses, etc.)

Return the result as a JSON array where each item has:
- "title": The chapter or section title
- "pageStart": The starting page or position (integer)
- "subtitle": Optional subtitle or description
- "level": Hierarchy level (1 for chapters, 2 for sections, etc.)

If chapters aren't clearly marked, create logical divisions based on content themes and transitions.

Text: 
$trimmedText
      ''';

      final response = await _callGemini(prompt, usePro: true);
      if (response != null) {
        // Extract JSON from the response
        final pattern = RegExp(r'\[[\s\S]*\]');
        final match = pattern.firstMatch(response);
        if (match != null) {
          final jsonStr = match.group(0);
          if (jsonStr != null) {
            try {
              return List<Map<String, dynamic>>.from(jsonDecode(jsonStr));
            } catch (e) {
              _log.warning('Error parsing JSON chapters: $e. Attempting cleanup...');
              // Try to clean malformed JSON
              final cleaned = _cleanJsonString(jsonStr);
              return List<Map<String, dynamic>>.from(jsonDecode(cleaned));
            }
          }
        }
      }
      
      // Fallback: Create basic chapter structure if extraction fails
      if (title != null) {
        return _createBasicChapters(title);
      }
      
      return [];
    } catch (e) {
      _log.severe('Error extracting chapters: $e');
      return [];
    }
  }
  
  // Special method for extracting chapters from a table of contents page
  Future<List<Map<String, dynamic>>> _extractChaptersFromTableOfContents(String text, String? title) async {
    try {
      final prompt = '''
This is a Table of Contents page from a book${title != null ? ' titled "$title"' : ''}.
Extract the chapters and their page numbers from this content.

Instructions:
1. Identify all chapter titles and their corresponding page numbers 
2. Also identify subheadings and sections with their page numbers
3. Maintain the hierarchical structure as shown in the content
4. Extract both main chapters (like "Chapter I") and named sections
5. Correctly parse page numbers, even if they appear at different positions

Return the result as a JSON array where each item has:
- "title": The chapter or section title (exactly as written)
- "pageStart": The page number as an integer
- "subtitle": Optional subtitle (if applicable)
- "level": Hierarchy level (1 for chapters, 2 for sections, 3 for subsections)

Parse the following table of contents:

$text
''';

      final response = await _callGemini(prompt, usePro: true);
      if (response != null) {
        // Extract JSON array
        final pattern = RegExp(r'\[[\s\S]*\]');
        final match = pattern.firstMatch(response);
        if (match != null) {
          final jsonStr = match.group(0);
          if (jsonStr != null) {
            try {
              final chapters = List<Map<String, dynamic>>.from(jsonDecode(jsonStr));
              _log.info('Successfully extracted ${chapters.length} chapters from table of contents');
              return chapters;
            } catch (e) {
              _log.warning('Error parsing JSON from table of contents: $e. Attempting alternate parsing...');
              // Try more robust parsing - look for chapter patterns in the text
              return _extractChaptersFromText(response);
            }
          }
        }
      }
      
      return [];
    } catch (e) {
      _log.severe('Error extracting chapters from table of contents: $e');
      return [];
    }
  }
  
  // Extract chapters from unstructured text if JSON parsing fails
  List<Map<String, dynamic>> _extractChaptersFromText(String text) {
    final chapters = <Map<String, dynamic>>[];
    
    // Pattern to match "Chapter X" or "Chapter X:" followed by title and page number
    final chapterPattern = RegExp(r'(Chapter\s+[IVXLCDM\d]+[:\.\s]*)([^0-9\n]+)[\s\.]*([\d]+)', caseSensitive: false);
    
    // Pattern to match section titles with page numbers
    final sectionPattern = RegExp(r'([A-Z][^0-9\n]{3,})\s*([\d]+)');
    
    // Find chapters
    final chapterMatches = chapterPattern.allMatches(text);
    for (final match in chapterMatches) {
      final title = match.group(1)! + (match.group(2) ?? '').trim();
      final pageStr = match.group(3);
      final pageNum = int.tryParse(pageStr ?? '') ?? 1;
      
      chapters.add({
        "title": title.trim(),
        "pageStart": pageNum,
        "level": 1
      });
    }
    
    // Find sections
    final sectionMatches = sectionPattern.allMatches(text);
    for (final match in sectionMatches) {
      final title = match.group(1) ?? '';
      final pageStr = match.group(2);
      final pageNum = int.tryParse(pageStr ?? '') ?? 1;
      
      // Skip if very short or looks like a header/footer
      if (title.length < 4 || title.contains('Page') || title.contains('Contents')) {
        continue;
      }
      
      chapters.add({
        "title": title.trim(),
        "pageStart": pageNum,
        "level": chapters.isEmpty ? 1 : 2  // If no chapters found, treat as level 1
      });
    }
    
    // Sort by page number
    chapters.sort((a, b) => (a["pageStart"] as int).compareTo(b["pageStart"] as int));
    
    return chapters;
  }
  
  // Helper to create fallback chapters when extraction fails
  List<Map<String, dynamic>> _createBasicChapters(String title) {
    _log.info('Creating basic chapter fallback for "$title"');
    // Simple fallback if AI extraction fails
    return [
      {
        "title": "Introduction",
        "pageStart": 1,
        "level": 1,
      },
      {
        "title": "Conclusion",
        "pageStart": -1, // Indicates end or unknown
        "level": 1,
      },
    ];
  }
  
  // Helper to clean malformed JSON
  String _cleanJsonString(String jsonStr) {
    return jsonStr
      .replaceAll(RegExp(r',\s*}'), '}') // Remove trailing commas in objects
      .replaceAll(RegExp(r',\s*\]'), ']') // Remove trailing commas in arrays
      .replaceAll(RegExp(r'\\'), '\\\\'); // Escape backslashes
  }

  // 2. BOOK SUMMARY - Enhanced with theme extraction
  Future<Map<String, dynamic>> generateBookSummary(String bookTitle, String author, {String? excerpt, String? language}) async {
    try {
      String prompt = '''
Generate a comprehensive analysis of the book "$bookTitle" by $author. 
${language != null ? 'The book is in $language. ' : ''}

Provide a response in JSON format with the following fields:
- "summary": A concise summary of the book (1-2 paragraphs)
- "themes": An array of main themes or concepts in the book (3-5 items)
- "audience": The likely target audience
- "difficulty": Reading level difficulty (easy, moderate, challenging)
- "keyTakeaways": An array of key lessons or insights (3-5 items)

''';
      
      if (excerpt != null && excerpt.isNotEmpty) {
        // Trim excerpt to avoid token limits
        final trimmedExcerpt = excerpt.length > 3000 ? excerpt.substring(0, 3000) : excerpt;
        prompt += 'Use this excerpt to enhance your analysis:\n\n$trimmedExcerpt';
      }

      final response = await _callGemini(prompt, usePro: true);
      if (response != null) {
        // Extract JSON from the response
        final pattern = RegExp(r'\{[\s\S]*\}');
        final match = pattern.firstMatch(response);
        if (match != null) {
          final jsonStr = match.group(0);
          if (jsonStr != null) {
            try {
              return Map<String, dynamic>.from(jsonDecode(jsonStr));
            } catch (e) {
              _log.warning('Failed to parse JSON summary. Creating simplified version.');
              // Fallback to simpler format
              return {
                "summary": response.length > 500 ? response.substring(0, 500) : response,
                "themes": ["Theme analysis unavailable"],
                "keyTakeaways": ["Key takeaways unavailable"]
              };
            }
          }
        }
        
        // If JSON extraction failed, return the raw text as summary
        return {
          "summary": response,
          "themes": ["Theme analysis unavailable"],
          "keyTakeaways": ["Key takeaways unavailable"]
        };
      }
      return {
        "summary": "Unable to generate summary for $bookTitle.",
        "themes": ["Theme analysis unavailable"],
        "keyTakeaways": ["Key takeaways unavailable"]
      };
    } catch (e) {
      _log.severe('Error generating book summary: $e');
      return {
        "summary": "Error generating summary: $e",
        "themes": ["Theme analysis unavailable"],
        "keyTakeaways": ["Key takeaways unavailable"]
      };
    }
  }

  // 3. BOOK RECOMMENDATIONS - Enhanced with details and reasons
  Future<List<Map<String, dynamic>>> getBookRecommendations(List<String> recentBooks, {String preferredGenre = '', List<String>? preferredAuthors, String? readerProfile}) async {
    try {
      final booksJoined = recentBooks.take(5).join(', ');
      
      String prompt = '''
Create personalized book recommendations based on these recently read books: $booksJoined.
${preferredGenre.isNotEmpty ? 'Focus on the $preferredGenre genre. ' : ''}
${preferredAuthors != null && preferredAuthors.isNotEmpty ? 'Consider books by these authors: ${preferredAuthors.join(', ')}. ' : ''}
${readerProfile != null ? 'Reader profile: $readerProfile. ' : ''}

Return results as a JSON array where each object has:
- "title": Book title
- "author": Author name
- "reason": Why this book is recommended based on reading history
- "publicationYear": Approximate year of publication
- "genre": Primary genre
- "similarTo": Which of the reader's previous books this is most similar to

Limit to 5 recommendations that are truly personalized.
''';

      final response = await _callGemini(prompt, usePro: true);
      if (response != null) {
        // Extract JSON from the response
        final pattern = RegExp(r'\[[\s\S]*\]');
        final match = pattern.firstMatch(response);
        if (match != null) {
          final jsonStr = match.group(0);
          if (jsonStr != null) {
            try {
              return List<Map<String, dynamic>>.from(jsonDecode(jsonStr));
            } catch (e) {
              _log.warning('Error parsing JSON recommendations: $e');
              // Fallback: extract titles at minimum
              final titles = response
                  .split('\n')
                  .where((line) => line.contains(':') && line.toLowerCase().contains('title'))
                  .map((line) => line.split(':').last.trim())
                  .where((title) => title.isNotEmpty)
                  .toList();
              
              return titles.map((title) => {
                "title": title,
                "author": "Unknown",
                "reason": "Based on your reading history"
              }).toList();
            }
          }
        }
        
        // Fallback: Try to extract titles from text
        final titles = response
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) => line.replaceAll(RegExp(r'^\d+\.?\s*'), '').trim())
            .where((title) => title.isNotEmpty)
            .take(5)
            .toList();
        
        return titles.map((title) => {
          "title": title,
          "author": "Unknown",
          "reason": "Based on your reading history"
        }).toList();
      }
      return [];
    } catch (e) {
      _log.severe('Error getting book recommendations: $e');
      return [];
    }
  }

  // 4. TRANSLATION - Enhanced with formatting preservation and language detection
  Future<Map<String, dynamic>> translateText(String text, String targetLanguage, {bool preserveFormatting = true}) async {
    try {
      if (text.isEmpty) return {'translated': '', 'detectedLanguage': 'unknown'};
      
      // Trim text to avoid token limits
      final trimmedText = text.length > 3000 ? text.substring(0, 3000) : text;
      
      final prompt = '''
Translate the following text to $targetLanguage:
${preserveFormatting ? 'Preserve the original formatting, including paragraphs, bullet points, and emphasis. ' : ''}
Return a JSON object with:
- "translated": The translated text
- "detectedLanguage": The detected source language

Text to translate:
$trimmedText
''';

      final response = await _callGemini(prompt, usePro: true);
      if (response != null) {
        // Try to extract JSON
        final pattern = RegExp(r'\{[\s\S]*\}');
        final match = pattern.firstMatch(response);
        if (match != null) {
          final jsonStr = match.group(0);
          if (jsonStr != null) {
            try {
              return Map<String, dynamic>.from(jsonDecode(jsonStr));
            } catch (e) {
              _log.warning('Error parsing JSON translation: $e');
            }
          }
        }
        
        // Fallback: just return the translated text
        return {
          'translated': response,
          'detectedLanguage': 'unknown'
        };
      }
      return {
        'translated': 'Translation failed',
        'detectedLanguage': 'unknown'
      };
    } catch (e) {
      _log.severe('Error translating text: $e');
      return {
        'translated': 'Error: $e',
        'detectedLanguage': 'unknown'
      };
    }
  }

  // 5. SEMANTIC SEARCH - Enhanced with context and highlighting
  Future<List<Map<String, dynamic>>> semanticSearch(String query, List<String> paragraphs) async {
    try {
      if (paragraphs.isEmpty) return [];
      
      // Format the paragraphs
      final formattedParagraphs = paragraphs.asMap().entries.map((e) => 
          "${e.key + 1}. ${e.value}").join('\n\n');
      
      // Build prompt
      final prompt = '''
Find passages that best answer or relate to this query: "$query"

Instructions:
1. Analyze the query for key concepts, intent, and context
2. Find the most semantically relevant paragraphs, not just keyword matches
3. For each relevant paragraph, identify the key phrase that best answers the query
4. Evaluate how completely each paragraph addresses the query

Text paragraphs:
$formattedParagraphs

Return results as a JSON array where each object has:
- "paragraphIndex": The original paragraph number (1-based)
- "text": The full paragraph text
- "relevanceScore": A number from 0-100 indicating how relevant this paragraph is
- "keyPhrase": The most relevant phrase or sentence within the paragraph
- "explanation": Brief explanation of why this paragraph is relevant

Limit to max 5 most relevant results.
''';

      final response = await _callGemini(prompt, usePro: true);
      if (response != null) {
        // Extract JSON from the response
        final pattern = RegExp(r'\[[\s\S]*\]');
        final match = pattern.firstMatch(response);
        if (match != null) {
          final jsonStr = match.group(0);
          if (jsonStr != null) {
            try {
              return List<Map<String, dynamic>>.from(jsonDecode(jsonStr));
            } catch (e) {
              _log.warning('Error parsing JSON search results: $e');
            }
          }
        }
        
        // Fallback: extract paragraph numbers and return basic data
        final numberPattern = RegExp(r'\d+');
        final matches = numberPattern.allMatches(response);
        
        List<Map<String, dynamic>> results = [];
        for (var match in matches) {
          final index = int.tryParse(match.group(0) ?? '');
          if (index != null && index > 0 && index <= paragraphs.length) {
            results.add({
              "paragraphIndex": index,
              "text": paragraphs[index - 1],
              "relevanceScore": 70,
              "keyPhrase": "Relevant content",
              "explanation": "Contains relevant information"
            });
          }
        }
        
        return results.take(5).toList();
      }
      return [];
    } catch (e) {
      _log.severe('Error performing semantic search: $e');
      return [];
    }
  }

  // 6. TEXT-TO-SPEECH ENHANCEMENTS
  Future<Map<String, dynamic>> generateSpeechMarkers(String text, {String? voiceStyle, String? language}) async {
    try {
      final trimmedText = text.length > 1000 ? text.substring(0, 1000) : text;
      
      final prompt = '''
Enhance this text for text-to-speech by adding SSML markers or appropriate annotations.
${voiceStyle != null ? 'Use a $voiceStyle speaking style. ' : ''}
${language != null ? 'The text is in $language. ' : ''}

Instructions:
1. Add appropriate pauses (<break>) at natural sentence and paragraph breaks
2. Add emphasis (<emphasis>) for important words or phrases
3. Adjust prosody (<prosody>) for questions, exclamations, and emotional content
4. Add phonetic pronunciations (<phoneme>) for difficult words if needed
5. Mark dialog with different voices if present
6. Return a JSON object with these fields:
   - "ssml": Text with SSML tags
   - "markedText": Text with simple markers like [pause], [emphasis], etc.
   - "emotion": Overall emotion of the text
   - "pace": Suggested speaking pace (slow, medium, fast)

Text:
$trimmedText
''';

      final response = await _callGemini(prompt, usePro: true);
      if (response != null) {
        // Extract JSON from the response
        final pattern = RegExp(r'\{[\s\S]*\}');
        final match = pattern.firstMatch(response);
        if (match != null) {
          final jsonStr = match.group(0);
          if (jsonStr != null) {
            try {
              return Map<String, dynamic>.from(jsonDecode(jsonStr));
            } catch (e) {
              _log.warning('Error parsing JSON speech markers: $e');
            }
          }
        }
        
        // Fallback: return the raw response
        return {
          "ssml": response,
          "markedText": response,
          "emotion": "neutral",
          "pace": "medium"
        };
      }
      return {
        "ssml": text,
        "markedText": text,
        "emotion": "neutral",
        "pace": "medium"
      };
    } catch (e) {
      _log.severe('Error generating speech markers: $e');
      return {
        "ssml": text,
        "markedText": text,
        "emotion": "neutral",
        "pace": "medium"
      };
    }
  }

  // 7. VOCABULARY ASSISTANCE - Enhanced with examples and contextual relevance
  Future<List<Map<String, dynamic>>> explainDifficultWords(String text, {String? targetLanguage, String? difficulty = 'medium'}) async {
    try {
      final trimmedText = text.length > 2000 ? text.substring(0, 2000) : text;
      
      final prompt = '''
Analyze this text and identify difficult words, technical terms, or culturally specific concepts.
${targetLanguage != null ? 'Provide explanations in $targetLanguage. ' : ''}
${difficulty != null ? 'Target explanations for a $difficulty reading level. ' : ''}

Instructions:
1. Identify words that might be challenging based on frequency, complexity, domain-specificity
2. For each term, provide a clear, concise definition
3. Include a contextual example showing usage
4. Note cultural, historical, or domain-specific context if relevant
5. If the word appears in a specific context in the text, explain that specific usage

Return results as a JSON array where each object has:
- "term": The difficult word or phrase
- "definition": Simple, clear explanation
- "example": An example sentence showing usage
- "context": How it's used in the original text (if applicable)
- "partOfSpeech": Grammatical category (noun, verb, etc.)

Limit to 10-15 most important or challenging terms.

Text:
$trimmedText
''';

      final response = await _callGemini(prompt, usePro: true);
      if (response != null) {
        // Extract JSON from the response
        final pattern = RegExp(r'\[[\s\S]*\]');
        final match = pattern.firstMatch(response);
        if (match != null) {
          final jsonStr = match.group(0);
          if (jsonStr != null) {
            try {
              return List<Map<String, dynamic>>.from(jsonDecode(jsonStr));
            } catch (e) {
              _log.warning('Error parsing JSON vocabulary: $e');
              
              // Fallback: try to extract word/definition pairs
              final simplePattern = RegExp(r'\{[\s\S]*?\}');
              final matches = simplePattern.allMatches(response);
              
              List<Map<String, dynamic>> results = [];
              for (var match in matches) {
                try {
                  final obj = jsonDecode(match.group(0)!);
                  if (obj is Map && obj.containsKey('term') && obj.containsKey('definition')) {
                    results.add(Map<String, dynamic>.from(obj));
                  }
                } catch (_) {}
              }
              
              if (results.isNotEmpty) {
                return results;
              }
            }
          }
        }
        
        // Extreme fallback: try to parse word: definition format
        final wordDefPattern = RegExp(r'(["\w\s-]+)[":]?\s*[:-]\s*[""]?([^"\n]+)[""]?');
        final wordMatches = wordDefPattern.allMatches(response);
        
        List<Map<String, dynamic>> simpleResults = [];
        for (var match in wordMatches) {
          if (match.groupCount >= 2) {
            final term = match.group(1)?.trim().replaceAll(RegExp(r'[""]'), '') ?? '';
            final definition = match.group(2)?.trim().replaceAll(RegExp(r'[""]'), '') ?? '';
            if (term.isNotEmpty && definition.isNotEmpty) {
              simpleResults.add({
                "term": term,
                "definition": definition,
                "example": "",
                "partOfSpeech": ""
              });
            }
          }
        }
        
        return simpleResults;
      }
      return [];
    } catch (e) {
      _log.severe('Error explaining difficult words: $e');
      return [];
    }
  }
  
  // 8. THEME AND CONCEPT ANALYSIS (New)
  Future<Map<String, dynamic>> analyzeThemesAndConcepts(String text, {int maxLength = 5000}) async {
    try {
      final trimmedText = text.length > maxLength ? text.substring(0, maxLength) : text;
      
      final prompt = '''
Analyze this text for key themes, concepts, and literary elements.

Instructions:
1. Identify major themes and recurring motifs
2. Extract key concepts or ideas presented
3. Analyze tone, mood, and writing style
4. Identify literary devices used (metaphors, symbols, etc.)
5. Note any cultural, historical, or philosophical references

Return as a JSON object with:
- "majorThemes": Array of main themes with descriptions
- "concepts": Array of key concepts presented
- "tone": Overall tone/mood of the writing
- "style": Analysis of writing style
- "literaryDevices": Notable literary devices used
- "culturalReferences": Any significant cultural or historical references

Text:
$trimmedText
''';

      final response = await _callGemini(prompt, usePro: true);
      if (response != null) {
        // Extract JSON
        final pattern = RegExp(r'\{[\s\S]*\}');
        final match = pattern.firstMatch(response);
        if (match != null) {
          final jsonStr = match.group(0);
          if (jsonStr != null) {
            try {
              return Map<String, dynamic>.from(jsonDecode(jsonStr));
            } catch (e) {
              _log.warning('Error parsing JSON theme analysis: $e');
            }
          }
        }
        
        // Fallback
        return {
          "majorThemes": ["Theme analysis unavailable"],
          "concepts": ["Concept analysis unavailable"],
          "tone": "Analysis unavailable",
          "style": "Analysis unavailable"
        };
      }
      
      return {
        "majorThemes": ["Theme analysis unavailable"],
        "concepts": ["Concept analysis unavailable"],
        "tone": "Analysis unavailable",
        "style": "Analysis unavailable"
      };
    } catch (e) {
      _log.severe('Error analyzing themes and concepts: $e');
      return {
        "majorThemes": ["Error in theme analysis"],
        "concepts": ["Error in concept analysis"],
        "tone": "Analysis error",
        "style": "Analysis error"
      };
    }
  }
  
  // 9. READING SETTINGS RECOMMENDATION (New)
  Future<Map<String, dynamic>> recommendReadingSettings(String textSample, String language) async {
    try {
      final trimmedText = textSample.length > 1000 ? textSample.substring(0, 1000) : textSample;
      
      final prompt = '''
Analyze this text sample and recommend optimal reading settings.
The text language is: $language

Instructions:
1. Analyze text complexity, sentence length, and word difficulty
2. Determine optimal font size and style for readability
3. Recommend line spacing and margins
4. Suggest color schemes based on content type and language
5. Recommend text-to-speech settings if applicable

Return a JSON object with:
- "fontRecommendation": Recommended font family (specific to language if needed)
- "fontSize": Recommended size (small, medium, large)
- "lineSpacing": Optimal line spacing (1.0-2.0)
- "colorScheme": Suggested color theme (light, sepia, dark, etc.)
- "readingSpeed": Suggested reading speed if using TTS
- "textDirection": LTR or RTL
- "justification": Preferred text alignment
- "explanation": Brief explanation for recommendations

Text sample:
$trimmedText
''';

      final response = await _callGemini(prompt);
      if (response != null) {
        // Extract JSON
        final pattern = RegExp(r'\{[\s\S]*\}');
        final match = pattern.firstMatch(response);
        if (match != null) {
          final jsonStr = match.group(0);
          if (jsonStr != null) {
            try {
              return Map<String, dynamic>.from(jsonDecode(jsonStr));
            } catch (e) {
              _log.warning('Error parsing JSON reading settings: $e');
            }
          }
        }
        
        // Fallback with default settings
        return {
          "fontRecommendation": language == "Arabic" || language == "Urdu" ? "Amiri" : "Georgia",
          "fontSize": "medium",
          "lineSpacing": 1.5,
          "colorScheme": "sepia",
          "textDirection": language == "Arabic" || language == "Urdu" ? "RTL" : "LTR",
          "justification": "justified",
          "explanation": "Default settings based on language"
        };
      }
      
      // Defaults if AI failed
      return {
        "fontRecommendation": language == "Arabic" || language == "Urdu" ? "Amiri" : "Georgia",
        "fontSize": "medium",
        "lineSpacing": 1.5,
        "colorScheme": "sepia",
        "textDirection": language == "Arabic" || language == "Urdu" ? "RTL" : "LTR",
        "justification": "justified",
        "explanation": "Default settings based on language"
      };
    } catch (e) {
      _log.severe('Error recommending reading settings: $e');
      return {
        "fontRecommendation": language == "Arabic" || language == "Urdu" ? "Amiri" : "Georgia",
        "fontSize": "medium",
        "lineSpacing": 1.5,
        "colorScheme": "sepia",
        "textDirection": language == "Arabic" || language == "Urdu" ? "RTL" : "LTR",
        "justification": "justified",
        "explanation": "Default settings due to error"
      };
    }
  }
  
  // 10. SMART BOOKMARKING (New)
  Future<List<Map<String, dynamic>>> suggestBookmarks(String text, {int maxLength = 8000}) async {
    try {
      final trimmedText = text.length > maxLength ? text.substring(0, maxLength) : text;
      
      final prompt = '''
Analyze this text and identify the most important passages that would be good candidates for bookmarks.

Instructions:
1. Find key quotes, important facts, pivotal moments, or memorable passages
2. Identify the most insightful or profound statements
3. Locate passages that summarize main arguments or themes
4. Find definitions of important concepts
5. Identify passages that mark structural transitions

Return a JSON array where each object has:
- "text": The passage to bookmark (keep brief)
- "position": Approximate position in the text (percentage or paragraph number)
- "type": Category of bookmark (quote, fact, summary, definition, etc.)
- "importance": Rating from 1-5 indicating significance
- "note": Suggested note about why this passage is worth bookmarking

Limit to 5-7 most important passages.

Text:
$trimmedText
''';

      final response = await _callGemini(prompt, usePro: true);
      if (response != null) {
        // Extract JSON
        final pattern = RegExp(r'\[[\s\S]*\]');
        final match = pattern.firstMatch(response);
        if (match != null) {
          final jsonStr = match.group(0);
          if (jsonStr != null) {
            try {
              return List<Map<String, dynamic>>.from(jsonDecode(jsonStr));
            } catch (e) {
              _log.warning('Error parsing JSON bookmarks: $e');
            }
          }
        }
        
        // Fallback: Try to extract quotes or notable lines
        final lines = response.split('\n');
        List<Map<String, dynamic>> results = [];
        
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.startsWith('"') && line.endsWith('"')) {
            results.add({
              "text": line.replaceAll(RegExp(r'^"|"$'), ''),
              "position": "unknown",
              "type": "quote",
              "importance": 3,
              "note": "Notable passage"
            });
          }
        }
        
        if (results.isNotEmpty) {
          return results.take(5).toList();
        }
      }
      
      return [];
    } catch (e) {
      _log.severe('Error suggesting bookmarks: $e');
      return [];
    }
  }
}

// ---- Update Riverpod Provider ----

// Provider for the GeminiService
final geminiServiceProvider = Provider<GeminiService>((ref) {
  // You might fetch the API key securely here instead of hardcoding
  final apiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'YOUR_API_KEY_HERE');
  // Ensure the API key is available
  if (apiKey == 'YOUR_API_KEY_HERE') {
    throw Exception('Please provide your Gemini API key via --dart-define=GEMINI_API_KEY=YOUR_API_KEY');
  }

  final model = GenerativeModel(model: 'gemini-1.5-pro', apiKey: apiKey);
  
  // Pass the model and apiKey to the constructor
  return GeminiService(model, apiKey);
}); 