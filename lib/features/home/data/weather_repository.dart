import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';
import '../domain/weather.dart';

/// DATA layer: ambil cuaca dari OpenWeather.
class WeatherRepository {
  static const _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<WeatherData> fetchWeather([String? city]) async {
    final target = city ?? AppConstants.defaultCity;
    final uri = Uri.parse(
      '$_baseUrl?q=$target&appid=${AppConstants.openWeatherApiKey}'
      '&units=metric&lang=id',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil cuaca: ${response.statusCode}');
    }
    return WeatherData.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
