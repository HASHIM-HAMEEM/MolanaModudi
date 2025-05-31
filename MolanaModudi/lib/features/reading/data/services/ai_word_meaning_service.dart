import 'dart:async';
import 'package:logging/logging.dart';

/// AI-powered word meaning and translation service
class AiWordMeaningService {
  static final _log = Logger('AiWordMeaningService');
  
  /// Get meaning and details for a selected word or phrase
  Future<WordMeaningResult> getWordMeaning(String selectedText) async {
    try {
      // Clean the input text
      final cleanText = _cleanText(selectedText);
      
      if (cleanText.isEmpty) {
        return WordMeaningResult.empty();
      }
      
      // Detect language and get appropriate meaning
      final isArabicUrdu = _isArabicOrUrdu(cleanText);
      
      if (isArabicUrdu) {
        return await _getArabicUrduMeaning(cleanText);
      } else {
        return await _getEnglishMeaning(cleanText);
      }
    } catch (e) {
      _log.warning('Error getting word meaning: $e');
      return WordMeaningResult.error('Unable to get meaning for this text');
    }
  }
  
  /// Get meaning for Arabic/Urdu text
  Future<WordMeaningResult> _getArabicUrduMeaning(String text) async {
    // In real implementation, this would call an AI service
    // For now, we'll use a comprehensive mock database
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
    
    final meaning = _getUrduArabicMockMeaning(text);
    if (meaning != null) {
      return meaning;
    }
    
    // Fallback for unknown words
    return WordMeaningResult(
      word: text,
      language: 'Urdu/Arabic',
      primaryMeaning: 'This is an Islamic term from the writings of Maulana Maududi.',
      secondaryMeaning: 'Please refer to the complete context for full understanding.',
      examples: [
        'Used frequently in Islamic scholarly texts',
        'Part of Maududi\'s comprehensive Islamic terminology',
      ],
      etymology: 'From classical Arabic/Urdu Islamic literature',
      relatedWords: ['Related Islamic concepts may include similar terminology'],
      partOfSpeech: 'Islamic term',
    );
  }
  
  /// Get meaning for English text
  Future<WordMeaningResult> _getEnglishMeaning(String text) async {
    await Future.delayed(const Duration(milliseconds: 400)); // Simulate API call
    
    final meaning = _getEnglishMockMeaning(text);
    if (meaning != null) {
      return meaning;
    }
    
    // Fallback for unknown words
    return WordMeaningResult(
      word: text,
      language: 'English',
      primaryMeaning: 'A concept discussed in Maulana Maududi\'s Islamic writings.',
      secondaryMeaning: 'Refers to principles within the Islamic intellectual framework.',
      examples: [
        'Used in the context of Islamic scholarship',
        'Part of comprehensive Islamic terminology',
      ],
      etymology: 'From Islamic scholarly tradition',
      relatedWords: ['Related concepts in Islamic thought'],
      partOfSpeech: 'Noun/Concept',
    );
  }
  
