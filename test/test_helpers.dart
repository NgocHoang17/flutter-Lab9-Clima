import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lab09_clima/services/location.dart';
import 'package:lab09_clima/services/weather_exception.dart';

Map<String, dynamic> weatherJson({
  String city = 'Hanoi',
  double temp = 26.5,
  int condition = 800,
  String icon = '01d',
}) => {
  'name': city,
  'sys': {'country': 'VN'},
  'main': {'temp': temp, 'feels_like': temp + 1, 'humidity': 70},
  'wind': {'speed': 3.4},
  'weather': [
    {'id': condition, 'description': 'trời quang', 'icon': icon},
  ],
};

http.Response weatherResponse({String city = 'Hanoi', double temp = 26.5}) =>
    http.Response(
      jsonEncode(weatherJson(city: city, temp: temp)),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

class TestLocation extends LocationService {
  TestLocation({this.error});
  final WeatherException? error;
  int calls = 0;
  @override
  Future<Coordinates> currentLocation() async {
    calls++;
    if (error != null) throw error!;
    return const Coordinates(21.0285, 105.8542);
  }
}
