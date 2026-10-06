// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WeatherDataImpl _$$WeatherDataImplFromJson(Map<String, dynamic> json) =>
    _$WeatherDataImpl(
      condition: json['condition'] as String? ?? 'Sunny',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 25.0,
      humidity: (json['humidity'] as num?)?.toInt() ?? 50,
      weatherCode: (json['weatherCode'] as num?)?.toInt() ?? 0,
      isDay: json['isDay'] as bool? ?? true,
      startHour: (json['startHour'] as num?)?.toInt(),
      startMin: (json['startMin'] as num?)?.toInt(),
      endHour: (json['endHour'] as num?)?.toInt(),
      endMin: (json['endMin'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$WeatherDataImplToJson(_$WeatherDataImpl instance) =>
    <String, dynamic>{
      'condition': instance.condition,
      'temperature': instance.temperature,
      'humidity': instance.humidity,
      'weatherCode': instance.weatherCode,
      'isDay': instance.isDay,
      'startHour': instance.startHour,
      'startMin': instance.startMin,
      'endHour': instance.endHour,
      'endMin': instance.endMin,
    };
