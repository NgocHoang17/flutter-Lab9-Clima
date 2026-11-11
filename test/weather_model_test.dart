import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lab09_clima/models/weather_data.dart';
import 'package:lab09_clima/services/weather_model.dart';
import 'package:lab09_clima/services/weather_exception.dart';
import 'test_helpers.dart';

TypeMatcher<WeatherException> errorKind(WeatherError kind) =>
    isA<WeatherException>().having((e) => e.kind, 'kind', kind);

void main() {
  test('Truy vấn thành phố được encode và JSON metric được đọc đúng', () async {
    final client = MockClient((request) async {
      expect(request.url.scheme, 'https');
      expect(request.url.host, 'api.openweathermap.org');
      expect(request.url.path, '/data/2.5/weather');
      expect(request.url.queryParameters['q'], 'Hồ Chí Minh,VN');
      expect(request.url.queryParameters['units'], 'metric');
      expect(request.url.queryParameters['lang'], 'vi');
      return weatherResponse();
    });
    addTearDown(client.close);
    final data = await WeatherModel(
      apiKey: 'test-only',
      client: client,
    ).getCityWeather(' Hồ Chí Minh,VN ');
    expect(data.temperature, 26.5);
    expect(data.description, 'trời quang');
    expect(data.humidity, 70);
  });

  test('Vị trí thật từ service được đưa vào lat/lon', () async {
    final location = TestLocation();
    final client = MockClient((request) async {
      expect(request.url.queryParameters['lat'], '21.0285');
      expect(request.url.queryParameters['lon'], '105.8542');
      expect(request.url.queryParameters.containsKey('q'), isFalse);
      return weatherResponse();
    });
    addTearDown(client.close);
    await WeatherModel(
      apiKey: 'test-only',
      client: client,
      location: location,
    ).getLocationWeather();
    expect(location.calls, 1);
  });

  test('Thiếu API key dừng trước khi gọi mạng hoặc xin vị trí', () async {
    final location = TestLocation();
    final model = WeatherModel(apiKey: '', location: location);
    addTearDown(model.close);
    await expectLater(
      model.getLocationWeather(),
      throwsA(errorKind(WeatherError.configuration)),
    );
    expect(location.calls, 0);
  });

  for (final entry in {
    401: WeatherError.configuration,
    404: WeatherError.cityNotFound,
    429: WeatherError.api,
    500: WeatherError.api,
  }.entries) {
    test('HTTP ${entry.key} trả lỗi có thể hiển thị', () async {
      final client = MockClient((_) async => http.Response('{}', entry.key));
      addTearDown(client.close);
      await expectLater(
        WeatherModel(apiKey: 'test-only', client: client).getCityWeather('x'),
        throwsA(errorKind(entry.value)),
      );
    });
  }

  test('Mạng lỗi và timeout không làm lộ URI/key', () async {
    final client = MockClient(
      (_) async => throw http.ClientException('secret-in-url'),
    );
    addTearDown(client.close);
    await expectLater(
      WeatherModel(apiKey: 'test-only', client: client).getCityWeather('x'),
      throwsA(
        errorKind(WeatherError.network).having(
          (dynamic e) => e.message,
          'sanitized',
          isNot(contains('secret-in-url')),
        ),
      ),
    );
    final delayed = MockClient((_) => Completer<http.Response>().future);
    addTearDown(delayed.close);
    await expectLater(
      WeatherModel(
        apiKey: 'test-only',
        client: delayed,
        timeout: const Duration(milliseconds: 10),
      ).getCityWeather('x'),
      throwsA(errorKind(WeatherError.network)),
    );
  });

  test('JSON hỏng/thiếu trường được báo lỗi dữ liệu', () async {
    for (final body in [
      'not-json',
      '[]',
      '{}',
      '{"name":"Hanoi","weather":[]}',
    ]) {
      final client = MockClient((_) async => http.Response(body, 200));
      addTearDown(client.close);
      await expectLater(
        WeatherModel(apiKey: 'test-only', client: client).getCityWeather('x'),
        throwsA(errorKind(WeatherError.invalidData)),
      );
    }
  });

  test('Icon thay đổi theo mã thời tiết và ngày/đêm', () {
    for (final entry in {
      201: Icons.thunderstorm,
      301: Icons.water_drop,
      501: Icons.water_drop,
      601: Icons.ac_unit,
      701: Icons.foggy,
      800: Icons.wb_sunny_rounded,
      803: Icons.cloud_rounded,
    }.entries) {
      expect(
        WeatherData.fromJson(weatherJson(condition: entry.key)).icon,
        entry.value,
      );
    }
    expect(
      WeatherData.fromJson(weatherJson(icon: '01n')).icon,
      Icons.nightlight_round,
    );
  });
}
