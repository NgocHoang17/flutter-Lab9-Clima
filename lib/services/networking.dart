import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'weather_exception.dart';

class NetworkHelper {
  NetworkHelper({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;
  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;

  Future<Map<String, dynamic>> getData(Uri uri) async {
    try {
      final response = await _client.get(uri).timeout(timeout);
      switch (response.statusCode) {
        case 200:
          final json = jsonDecode(utf8.decode(response.bodyBytes));
          if (json is! Map<String, dynamic>) throw const FormatException();
          return json;
        case 401:
        case 403:
          throw const WeatherException(
            'API key không hợp lệ hoặc chưa được kích hoạt. Kiểm tra cấu hình OpenWeatherMap.',
            WeatherError.configuration,
          );
        case 404:
          throw const WeatherException(
            'Không tìm thấy thành phố. Kiểm tra tên, có thể thêm mã quốc gia (ví dụ: Hanoi,VN).',
            WeatherError.cityNotFound,
          );
        case 429:
          throw const WeatherException(
            'Dịch vụ đã đạt giới hạn yêu cầu. Vui lòng thử lại sau.',
            WeatherError.api,
          );
        default:
          throw const WeatherException(
            'Dịch vụ thời tiết tạm thời không phản hồi. Vui lòng thử lại.',
            WeatherError.api,
          );
      }
    } on TimeoutException {
      throw const WeatherException(
        'Kết nối quá thời gian chờ. Kiểm tra mạng rồi thử lại.',
        WeatherError.network,
      );
    } on http.ClientException {
      // Không đưa URL chứa appid hoặc nội dung lỗi thô lên giao diện/log.
      throw const WeatherException(
        'Không kết nối được dịch vụ. Kiểm tra mạng rồi thử lại.',
        WeatherError.network,
      );
    } on FormatException {
      throw const WeatherException(
        'Dữ liệu thời tiết không hợp lệ. Vui lòng thử lại sau.',
        WeatherError.invalidData,
      );
    }
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
