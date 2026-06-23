import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App-wide constants.
///
/// This file IS committed (with no secret) so the project compiles for every
/// teammate after `git clone`. Do NOT gitignore it.
///
/// The real OpenWeather key lives in `.env` (gitignored). Copy `.env.example`
/// to `.env` and fill it in. `.env` is loaded in `main()` before `runApp()`.
class AppConstants {

  static String get openWeatherApiKey {
    final fromDotenv =
    dotenv.isInitialized ? dotenv.env['OPENWEATHER_API_KEY'] : null;
    if (fromDotenv != null && fromDotenv.isNotEmpty) return fromDotenv;
    return _dartDefineKey;
  }

  static const String _dartDefineKey = String.fromEnvironment(
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
