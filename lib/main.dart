import 'package:flutter/material.dart';
import 'screens/weather_page.dart';

void main() => runApp(const ClimaApp());

class ClimaApp extends StatelessWidget {
  const ClimaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Clima',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF167697)),
      scaffoldBackgroundColor: const Color(0xFFF0F6F8),
    ),
    home: const WeatherPage(),
  );
}
