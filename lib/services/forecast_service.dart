import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sky_plan/services/location_service.dart';
import 'package:sky_plan/model/weather_type_mapper.dart';

class HourlyForecast {
  final int hour;
  final double temperature;
  final double feelsLike;
  final int rainChance;
  final double rainMm;
  final double uvIndex;
  final double windKmh;
  final int weatherCode;

  const HourlyForecast({
    required this.hour,
    required this.temperature,
    required this.feelsLike,
    required this.rainChance,
    required this.rainMm,
    required this.uvIndex,
    required this.windKmh,
    required this.weatherCode,
  });

  /// One line of the forecast table that goes into the AI prompt.
  String toPromptLine() =>
      '${formatHour(hour)}: ${temperature.round()}°C '
      '(feels like ${feelsLike.round()}°C), '
      'UV ${uvIndex.round()} (${uvLabel(uvIndex)}), '
      '${conditionLabelFromWmoCode(weatherCode)}, '
      '$rainChance% chance of rain, '
      '${rainMm.toStringAsFixed(1)} mm that hour (${rainLabel(rainMm)}), '
      'wind ${windKmh.round()} km/h';
}

String uvLabel(double uv) {
  if (uv < 3) return 'low';
  if (uv < 6) return 'moderate';
  if (uv < 8) return 'high';
  if (uv < 11) return 'very high';
  return 'extreme';
}

String rainLabel(double mm) {
  if (mm < 0.1) return 'no rain';
  if (mm < 2.5) return 'light rain';
  if (mm < 7.6) return 'moderate rain';
  if (mm < 50) return 'heavy rain';
  return 'violent rain';
}

String formatHour(int hour) {
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$h12 ${hour < 12 ? 'AM' : 'PM'}';
}

/// Formats minutes since midnight (can exceed 1440 for tomorrow) as "10:20 AM".
String formatClock(int absoluteMinutes) {
  final hour = (absoluteMinutes ~/ 60) % 24;
  final minute = (absoluteMinutes % 60).toString().padLeft(2, '0');
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$h12:$minute ${hour < 12 ? 'AM' : 'PM'}';
}

typedef ForecastWindow = ({
  List<HourlyForecast> hours,
  bool isTomorrow,
  String? windowLabel,
});

/// Shared Open-Meteo request used by both fetch functions below.
Future<Map<String, dynamic>> _fetchRawForecast() async {
  final location = await LocationService.getCurrentLocation();
  final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': '${location.latitude}',
    'longitude': '${location.longitude}',
    'current': 'temperature_2m',
    'hourly': 'temperature_2m,apparent_temperature,precipitation_probability,'
        'precipitation,weather_code,uv_index,wind_speed_10m',
    'forecast_days': '3',
    'timezone': 'auto',
  });

  final response = await http.get(uri).timeout(const Duration(seconds: 15));
  if (response.statusCode != 200) {
    throw Exception('Forecast request failed (${response.statusCode}).');
  }
  return jsonDecode(response.body) as Map<String, dynamic>;
}

/// Reads one hourly bucket out of the Open-Meteo response.
/// Missing values (null) fall back to 0 so the app never crashes on them.
HourlyForecast _hourAt(Map<String, dynamic> hourly, int index) {
  double value(String key) =>
      ((hourly[key] as List)[index] as num?)?.toDouble() ?? 0;

  return HourlyForecast(
    hour: index % 24,
    temperature: value('temperature_2m'),
    feelsLike: value('apparent_temperature'),
    rainChance: value('precipitation_probability').round(),
    rainMm: value('precipitation'),
    uvIndex: value('uv_index'),
    windKmh: value('wind_speed_10m'),
    weatherCode: value('weather_code').toInt(),
  );
}

/// Fetches hourly conditions between a selected start and end hour.
/// If the selected window has already passed today, tomorrow is used.
Future<ForecastWindow> fetchForecastWindow({
  required int startHour,
  required int endHour,
}) async {
  final body = await _fetchRawForecast();
  final hourly = body['hourly'] as Map<String, dynamic>;
  final total = (hourly['temperature_2m'] as List).length;
  final nowHour =
      int.parse((body['current']['time'] as String).substring(11, 13));
  final isTomorrow = nowHour > endHour;
  final offset = isTomorrow ? 24 : 0;
  final hours = <HourlyForecast>[];

  for (var h = startHour; h <= endHour; h++) {
    final i = offset + h;
    if (i >= total) break;
    hours.add(_hourAt(hourly, i));
  }

  return (hours: hours, isTomorrow: isTomorrow, windowLabel: null);
}

/// Fetches a short forecast starting from the current local time.
///
/// [startOffsetMinutes] shifts the start into the future, e.g. 120 for
/// "class in 2 hours". When the start is within 4 hours, the hours between now
/// and the start are included too, so the AI can also judge the trip there.
Future<ForecastWindow> fetchNextForecastWindow({
  required int durationMinutes,
  int startOffsetMinutes = 0,
}) async {
  final body = await _fetchRawForecast();
  final currentTime = body['current']['time'] as String;
  final nowHour = int.parse(currentTime.substring(11, 13));
  final nowMinute = int.parse(currentTime.substring(14, 16));
  final hourly = body['hourly'] as Map<String, dynamic>;
  final total = (hourly['temperature_2m'] as List).length;

  // Minutes since today's 00:00, which is also how Open-Meteo indexes hours.
  final startAbs = nowHour * 60 + nowMinute + startOffsetMinutes;
  final endAbs = startAbs + durationMinutes;

  final includeLeadUp = startOffsetMinutes > 0 && startOffsetMinutes <= 240;
  final firstIndex = includeLeadUp ? nowHour : startAbs ~/ 60;
  final lastIndex = (endAbs - 1) ~/ 60;

  final hours = <HourlyForecast>[];
  for (var index = firstIndex; index <= lastIndex && index < total; index++) {
    hours.add(_hourAt(hourly, index));
  }

  final day = startAbs >= 24 * 60 ? ' tomorrow' : '';
  return (
    hours: hours,
    isTomorrow: startAbs >= 24 * 60,
    windowLabel: '${formatClock(startAbs)} to ${formatClock(endAbs)}$day',
  );
}