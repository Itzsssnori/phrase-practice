import 'package:material_ui/material_ui.dart';
import '../models/category.dart';
import '../models/language.dart';
import '../models/phrase.dart';
import '../models/quiz.dart';
import '../models/user_progress.dart';

/// PLACEHOLDER SERVICE: Stage 1 sample hardcoded data for UI layouts.
/// No backend, AI calls, or network requests are included.
class MockDataService {
  MockDataService._();

  // Supported languages list (Placeholder)
  static const List<Language> sampleLanguages = [
    Language(code: 'en', name: 'English', nativeName: 'English', flag: '🇬🇧'),
    Language(code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
    Language(code: 'ja', name: 'Japanese', nativeName: '日本語', flag: '🇯🇵'),
    Language(code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷'),
    Language(code: 'de', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪'),
    Language(code: 'it', name: 'Italian', nativeName: 'Italiano', flag: '🇮🇹'),
    Language(code: 'ko', name: 'Korean', nativeName: '한국어', flag: '🇰🇷'),
  ];

  // Sample Categories (Placeholder)
  static const List<Category> sampleCategories = [
    Category(
      id: 'travel',
      title: 'Travel & Transport',
      description: 'Navigating stations, airports, tickets, and directions',
      icon: Icons.flight_takeoff_rounded,
      phraseCount: 42,
      progress: 0.65,
    ),
    Category(
      id: 'dining',
      title: 'Dining & Cafes',
      description: 'Ordering food, drinks, asking for recommendations and the bill',
      icon: Icons.restaurant_rounded,
      phraseCount: 38,
      progress: 0.40,
    ),
    Category(
      id: 'daily',
      title: 'Daily Essentials',
      description: 'Greetings, polite expressions, introducing yourself',
      icon: Icons.chat_bubble_outline_rounded,
      phraseCount: 56,
      progress: 0.85,
    ),
    Category(
      id: 'emergency',
      title: 'Emergency & Help',
      description: 'Pharmacy, medical needs, asking for urgent assistance',
      icon: Icons.health_and_safety_outlined,
      phraseCount: 24,
      progress: 0.15,
    ),
    Category(
      id: 'shopping',
      title: 'Shopping & Markets',
      description: 'Prices, sizing, bargaining, and payment methods',
      icon: Icons.shopping_bag_outlined,
      phraseCount: 30,
      progress: 0.20,
    ),
  ];

  // Sample Phrases (Placeholder)
  static const List<Phrase> samplePhrases = [
    Phrase(
      id: 'p1',
      originalText: '¿Dónde está la estación de tren más cercana?',
      translatedText: 'Where is the nearest train station?',
      phonetic: 'DON-deh es-TAH lah es-tah-SYON deh tren mahs ser-KAH-nah',
      contextNote: 'Use when asking pedestrians or station officers for directions.',
      categoryId: 'travel',
      isFavorite: true,
    ),
    Phrase(
      id: 'p2',
      originalText: 'La cuenta, por favor.',
      translatedText: 'The check, please.',
      phonetic: 'lah KWEN-tah, por fah-VOR',
      contextNote: 'Polite phrase to ask waitstaff for the bill at a restaurant.',
      categoryId: 'dining',
      isFavorite: true,
    ),
    Phrase(
      id: 'p3',
      originalText: 'Mucho gusto en conocerte.',
      translatedText: 'Nice to meet you.',
      phonetic: 'MOO-choh GOOS-toh en koh-noh-SEHR-teh',
      contextNote: 'Standard warm greeting when meeting someone for the first time.',
      categoryId: 'daily',
      isFavorite: false,
    ),
    Phrase(
      id: 'p4',
      originalText: '¿Tiene esto en otra talla o color?',
      translatedText: 'Do you have this in another size or color?',
      phonetic: 'TYEH-neh EHS-toh en OH-trah TAH-yah oh koh-LOR',
      contextNote: 'Helpful in clothing shops and department stores.',
      categoryId: 'shopping',
      isFavorite: false,
    ),
    Phrase(
      id: 'p5',
      originalText: 'Necesito ver a un médico inmediatamente.',
      translatedText: 'I need to see a doctor immediately.',
      phonetic: 'neh-seh-SEE-toh vehr ah oon MEH-dee-koh een-meh-dyah-tah-MEN-teh',
      contextNote: 'Emergency phrase for health facilities or seeking aid.',
      categoryId: 'emergency',
      isFavorite: true,
    ),
  ];

  // Sample User Progress (Placeholder)
  static const UserProgress sampleProgress = UserProgress(
    phrasesLearned: 142,
    totalPhrases: 320,
    currentStreakDays: 12,
    totalQuizzesTaken: 18,
    averageAccuracy: 88.5,
  );

  // Sample Quiz Question List (Placeholder)
  static const List<QuizQuestion> sampleQuestions = [
    QuizQuestion(
      id: 'q1',
      prompt: 'Select the correct translation:',
      originalPhrase: '¿Dónde está la estación de tren más cercana?',
      options: [
        'Where can I buy a train ticket?',
        'Where is the nearest train station?',
        'What time does the last train depart?',
        'Is the train running on schedule?',
      ],
      correctIndex: 1,
      explanation: '"¿Dónde está...?" means "Where is...?" and "la estación de tren más cercana" refers to the nearest train station.',
    ),
    QuizQuestion(
      id: 'q2',
      prompt: 'What does this polite dining phrase mean?',
      originalPhrase: 'La cuenta, por favor.',
      options: [
        'Could we see the menu?',
        'Another glass of water, please.',
        'The check, please.',
        'Can we reserve a table?',
      ],
      correctIndex: 2,
      explanation: '"La cuenta" specifically translates to the check or bill at a dining venue.',
    ),
    QuizQuestion(
      id: 'q3',
      prompt: 'Choose the appropriate meaning:',
      originalPhrase: 'Mucho gusto en conocerte.',
      options: [
        'Have a pleasant journey.',
        'Nice to meet you.',
        'See you again tomorrow.',
        'Thank you very much.',
      ],
      correctIndex: 1,
      explanation: '"Mucho gusto" is a polite expression of pleasure upon meeting someone.',
    ),
  ];
}
