/// Configuration file containing curated collections of book identifiers
/// from the Internet Archive, based on recommendations from the comprehensive guide.
/// 
/// This file provides lists of identifiers for high-quality, reliable copies of 
/// Maulana Maududi's works in multiple languages.
class BookCollections {
  // Collection of featured books that should be highlighted in the app
  // These are high-quality, well-scanned copies with good OCR
  static const List<String> featuredBooks = [
    // English Books
    'fundamentals-of-islam',           // Fundamentals of Islam
    'towards-understanding-islam',     // Towards Understanding Islam 
    'tafhimul-quran-english',          // Tafhimul Quran (English)
    'let-us-be-muslims',               // Let Us Be Muslims
    'islamic-way-of-life',             // Islamic Way of Life
    'human-rights-in-islam',           // Human Rights in Islam
    'four-basic-quranic-terms',        // Four Basic Quranic Terms
    'first-principles-of-islamic-economics', // First Principles of Islamic Economics
    'witness-to-mankind',              // Witness to Mankind
    'islamic-law-and-constitution',    // Islamic Law and Constitution
    'purdah-status-women-islam',       // Purdah and Status of Women in Islam
    'al-jihad-fil-islam',              // Jihad in Islam
    'economic-system-of-islam',        // Economic System of Islam
    'islamic-state',                   // Islamic State
    'problems-of-nationalism',         // Problems of Nationalism
    'rights-of-spouses',               // Rights of Spouses
    'interest',                        // Interest (Sood)
    'islam-and-ignorance',             // Islam and Ignorance
    'moral-foundations-islamic-movement', // Moral Foundations of Islamic Movement
    'life-after-death',                // Life After Death
    
    // Urdu Books
    'tafhimulquranurduvol1',          // Tafhimul Quran Vol 1 (Urdu)
    'TafhimulQuranVol2',              // Tafhimul Quran Vol 2 (Urdu)
    'TafhimulQuranVol3',              // Tafhimul Quran Vol 3 (Urdu)
    'TafhimulQuranVol4',              // Tafhimul Quran Vol 4 (Urdu)
    'TafhimulQuranVol5',              // Tafhimul Quran Vol 5 (Urdu)
    'TafhimulQuranVol6',              // Tafhimul Quran Vol 6 (Urdu)
    'khutbat-e-maududi',              // Khutbat-e-Maududi
    'deenyat',                        // Deenyat
    'islamic-riyasat',                // Islamic Riyasat
    'khilafat-o-mulukiat',            // Khilafat-o-Mulukiat
    'huquq-uz-zaujain',               // Rights of Spouses (Urdu)
    'sood-urdu',                      // Interest (Urdu)
    'seerat-sarwar-e-alam',           // Biography of the Prophet (Urdu)
    'tehreek-e-islami-ki-akhlaqi-bunyaadein', // Moral Foundations (Urdu)
    'zindagi-bad-maut',               // Life After Death (Urdu)
    'khutbat-e-europe',               // Lectures in Europe (Urdu)
    'rasail-o-masail',                // Essays and Issues (Urdu)
    'tafheemat',                      // Understandings (Urdu)
    'banao-aur-bigarh',               // Making and Marring (Urdu)

    // Arabic Books
    'mabadayeulislam',                // Mabade-ul-Islam (Arabic)
    'al-mustalahat-al-arbaa',         // Al-Mustalahat Al-Arbaa (Four Basic Terms in Arabic)
    'al-jihad-fi-sabilillah',         // Al-Jihad Fi Sabilillah
    'nahnu-wa-al-hadarah-al-gharbiyyah', // Nahnu wa al-Hadarah al-Gharbiyyah
    'al-islam-wa-al-jahiliyyah',      // Al-Islam wa al-Jahiliyyah
    'al-hukumat-al-islamiyyah',       // Islamic Government (Arabic)
    'al-qanun-al-islami',             // Islamic Law (Arabic)
    'huquq-ahl-al-dhimmah',           // Rights of Non-Muslims (Arabic)
    'al-hijab',                       // Hijab (Arabic)
    'tafsir-surat-al-nur',            // Tafsir of Surah Al-Nur (Arabic)
  ];

  // Collection of recommended Tafsir books
  static const List<String> tafsirBooks = [
    'tafhimul-quran-english',         // English Tafsir
    'tafhimulquranurduvol1',          // Urdu Tafsir Vol 1
    'TafhimulQuranVol2',              // Urdu Tafsir Vol 2
    'TafhimulQuranVol3',              // Urdu Tafsir Vol 3
    'TafhimulQuranVol4',              // Urdu Tafsir Vol 4
    'TafhimulQuranVol5',              // Urdu Tafsir Vol 5
    'TafhimulQuranVol6',              // Urdu Tafsir Vol 6
    'tafsir-surat-al-fatiha',         // Tafsir of Surah Al-Fatiha
    'tafsir-surat-al-baqarah',        // Tafsir of Surah Al-Baqarah
    'tafsir-surat-al-nur',            // Tafsir of Surah Al-Nur
  ];

  // Recommended books on Islamic Law
  static const List<String> islamicLawBooks = [
    'islamic-law-and-constitution',   // Islamic Law and Constitution
    'huquq-al-zawjain',               // Rights of Spouses
    'qanun-e-shahadat',               // Law of Evidence
    'first-principles-of-islamic-economics', // Islamic Economics
    'al-qanun-al-islami',             // Islamic Law (Arabic)
    'huquq-ahl-al-dhimmah',           // Rights of Non-Muslims
  ];

  // Recommended books on Political Thought
  static const List<String> politicalThoughtBooks = [
    'islamic-riyasat',                // Islamic State
    'khilafat-o-mulukiat',            // Caliphate and Monarchy
    'islamic-system-of-government',   // Islamic System of Government
    'economic-system-of-islam',       // Economic System of Islam
    'problems-of-nationalism',        // Problems of Nationalism
    'al-hukumat-al-islamiyyah',       // Islamic Government (Arabic)
  ];

  // Books with highest quality OCR (helpful for search & text selection)
  static const List<String> highQualityOcrBooks = [
    'towards-understanding-islam',    // High-quality OCR scan
    'fundamentals-of-islam',          // High-quality OCR scan
    'let-us-be-muslims',              // High-quality OCR scan
    'islamic-way-of-life',            // High-quality OCR scan
    'human-rights-in-islam',          // High-quality OCR scan
    'four-basic-quranic-terms',       // High-quality OCR scan
  ];

  // Create map of books by category ID for easy lookup
  static final Map<String, List<String>> booksByCategory = {
    'tafsir': tafsirBooks,
    'islamic_law': islamicLawBooks,
    'political_thought': politicalThoughtBooks,
  };

  // Helper method to get identifiers by category
  static List<String> getBooksByCategory(String categoryId) {
    return booksByCategory[categoryId] ?? [];
  }
} 