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

/// Fetches the hourly forecast and keeps only the hours between
/// [startHour] and [endHour]. If that window has already passed today
/// (e.g. it's 8 PM and they picked 9 AM–5 PM), it uses tomorrow's forecast.
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
    'timezone': 'auto', // times come back in the user's local time
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

  // current.time looks like "2026-09-28T14:15" (user's local time).
  final nowHour =
      int.parse((body['current']['time'] as String).substring(11, 13));
  final isTomorrow = nowHour > endHour;

  // The hourly arrays start at local midnight today: index = day*24 + hour.
  final offset = isTomorrow ? 24 : 0;
  final hours = <HourlyForecast>[];
  for (var h = startHour; h <= endHour; h++) {
    final i = offset + h;
    if (i >= temps.length) break;
    hours.add(HourlyForecast(
      hour: h,
      temperature: (temps[i] as num).toDouble(),
      rainChance: ((rain[i] ?? 0) as num).round(),
      weatherCode: (codes[i] as num).toInt(),
    ));
  }
  return (hours: hours, isTomorrow: isTomorrow);
}