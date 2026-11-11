import 'package:http/http.dart' as http;
import '../models/weather_data.dart';
import 'location.dart';
import 'networking.dart';
import 'weather_exception.dart';

class WeatherModel {
  WeatherModel({
    this.apiKey = const String.fromEnvironment('OPENWEATHER_API_KEY'),
    http.Client? client,
    LocationService? location,
    Duration timeout = const Duration(seconds: 15),
  }) : _network = NetworkHelper(client: client, timeout: timeout),
       location = location ?? LocationService();
  final String apiKey;
  final NetworkHelper _network;
  final LocationService location;

  void _checkKey() {
    if (apiKey.trim().isEmpty) {
      throw const WeatherException(
        'Ứng dụng chưa có API key. Xem ASSETS_NOTES.md để cấu hình dịch vụ thời tiết.',
        WeatherError.configuration,
      );
    }
  }

  Future<WeatherData> getCityWeather(String city) async {
    _checkKey();
    if (city.trim().isEmpty) {
      throw const WeatherException(
        'Vui lòng nhập tên thành phố.',
        WeatherError.cityNotFound,
      );
    }
    return _fetch({'q': city.trim()});
  }

  Future<WeatherData> getLocationWeather() async {
    _checkKey();
    final position = await location.currentLocation();
    return _fetch({
      'lat': '${position.latitude}',
      'lon': '${position.longitude}',
    });
  }

  Future<WeatherData> _fetch(Map<String, String> query) async {
    final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      ...query,
      'appid': apiKey.trim(),
      'units': 'metric',
      'lang': 'vi',
    });
    final json = await _network.getData(uri);
    try {
      return WeatherData.fromJson(json);
    } on FormatException {
      throw const WeatherException(
        'Dữ liệu thời tiết thiếu thông tin cần thiết. Vui lòng thử lại.',
        WeatherError.invalidData,
      );
    }
  }

  void close() => _network.close();
}
