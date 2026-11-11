import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import '../services/weather_exception.dart';
import '../services/weather_model.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key, this.model});
  final WeatherModel? model;
  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  late final WeatherModel _model = widget.model ?? WeatherModel();
  final _cityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  WeatherData? _weather;
  WeatherException? _error;
  bool _loading = false;
  String? _lastCity;
  DateTime? _updatedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load({String? city}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      _weather = null;
      _lastCity = city;
    });
    try {
      final weather = city == null
          ? await _model.getLocationWeather()
          : await _model.getCityWeather(city);
      if (!mounted) return;
      setState(() {
        _weather = weather;
        _updatedAt = DateTime.now();
      });
    } on WeatherException catch (error) {
      if (mounted) setState(() => _error = error);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = const WeatherException(
            'Chưa lấy được thời tiết. Thử tìm theo tên thành phố hoặc thử lại sau.',
            WeatherError.api,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _search() {
    if (_loading || !_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _load(city: _cityController.text.trim());
  }

  Future<void> _openSettings() async {
    try {
      final opened = _error?.kind == WeatherError.locationDisabled
          ? await _model.location.openLocationSettings()
          : await _model.location.openAppSettings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            opened
                ? 'Sau khi cấp quyền, quay lại và nhấn Vị trí của tôi.'
                : 'Hãy mở cài đặt thiết bị để bật quyền vị trí.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hãy cấp quyền vị trí trong cài đặt thiết bị.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    if (widget.model == null) _model.close();
    super.dispose();
  }

  Widget _errorCard() => Card(
    margin: EdgeInsets.zero,
    color: const Color(0xFFFFEDE7),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.info_outline, size: 40, color: Color(0xFF9F432F)),
          const SizedBox(height: 16),
          Text(
            _error!.message,
            key: const Key('error-message'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, height: 1.5),
          ),
          const SizedBox(height: 16),
          if (_error!.kind != WeatherError.configuration)
            OutlinedButton.icon(
              onPressed: () => _load(city: _lastCity),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          if (_error!.kind == WeatherError.permission ||
              _error!.kind == WeatherError.permissionForever ||
              _error!.kind == WeatherError.locationDisabled)
            Text(
              kIsWeb
                  ? 'Bật quyền vị trí trong cài đặt trang web của trình duyệt, hoặc tìm theo thành phố.'
                  : 'Bạn có thể tìm theo thành phố mà không cần quyền vị trí.',
              textAlign: TextAlign.center,
            ),
          if (!kIsWeb &&
              (_error!.kind == WeatherError.permissionForever ||
                  _error!.kind == WeatherError.locationDisabled))
            TextButton(
              onPressed: _openSettings,
              child: const Text('Mở cài đặt vị trí'),
            ),
        ],
      ),
    ),
  );

  Widget _weatherCard(WeatherData weather) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: weather.backgroundColors,
      ),
    ),
    child: Column(
      children: [
        const Icon(Icons.location_on_outlined, color: Colors.white70),
        const SizedBox(height: 8),
        Text(
          [weather.city, weather.country].where((s) => s.isNotEmpty).join(', '),
          key: const Key('weather-city'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 28),
        Icon(
          weather.icon,
          key: const Key('weather-icon'),
          size: 84,
          color: const Color(0xFFFFE5A2),
        ),
        Text(
          '${weather.temperature.round()}°C',
          key: const Key('weather-temperature'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 72,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          weather.description,
          key: const Key('weather-description'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        const SizedBox(height: 12),
        Text(
          'Cảm giác như ${weather.feelsLike.round()}°C',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 28,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            Text(
              'Độ ẩm  ${weather.humidity.round()}%',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Gió  ${weather.windSpeed.toStringAsFixed(1)} m/s',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Cập nhật ${TimeOfDay.fromDateTime(_updatedAt!).format(context)} · OpenWeatherMap',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('CLIMA / 09')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Thời tiết quanh bạn',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Một nơi bất kỳ. Thời tiết ngay lúc này.'),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    key: const Key('city-input'),
                    controller: _cityController,
                    enabled: !_loading,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText: 'Tên thành phố',
                      hintText: 'Ví dụ: Hanoi,VN',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Vui lòng nhập tên thành phố.'
                        : null,
                    onFieldSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      key: const Key('search'),
                      onPressed: _loading ? null : _search,
                      icon: const Icon(Icons.search),
                      label: const Text('Tìm kiếm'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('my-location'),
                      onPressed: _loading ? null : () => _load(),
                      icon: const Icon(Icons.my_location),
                      label: const Text('Vị trí của tôi'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text('Đang lấy thời tiết…'),
                      ],
                    ),
                  )
                else if (_error != null)
                  _errorCard()
                else if (_weather != null)
                  _weatherCard(_weather!),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