  /// Mock database for Urdu/Arabic words commonly found in Maududi's works
  WordMeaningResult? _getUrduArabicMockMeaning(String text) {
    final meanings = <String, WordMeaningResult>{
      'اسلام': WordMeaningResult(
        word: 'اسلام',
        language: 'Arabic',
        primaryMeaning: 'Submission to Allah; Peace',
        secondaryMeaning: 'The complete way of life ordained by Allah',
        examples: [
          'اسلام ایک مکمل نظام زندگی ہے',
          'Islam is a complete system of life',
        ],
        etymology: 'From Arabic root س-ل-م (peace, submission)',
        relatedWords: ['مسلم', 'سلام', 'استسلام'],
        partOfSpeech: 'Noun (feminine)',
      ),
      
      'اللہ': WordMeaningResult(
        word: 'اللہ',
        language: 'Arabic',
        primaryMeaning: 'Allah - The One True God',
        secondaryMeaning: 'The Creator and Sustainer of the universe',
        examples: [
          'اللہ تعالیٰ کی عبادت کرو',
          'Worship Allah the Almighty',
        ],
        etymology: 'The proper name of God in Arabic',
        relatedWords: ['رب', 'خدا', 'الرحمن'],
        partOfSpeech: 'Proper Noun',
      ),
      
      'قرآن': WordMeaningResult(
        word: 'قرآن',
        language: 'Arabic',
        primaryMeaning: 'The Holy Quran - Word of Allah',
        secondaryMeaning: 'The final revelation sent to Prophet Muhammad (PBUH)',
        examples: [
          'قرآن مجید اللہ کا کلام ہے',
          'The Holy Quran is the word of Allah',
        ],
        etymology: 'From Arabic قرأ meaning "to read"',
        relatedWords: ['کتاب', 'وحی', 'تنزیل'],
        partOfSpeech: 'Noun (masculine)',
      ),
      
      'جہاد': WordMeaningResult(
        word: 'جہاد',
        language: 'Arabic',
        primaryMeaning: 'Struggle/Striving in the path of Allah',
        secondaryMeaning: 'Personal and collective effort to establish Islamic values',
        examples: [
          'جہاد فی سبیل اللہ',
          'Striving in the way of Allah',
        ],
        etymology: 'From Arabic root ج-ہ-د (to strive, struggle)',
        relatedWords: ['مجاہد', 'اجتہاد', 'جدوجہد'],
        partOfSpeech: 'Noun (masculine)',
      ),
      
      'نظام': WordMeaningResult(
        word: 'نظام',
        language: 'Arabic/Urdu',
        primaryMeaning: 'System; Order; Organization',
        secondaryMeaning: 'A comprehensive framework of principles and practices',
        examples: [
          'اسلامی نظام زندگی',
          'Islamic system of life',
        ],
        etymology: 'From Arabic نظم meaning order/arrangement',
        relatedWords: ['ترتیب', 'قانون', 'ضابطہ'],
        partOfSpeech: 'Noun (masculine)',
      ),
      
      'تعلیم': WordMeaningResult(
        word: 'تعلیم',
        language: 'Arabic/Urdu',
        primaryMeaning: 'Education; Teaching; Learning',
        secondaryMeaning: 'The process of acquiring knowledge and moral training',
        examples: [
          'اسلامی تعلیم کی اہمیت',
          'The importance of Islamic education',
        ],
        etymology: 'From Arabic علم (knowledge)',
        relatedWords: ['علم', 'تربیت', 'درس'],
        partOfSpeech: 'Noun (feminine)',
      ),
      
      'خلافت': WordMeaningResult(
        word: 'خلافت',
        language: 'Arabic',
        primaryMeaning: 'Caliphate; Islamic leadership',
        secondaryMeaning: 'The institution of Islamic governance',
        examples: [
          'خلافت راشدہ کا دور',
          'The era of Rightly-Guided Caliphate',
        ],
        etymology: 'From Arabic خلف meaning succession',
        relatedWords: ['خلیفہ', 'امامت', 'حکومت'],
        partOfSpeech: 'Noun (feminine)',
      ),
    };
    
    // Try exact match first
    if (meanings.containsKey(text.trim())) {
      return meanings[text.trim()];
    }
    
    // Try partial matches for compound words
    for (final key in meanings.keys) {
      if (text.contains(key) || key.contains(text)) {
        return meanings[key];
      }
    }
    
    return null;
  }
  
