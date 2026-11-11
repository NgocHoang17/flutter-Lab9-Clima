import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'weather_exception.dart';

class Coordinates {
  const Coordinates(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

class LocationService {
  Future<Coordinates> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const WeatherException(
        'Dịch vụ vị trí đang tắt. Bật vị trí hoặc tìm theo tên thành phố.',
        WeatherError.locationDisabled,
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const WeatherException(
        'Quyền vị trí đã bị chặn. Mở cài đặt để cấp lại quyền hoặc tìm theo thành phố.',
        WeatherError.permissionForever,
      );
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      throw const WeatherException(
        'Bạn chưa cấp quyền vị trí. Vẫn có thể tìm thời tiết theo tên thành phố.',
        WeatherError.permission,
      );
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return Coordinates(position.latitude, position.longitude);
    } on TimeoutException {
      throw const WeatherException(
        'Chưa xác định được vị trí. Thử lại ngoài trời hoặc tìm theo thành phố.',
        WeatherError.locationDisabled,
      );
    } on PermissionDeniedException {
      throw const WeatherException(
        'Quyền vị trí đã bị từ chối. Hãy tìm theo tên thành phố.',
        WeatherError.permission,
      );
    } on LocationServiceDisabledException {
      throw const WeatherException(
        'Dịch vụ vị trí đã bị tắt. Hãy bật vị trí rồi thử lại.',
        WeatherError.locationDisabled,
      );
    }
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
