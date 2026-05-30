/// App-wide constants.
///
/// This file IS committed (with a placeholder key) so the project compiles for
/// every teammate after `git clone`. Do NOT gitignore it.
///
/// For the real OpenWeather key, prefer not committing it. Two options:
///   1) Replace the placeholder locally and avoid committing that change, or
///   2) Pass it at run time and read via String.fromEnvironment:
///        flutter run --dart-define=OPENWEATHER_API_KEY=xxxxx
class AppConstants {
  /// OpenWeather API key. Falls back to --dart-define if provided, otherwise
  /// the placeholder below (which will make weather calls fail with 401 until set).
  static const String openWeatherApiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
    defaultValue: 'YOUR_API_KEY_HERE',
  );

  static const String defaultCity = 'Surabaya';

  // Firestore collection names — use these instead of raw strings.
  static const String usersCollection = 'users';
  static const String moodsCollection = 'moods';
  static const String workoutsCollection = 'workouts';
  static const String goalsCollection = 'goals';
}
