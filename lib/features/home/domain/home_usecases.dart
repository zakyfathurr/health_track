import '../data/quotes_repository.dart';
import '../data/weather_repository.dart';
import 'quote.dart';
import 'weather.dart';

/// DOMAIN layer untuk dashboard home.

class GetWeatherUseCase {
  final WeatherRepository _repo;
  GetWeatherUseCase([WeatherRepository? repo])
    : _repo = repo ?? WeatherRepository();

  Future<WeatherData> call([String? city]) => _repo.fetchWeather(city);
}

class GetTodayQuoteUseCase {
  final QuotesRepository _repo;
  GetTodayQuoteUseCase([QuotesRepository? repo])
    : _repo = repo ?? QuotesRepository();

  Future<QuoteData> call() => _repo.fetchTodayQuote();
}

/// Pure business logic — rekomendasi kesehatan berdasarkan cuaca (DOMAIN).
String healthRecommendation(WeatherData weather) {
  final temp = weather.temperature;
  final condition = weather.condition.toLowerCase();

  if (condition.contains('rain') || condition.contains('hujan')) {
    return 'Hari ini hujan, indoor workout lebih direkomendasikan.';
  }
  if (temp > 33) {
    return 'Cuaca hari ini panas, jangan lupa minum lebih banyak air.';
  }
  if (temp < 20) {
    return 'Cuaca sejuk, cocok untuk jogging pagi hari!';
  }
  return 'Cuaca mendukung untuk aktivitas fisik di luar ruangan.';
}
