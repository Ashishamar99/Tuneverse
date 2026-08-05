class AppConstants {
  AppConstants._();

  static const Duration streamCacheDuration = Duration(hours: 6);

  static const int maxConcurrentDownloads = 3;

  static const String defaultProfileName = 'Default';
  static const String defaultProfileEmoji = '🎵';
  static const int maxProfileCount = 6;

  static const Duration searchDebounceDuration = Duration(milliseconds: 300);

  static const int youtubeSearchResultsLimit = 20;

  // Rejects files that are effectively empty or header-only (cover art stored
  // as an audio file, partial downloads, etc.).
  static const int minAudioFileSizeBytes = 100 * 1024;

  // Rejects alert sounds, notification tones, and short sound effects that
  // would pollute the library scan.
  static const int minAudioDurationSeconds = 10;

  static const List<String> supportedAudioExtensions = [
    '.mp3',
    '.flac',
    '.aac',
    '.m4a',
    '.opus',
    '.ogg',
    '.wav',
    '.wma',
    '.alac',
  ];
}
