// IMPORTANT: The project lead must review and approve this privacy text
// before any public release.

/// Single place for all user-facing Privacy screen text so it is easy to edit.
class PrivacySection {
  final String title;
  final String body;
  final List<String> bullets;

  const PrivacySection({
    required this.title,
    required this.body,
    this.bullets = const [],
  });
}

class PrivacyCopy {
  PrivacyCopy._();

  static const String screenTitle = 'Privacy';
  static const String introTitle = 'How Phrase Practice handles your data';
  static const String introBody =
      'We keep data collection simple and store only what is needed for your study experience.';

  static const List<PrivacySection> sections = [
    PrivacySection(
      title: 'What we store when you create an account',
      body: 'If you sign in, the following information is saved to your account:',
      bullets: [
        'Your email address and display name',
        'Your language choices (the language you speak and the language you are learning)',
        'Phrases you mark as favorites',
        'Phrases you mark as learned',
        'Phrases you have recently studied',
        'Your quiz attempts (scores, categories, and answers)',
      ],
    ),
    PrivacySection(
      title: 'Where your data is stored',
      body:
          'Your account and study data are stored using Firebase, a service provided by Google. Your saved data is private to your account.',
    ),
    PrivacySection(
      title: 'What stays on your device only',
      body:
          'If you use the app as a guest, nothing is saved to an account. Display settings such as theme mode, study text size, and recall mode are stored only on your device. Pronunciation audio is produced by your device\'s or browser\'s built-in speech engine, and depending on the browser the text may be processed by its provider.',
    ),
    PrivacySection(
      title: 'How to delete your data',
      body:
          'You can delete your account and all saved data at any time from Settings & Profile by choosing "Delete Account". After you confirm your password, all of your saved phrases, quiz attempts, profile details, and account login are permanently deleted.',
    ),
  ];
}
