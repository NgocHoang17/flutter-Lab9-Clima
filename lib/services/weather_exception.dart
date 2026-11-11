enum WeatherError {
  configuration,
  network,
  cityNotFound,
  permission,
  permissionForever,
  locationDisabled,
  invalidData,
  api,
}

class WeatherException implements Exception {
  const WeatherException(this.message, this.kind);
  final String message;
  final WeatherError kind;
  @override
  String toString() => message;
}
