class WeatherData {
  final String city;
  final double temperature;
  final String condition;
  final int humidity;
  final String icon;

  const WeatherData({
    required this.city,
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.icon,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) => WeatherData(
    city: json['name'] as String,
    temperature: (json['main']['temp'] as num).toDouble(),
    condition: (json['weather'] as List).first['description'] as String,
    humidity: json['main']['humidity'] as int,
    icon: (json['weather'] as List).first['icon'] as String,
  );
}
