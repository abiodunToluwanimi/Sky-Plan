import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sky_plan/services/location_service.dart';
import 'package:sky_plan/model/weather_type_mapper.dart';

class HourlyForecast {
  final int hour;
  final double temperature;
  final int rainChance;
  final int weatherCode;

  const HourlyForecast({
    required this.hour,
    required this.temperature,
    required this.rainChance,
    required this.weatherCode,
  });

  /// One line of the forecast table that goes into the AI prompt.
  String toPromptLine() =>
      '${formatHour(hour)}: ${temperature.round()}°C, '
      '${conditionLabelFromWmoCode(weatherCode)}, $rainChance% chance of rain';
}

String formatHour(int hour) {
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$h12 ${hour < 12 ? 'AM' : 'PM'}';
}

typedef ForecastWindow = ({List<HourlyForecast> hours, bool isTomorrow});

/// Fetches hourly conditions between a selected start and end hour.
/// If the selected window has already passed today, tomorrow is used.
Future<ForecastWindow> fetchForecastWindow({
  required int startHour,
  required int endHour,
}) async {
  final position = await getCurrentPosition();
  final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': '${position.latitude}',
    'longitude': '${position.longitude}',
    'current': 'temperature_2m',
    'hourly': 'temperature_2m,precipitation_probability,weather_code',
    'forecast_days': '2',
    'timezone': 'auto',
  });

  final response = await http.get(uri).timeout(const Duration(seconds: 15));
  if (response.statusCode != 200) {
    throw Exception('Forecast request failed (${response.statusCode}).');
  }

  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final hourly = body['hourly'] as Map<String, dynamic>;
  final temps = hourly['temperature_2m'] as List;
  final rain = hourly['precipitation_probability'] as List;
  final codes = hourly['weather_code'] as List;
  final nowHour = int.parse((body['current']['time'] as String).substring(11, 13));
  final isTomorrow = nowHour > endHour;
  final offset = isTomorrow ? 24 : 0;
  final hours = <HourlyForecast>[];

  for (var h = startHour; h <= endHour; h++) {
    final i = offset + h;
    if (i >= temps.length) break;
    hours.add(HourlyForecast(
      hour: h % 24,
      temperature: (temps[i] as num).toDouble(),
      rainChance: ((rain[i] ?? 0) as num).round(),
      weatherCode: (codes[i] as num).toInt(),
    ));
  }

  return (hours: hours, isTomorrow: isTomorrow);
}

/// Fetches a short forecast starting from the current local hour.
/// Used when the user writes a duration (or leaves timing unspecified)
/// rather than selecting exact start/end clock times.
Future<ForecastWindow> fetchNextForecastWindow({
  required int durationMinutes,
}) async {
  final position = await getCurrentPosition();
  final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': '${position.latitude}',
    'longitude': '${position.longitude}',
    'current': 'temperature_2m',
    'hourly': 'temperature_2m,precipitation_probability,weather_code',
    'forecast_days': '2',
    'timezone': 'auto',
  });

  final response = await http.get(uri).timeout(const Duration(seconds: 15));
  if (response.statusCode != 200) {
    throw Exception('Forecast request failed (${response.statusCode}).');
  }

  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final currentTime = body['current']['time'] as String;
  final nowHour = int.parse(currentTime.substring(11, 13));
  final nowMinute = int.parse(currentTime.substring(14, 16));
  final hourly = body['hourly'] as Map<String, dynamic>;
  final temps = hourly['temperature_2m'] as List;
  final rain = hourly['precipitation_probability'] as List;
  final codes = hourly['weather_code'] as List;

  // Include every hourly bucket touched by the duration. For example,
  // 2h 30m starting at 10:30 needs the 10:00, 11:00 and 12:00 buckets.
  final hoursNeeded = ((nowMinute + durationMinutes + 59) ~/ 60)
      .clamp(1, 25)
      .toInt();
  final hours = <HourlyForecast>[];

  for (var step = 0; step < hoursNeeded; step++) {
    final index = nowHour + step;
    if (index >= temps.length) break;
    hours.add(HourlyForecast(
      hour: index % 24,
      temperature: (temps[index] as num).toDouble(),
      rainChance: ((rain[index] ?? 0) as num).round(),
      weatherCode: (codes[index] as num).toInt(),
    ));
  }

  return (hours: hours, isTomorrow: false);
}
