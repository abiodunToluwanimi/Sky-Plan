import 'package:freezed_annotation/freezed_annotation.dart';

// These two lines are required for codegen to link the files
part 'weather_data.freezed.dart';
part 'weather_data.g.dart';

@freezed
class WeatherData with _$WeatherData {
  const factory WeatherData({
    @Default('Sunny') String condition,
    @Default(25.0) double temperature,
    @Default(50) int humidity,
    // WMO weather code from Open-Meteo (0 = clear sky). See:
    // https://open-meteo.com/en/docs
    @Default(0) int weatherCode,
    @Default(true) bool isDay,
    int? startHour,
    int? startMin,
    int? endHour,
    int? endMin,
  }) = _WeatherData;

  // This single line generates all the JSON parsing logic
  factory WeatherData.fromJson(Map<String, dynamic> json) =>
      _$WeatherDataFromJson(json);
}