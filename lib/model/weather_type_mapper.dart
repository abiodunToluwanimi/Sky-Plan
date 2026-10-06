import 'package:flutter_weather_bg/flutter_weather_bg.dart';

/// Maps an Open-Meteo WMO weather code (https://open-meteo.com/en/docs)
/// to the closest WeatherType supported by flutter_weather_bg.
///
/// `isDay` picks between the day/night variant where the package has one
/// (sunny vs sunnyNight, cloudy vs cloudyNight) — Open-Meteo gives you this
/// as `is_day` (1 or 0) in the same response, no sunrise/sunset math needed.
WeatherType weatherTypeFromWmoCode(int code, {required bool isDay}) {
  switch (code) {
    case 0: // clear sky
    case 1: // mainly clear
      return isDay ? WeatherType.sunny : WeatherType.sunnyNight;

    case 2: // partly cloudy
      return isDay ? WeatherType.cloudy : WeatherType.cloudyNight;

    case 3: // overcast
      return WeatherType.overcast;

    case 45: // fog
    case 48: // depositing rime fog
      return WeatherType.foggy;

    case 51: // drizzle: light
    case 53: // drizzle: moderate
    case 55: // drizzle: dense
    case 56: // freezing drizzle: light
    case 57: // freezing drizzle: dense
    case 61: // rain: slight
    case 80: // rain showers: slight
      return WeatherType.lightRainy;

    case 63: // rain: moderate
    case 81: // rain showers: moderate
      return WeatherType.middleRainy;

    case 65: // rain: heavy
    case 66: // freezing rain: light
    case 67: // freezing rain: heavy
    case 82: // rain showers: violent
      return WeatherType.heavyRainy;

    case 71: // snow fall: slight
    case 77: // snow grains
    case 85: // snow showers: slight
      return WeatherType.lightSnow;

    case 73: // snow fall: moderate
      return WeatherType.middleSnow;

    case 75: // snow fall: heavy
    case 86: // snow showers: heavy
      return WeatherType.heavySnow;

    case 95: // thunderstorm: slight or moderate
    case 96: // thunderstorm with slight hail
    case 99: // thunderstorm with heavy hail
      return WeatherType.thunder;

    default:
      // Unmapped/unexpected code — fall back to something neutral
      // rather than crashing the background.
      return isDay ? WeatherType.cloudy : WeatherType.cloudyNight;
  }
}

/// Open-Meteo only gives you a numeric code, not a label — this fills that
/// gap for anywhere you're currently showing `weatherData.condition`.
String conditionLabelFromWmoCode(int code) {
  switch (code) {
    case 0:
      return 'Clear sky';
    case 1:
      return 'Mainly clear';
    case 2:
      return 'Partly cloudy';
    case 3:
      return 'Overcast';
    case 45:
    case 48:
      return 'Fog';
    case 51:
    case 53:
    case 55:
      return 'Drizzle';
    case 56:
    case 57:
      return 'Freezing drizzle';
    case 61:
    case 63:
    case 65:
      return 'Rain';
    case 66:
    case 67:
      return 'Freezing rain';
    case 71:
    case 73:
    case 75:
    case 77:
      return 'Snow';
    case 80:
    case 81:
    case 82:
      return 'Rain showers';
    case 85:
    case 86:
      return 'Snow showers';
    case 95:
      return 'Thunderstorm';
    case 96:
    case 99:
      return 'Thunderstorm with hail';
    default:
      return 'Unknown';
  }
}