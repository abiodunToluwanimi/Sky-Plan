import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'weather_data.dart';
import 'package:sky_plan/model/weather_type_mapper.dart';
import 'package:sky_plan/services/location_service.dart';

part 'weather_provider.g.dart';

// This generates a NotifierProvider named 'weatherProvider'
@riverpod
class Weather extends _$Weather {
  @override
  WeatherData build() {
    // Initial default state before the first live fetch completes.
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

  /// Gets the device's current location, then pulls live conditions for it
  /// from Open-Meteo (no API key needed).
  Future<void> fetchLiveWeather() async {
    final position = await getCurrentPosition();

    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${position.latitude}',
      'longitude': '${position.longitude}',
      'current': 'temperature_2m,relative_humidity_2m,weather_code,is_day',
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
        'Open-Meteo request failed with status ${response.statusCode}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final current = body['current'] as Map<String, dynamic>;
    final code = current['weather_code'] as int;

    state = state.copyWith(
      temperature: (current['temperature_2m'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).round(),
      weatherCode: code,
      isDay: current['is_day'] == 1,
      condition: conditionLabelFromWmoCode(code),
    );
  }
}