  /// Mock database for English words
  WordMeaningResult? _getEnglishMockMeaning(String text) {
    final word = text.toLowerCase().trim();
    
    final meanings = <String, WordMeaningResult>{
      'islam': WordMeaningResult(
        word: 'Islam',
        language: 'English',
        primaryMeaning: 'The religion of Muslims; submission to Allah',
        secondaryMeaning: 'A complete way of life based on the Quran and Sunnah',
        examples: [
          'Islam provides guidance for all aspects of life',
          'Maududi wrote extensively about Islam as a comprehensive system',
        ],
        etymology: 'From Arabic islām, meaning submission',
        relatedWords: ['Muslim', 'Islamic', 'Submission'],
        partOfSpeech: 'Noun',
      ),
      
      'jihad': WordMeaningResult(
        word: 'Jihad',
        language: 'English',
        primaryMeaning: 'Striving or struggling in the way of Allah',
        secondaryMeaning: 'Personal and collective effort to establish Islamic values',
        examples: [
          'Maududi emphasized the importance of intellectual jihad',
          'Jihad includes both inner struggle and external effort',
        ],
        etymology: 'From Arabic jihād, from root j-h-d (to strive)',
        relatedWords: ['Struggle', 'Effort', 'Striving'],
        partOfSpeech: 'Noun',
      ),
      
      'caliphate': WordMeaningResult(
        word: 'Caliphate',
        language: 'English',
        primaryMeaning: 'Islamic form of government led by a Caliph',
        secondaryMeaning: 'The institution representing Islamic leadership',
        examples: [
          'Maududi wrote about the ideal Islamic caliphate',
          'The caliphate system in early Islamic history',
        ],
        etymology: 'From Arabic khilāfah, meaning succession',
        relatedWords: ['Caliph', 'Leadership', 'Government'],
        partOfSpeech: 'Noun',
      ),
      
      'system': WordMeaningResult(
        word: 'System',
        language: 'English',
        primaryMeaning: 'An organized framework of principles and practices',
        secondaryMeaning: 'In Islamic context: comprehensive life guidance',
        examples: [
          'The Islamic system encompasses all aspects of life',
          'Maududi advocated for implementing the Islamic system',
        ],
        etymology: 'From Greek systēma, meaning organized whole',
        relatedWords: ['Framework', 'Organization', 'Structure'],
        partOfSpeech: 'Noun',
      ),
      
      'education': WordMeaningResult(
        word: 'Education',
        language: 'English',
        primaryMeaning: 'The process of acquiring knowledge and skills',
        secondaryMeaning: 'In Islamic context: holistic development including spiritual training',
        examples: [
          'Islamic education integrates worldly and religious knowledge',
          'Maududi emphasized character building through education',
        ],
        etymology: 'From Latin educatio, meaning bringing up',
        relatedWords: ['Learning', 'Teaching', 'Training'],
        partOfSpeech: 'Noun',
      ),
    };
    
    return meanings[word];
  }
  
  /// Clean text for processing
  String _cleanText(String text) {
    // Remove extra whitespace and common punctuation using a simpler approach
    String cleaned = text.trim();
    
    // Remove common punctuation characters one by one
    cleaned = cleaned.replaceAll('۔', '');  // Urdu full stop
    cleaned = cleaned.replaceAll('.', '');
    cleaned = cleaned.replaceAll(',', '');
    cleaned = cleaned.replaceAll('!', '');
    cleaned = cleaned.replaceAll('?', '');
    cleaned = cleaned.replaceAll(':', '');
    cleaned = cleaned.replaceAll(';', '');
    cleaned = cleaned.replaceAll('"', '');
    cleaned = cleaned.replaceAll("'", '');
    cleaned = cleaned.replaceAll('(', '');
    cleaned = cleaned.replaceAll(')', '');
    cleaned = cleaned.replaceAll('[', '');
    cleaned = cleaned.replaceAll(']', '');
    
    // Remove multiple spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    
    return cleaned.trim();
  }
  
  /// Detect if text is Arabic or Urdu
  bool _isArabicOrUrdu(String text) {
    // Check for Arabic/Urdu Unicode ranges
    final arabicUrduPattern = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
    return arabicUrduPattern.hasMatch(text);
  }
}

/// Result class for word meaning lookup
class WordMeaningResult {
  final String word;
  final String language;
  final String primaryMeaning;
  final String secondaryMeaning;
  final List<String> examples;
  final String etymology;
  final List<String> relatedWords;
  final String partOfSpeech;
  final bool hasError;
  final String? errorMessage;
  
  const WordMeaningResult({
    required this.word,
    required this.language,
    required this.primaryMeaning,
    required this.secondaryMeaning,
    required this.examples,
    required this.etymology,
    required this.relatedWords,
    required this.partOfSpeech,
    this.hasError = false,
    this.errorMessage,
  });
  
  factory WordMeaningResult.empty() {
    return const WordMeaningResult(
      word: '',
      language: '',
      primaryMeaning: 'No meaning found',
      secondaryMeaning: 'Please try selecting a single word',
      examples: [],
      etymology: '',
      relatedWords: [],
      partOfSpeech: '',
      hasError: true,
      errorMessage: 'No text selected',
    );
  }
  
  factory WordMeaningResult.error(String message) {
    return WordMeaningResult(
      word: '',
      language: '',
      primaryMeaning: 'Error',
      secondaryMeaning: message,
      examples: [],
      etymology: '',
      relatedWords: [],
      partOfSpeech: '',
      hasError: true,
      errorMessage: message,
    );
  }
} 