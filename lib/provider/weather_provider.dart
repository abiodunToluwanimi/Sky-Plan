import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'weather_data.dart';
import 'package:sky_plan/model/weather_type_mapper.dart';
import 'package:sky_plan/services/location_service.dart';

part 'weather_provider.g.dart';

@riverpod
class Weather extends _$Weather {
  @override
  WeatherData build() {
    return const WeatherData(
      condition: 'Loading…',
      temperature: 25.0,
      humidity: 50,
      weatherCode: 0,
      isDay: true,
    );
  }

  void selectStartTime(int hour, int min) {
    state = state.copyWith(startHour: hour, startMin: min);
  }

  void selectEndTime(int hour, int min) {
    state = state.copyWith(endHour: hour, endMin: min);
  }

  void clearSelectedTimes() {
    state = state.copyWith(
      startHour: null,
      startMin: null,
      endHour: null,
      endMin: null,
    );
  }

  /// Gets current conditions from Open-Meteo.
  ///
  /// If coordinates are provided, it uses those exact coordinates. This lets
  /// the screen share one GPS fix between its location label and weather data.
  /// If omitted, it preserves the original behavior and gets device location
  /// using the project's location service.
  Future<void> fetchLiveWeather({double? latitude, double? longitude}) async {
    if ((latitude == null) != (longitude == null)) {
      throw ArgumentError('Pass both latitude and longitude, or neither.');
    }

    late final double requestLatitude;
    late final double requestLongitude;

    if (latitude != null && longitude != null) {
      requestLatitude = latitude;
      requestLongitude = longitude;
    } else {
      final location = await LocationService.getCurrentLocation();
      requestLatitude = location.latitude;
      requestLongitude = location.longitude;
    }

    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$requestLatitude',
      'longitude': '$requestLongitude',
      'current': 'temperature_2m,relative_humidity_2m,weather_code,is_day',
    });

    final response = await http.get(uri).timeout(
      const Duration(seconds: 20),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Open-Meteo request failed with status ${response.statusCode}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final current = body['current'] as Map<String, dynamic>;
    final code = (current['weather_code'] as num).toInt();

    state = state.copyWith(
      temperature: (current['temperature_2m'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).round(),
      weatherCode: code,
      isDay: current['is_day'] == 1,
      condition: conditionLabelFromWmoCode(code),
    );
  }
}
