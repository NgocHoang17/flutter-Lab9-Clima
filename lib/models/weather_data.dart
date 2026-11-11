import 'package:flutter/material.dart';

class WeatherData {
  const WeatherData({
    required this.city,
    required this.country,
    required this.temperature,
    required this.description,
    required this.conditionId,
    required this.isNight,
    required this.humidity,
    required this.windSpeed,
    required this.feelsLike,
  });
  final String city, country, description;
  final double temperature, humidity, windSpeed, feelsLike;
  final int conditionId;
  final bool isNight;

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'];
    final weather = json['weather'];
    final wind = json['wind'];
    final sys = json['sys'];
    if (main is! Map<String, dynamic> ||
        wind is! Map<String, dynamic> ||
        weather is! List ||
        weather.isEmpty ||
        weather.first is! Map<String, dynamic> ||
        json['name'] is! String ||
        (json['name'] as String).trim().isEmpty) {
      throw const FormatException('Missing weather data');
    }
    final condition = weather.first as Map<String, dynamic>;
    if (condition['description'] is! String ||
        condition['id'] is! num ||
        (condition['icon'] != null && condition['icon'] is! String)) {
      throw const FormatException();
    }
    double number(dynamic value) {
      if (value is! num || !value.isFinite) throw const FormatException();
      return value.toDouble();
    }

    return WeatherData(
      city: json['name'] as String,
      country: sys is Map<String, dynamic> && sys['country'] is String
          ? sys['country'] as String
          : '',
      temperature: number(main['temp']),
      feelsLike: number(main['feels_like']),
      humidity: number(main['humidity']),
      windSpeed: number(wind['speed']),
      description: condition['description'] as String,
      conditionId: number(condition['id']).toInt(),
      isNight: (condition['icon'] as String? ?? '').endsWith('n'),
    );
  }

  IconData get icon {
    if (conditionId >= 200 && conditionId < 300) return Icons.thunderstorm;
    if (conditionId >= 300 && conditionId < 600) return Icons.water_drop;
    if (conditionId >= 600 && conditionId < 700) return Icons.ac_unit;
    if (conditionId >= 700 && conditionId < 800) return Icons.foggy;
    if (conditionId == 800) {
      return isNight ? Icons.nightlight_round : Icons.wb_sunny_rounded;
    }
    return Icons.cloud_rounded;
  }

  List<Color> get backgroundColors {
    if (isNight) return const [Color(0xFF142A49), Color(0xFF354268)];
    if (conditionId < 600) return const [Color(0xFF264F65), Color(0xFF577481)];
    return const [Color(0xFF096D95), Color(0xFF4D9FB3)];
  }
}
