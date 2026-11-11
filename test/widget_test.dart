import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lab09_clima/main.dart';
import 'package:lab09_clima/screens/weather_page.dart';
import 'package:lab09_clima/services/weather_model.dart';
import 'package:lab09_clima/services/weather_exception.dart';
import 'test_helpers.dart';

void main() {
  testWidgets('Thiếu cấu hình được hiển thị, không dùng dữ liệu giả', (
    tester,
  ) async {
    await tester.pumpWidget(const ClimaApp());
    await tester.pumpAndSettle();
    expect(find.textContaining('Ứng dụng chưa có API key'), findsOneWidget);
    expect(find.byKey(const Key('weather-temperature')), findsNothing);
  });

  testWidgets(
    'Loading, tìm thành phố, validation, lỗi 404 và phục hồi bằng vị trí',
    (tester) async {
      final pending = Completer<http.Response>();
      var initial = true;
      final client = MockClient((request) {
        if (initial) {
          initial = false;
          return pending.future;
        }
        final city = request.url.queryParameters['q'];
        if (city == 'unknown') return Future.value(http.Response('{}', 404));
        return Future.value(
          weatherResponse(
            city: city ?? 'Hanoi',
            temp: city == null ? 26.5 : 15,
          ),
        );
      });
      addTearDown(client.close);
      final model = WeatherModel(
        apiKey: 'test-only',
        client: client,
        location: TestLocation(),
      );
      await tester.pumpWidget(MaterialApp(home: WeatherPage(model: model)));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byKey(const Key('search'))).onPressed,
        isNull,
      );
      pending.complete(weatherResponse());
      await tester.pumpAndSettle();
      expect(find.text('Hanoi, VN'), findsOneWidget);
      await tester.tap(find.byKey(const Key('search')));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập tên thành phố.'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('city-input')), 'London');
      await tester.tap(find.byKey(const Key('search')));
      await tester.pumpAndSettle();
      expect(find.text('London, VN'), findsOneWidget);
      expect(find.text('15°C'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('city-input')), 'unknown');
      await tester.tap(find.byKey(const Key('search')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Không tìm thấy thành phố'), findsOneWidget);
      expect(find.byKey(const Key('weather-temperature')), findsNothing);
      await tester.tap(find.byKey(const Key('my-location')));
      await tester.pumpAndSettle();
      expect(find.text('Hanoi, VN'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final kind in [
    WeatherError.permission,
    WeatherError.permissionForever,
    WeatherError.locationDisabled,
  ]) {
    testWidgets('$kind vẫn cho phép tìm theo thành phố', (tester) async {
      final client = MockClient((_) async => weatherResponse());
      addTearDown(client.close);
      final model = WeatherModel(
        apiKey: 'test-only',
        client: client,
        location: TestLocation(
          error: WeatherException('Lỗi vị trí thử nghiệm', kind),
        ),
      );
      await tester.pumpWidget(MaterialApp(home: WeatherPage(model: model)));
      await tester.pumpAndSettle();
      expect(find.text('Lỗi vị trí thử nghiệm'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('city-input')), 'Hanoi');
      await tester.tap(find.byKey(const Key('search')));
      await tester.pumpAndSettle();
      expect(find.text('Hanoi, VN'), findsOneWidget);
    });
  }
}
