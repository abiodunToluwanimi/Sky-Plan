// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weather_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WeatherData _$WeatherDataFromJson(Map<String, dynamic> json) {
  return _WeatherData.fromJson(json);
}

/// @nodoc
mixin _$WeatherData {
  String get condition => throw _privateConstructorUsedError;
  double get temperature => throw _privateConstructorUsedError;
  int get humidity =>
      throw _privateConstructorUsedError; // WMO weather code from Open-Meteo (0 = clear sky). See:
// https://open-meteo.com/en/docs
  int get weatherCode => throw _privateConstructorUsedError;
  bool get isDay => throw _privateConstructorUsedError;
  int? get startHour => throw _privateConstructorUsedError;
  int? get startMin => throw _privateConstructorUsedError;
  int? get endHour => throw _privateConstructorUsedError;
  int? get endMin => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WeatherDataCopyWith<WeatherData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WeatherDataCopyWith<$Res> {
  factory $WeatherDataCopyWith(
          WeatherData value, $Res Function(WeatherData) then) =
      _$WeatherDataCopyWithImpl<$Res, WeatherData>;
  @useResult
  $Res call(
      {String condition,
      double temperature,
      int humidity,
      int weatherCode,
      bool isDay,
      int? startHour,
      int? startMin,
      int? endHour,
      int? endMin});
}

/// @nodoc
class _$WeatherDataCopyWithImpl<$Res, $Val extends WeatherData>
    implements $WeatherDataCopyWith<$Res> {
  _$WeatherDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? condition = null,
    Object? temperature = null,
    Object? humidity = null,
    Object? weatherCode = null,
    Object? isDay = null,
    Object? startHour = freezed,
    Object? startMin = freezed,
    Object? endHour = freezed,
    Object? endMin = freezed,
  }) {
    return _then(_value.copyWith(
      condition: null == condition
          ? _value.condition
          : condition // ignore: cast_nullable_to_non_nullable
              as String,
      temperature: null == temperature
          ? _value.temperature
          : temperature // ignore: cast_nullable_to_non_nullable
              as double,
      humidity: null == humidity
          ? _value.humidity
          : humidity // ignore: cast_nullable_to_non_nullable
              as int,
      weatherCode: null == weatherCode
          ? _value.weatherCode
          : weatherCode // ignore: cast_nullable_to_non_nullable
              as int,
      isDay: null == isDay
          ? _value.isDay
          : isDay // ignore: cast_nullable_to_non_nullable
              as bool,
      startHour: freezed == startHour
          ? _value.startHour
          : startHour // ignore: cast_nullable_to_non_nullable
              as int?,
      startMin: freezed == startMin
          ? _value.startMin
          : startMin // ignore: cast_nullable_to_non_nullable
              as int?,
      endHour: freezed == endHour
          ? _value.endHour
          : endHour // ignore: cast_nullable_to_non_nullable
              as int?,
      endMin: freezed == endMin
          ? _value.endMin
          : endMin // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WeatherDataImplCopyWith<$Res>
    implements $WeatherDataCopyWith<$Res> {
  factory _$$WeatherDataImplCopyWith(
          _$WeatherDataImpl value, $Res Function(_$WeatherDataImpl) then) =
      __$$WeatherDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String condition,
      double temperature,
      int humidity,
      int weatherCode,
      bool isDay,
      int? startHour,
      int? startMin,
      int? endHour,
      int? endMin});
}

/// @nodoc
class __$$WeatherDataImplCopyWithImpl<$Res>
    extends _$WeatherDataCopyWithImpl<$Res, _$WeatherDataImpl>
    implements _$$WeatherDataImplCopyWith<$Res> {
  __$$WeatherDataImplCopyWithImpl(
      _$WeatherDataImpl _value, $Res Function(_$WeatherDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? condition = null,
    Object? temperature = null,
    Object? humidity = null,
    Object? weatherCode = null,
    Object? isDay = null,
    Object? startHour = freezed,
    Object? startMin = freezed,
    Object? endHour = freezed,
    Object? endMin = freezed,
  }) {
    return _then(_$WeatherDataImpl(
      condition: null == condition
          ? _value.condition
          : condition // ignore: cast_nullable_to_non_nullable
              as String,
      temperature: null == temperature
          ? _value.temperature
          : temperature // ignore: cast_nullable_to_non_nullable
              as double,
      humidity: null == humidity
          ? _value.humidity
          : humidity // ignore: cast_nullable_to_non_nullable
              as int,
      weatherCode: null == weatherCode
          ? _value.weatherCode
          : weatherCode // ignore: cast_nullable_to_non_nullable
              as int,
      isDay: null == isDay
          ? _value.isDay
          : isDay // ignore: cast_nullable_to_non_nullable
              as bool,
      startHour: freezed == startHour
          ? _value.startHour
          : startHour // ignore: cast_nullable_to_non_nullable
              as int?,
      startMin: freezed == startMin
          ? _value.startMin
          : startMin // ignore: cast_nullable_to_non_nullable
              as int?,
      endHour: freezed == endHour
          ? _value.endHour
          : endHour // ignore: cast_nullable_to_non_nullable
              as int?,
      endMin: freezed == endMin
          ? _value.endMin
          : endMin // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WeatherDataImpl implements _WeatherData {
  const _$WeatherDataImpl(
      {this.condition = 'Sunny',
      this.temperature = 25.0,
      this.humidity = 50,
      this.weatherCode = 0,
      this.isDay = true,
      this.startHour,
      this.startMin,
      this.endHour,
      this.endMin});

  factory _$WeatherDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$WeatherDataImplFromJson(json);

  @override
  @JsonKey()
  final String condition;
  @override
  @JsonKey()
  final double temperature;
  @override
  @JsonKey()
  final int humidity;
// WMO weather code from Open-Meteo (0 = clear sky). See:
// https://open-meteo.com/en/docs
  @override
  @JsonKey()
  final int weatherCode;
  @override
  @JsonKey()
  final bool isDay;
  @override
  final int? startHour;
  @override
  final int? startMin;
  @override
  final int? endHour;
  @override
  final int? endMin;

  @override
  String toString() {
    return 'WeatherData(condition: $condition, temperature: $temperature, humidity: $humidity, weatherCode: $weatherCode, isDay: $isDay, startHour: $startHour, startMin: $startMin, endHour: $endHour, endMin: $endMin)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WeatherDataImpl &&
            (identical(other.condition, condition) ||
                other.condition == condition) &&
            (identical(other.temperature, temperature) ||
                other.temperature == temperature) &&
            (identical(other.humidity, humidity) ||
                other.humidity == humidity) &&
            (identical(other.weatherCode, weatherCode) ||
                other.weatherCode == weatherCode) &&
            (identical(other.isDay, isDay) || other.isDay == isDay) &&
            (identical(other.startHour, startHour) ||
                other.startHour == startHour) &&
            (identical(other.startMin, startMin) ||
                other.startMin == startMin) &&
            (identical(other.endHour, endHour) || other.endHour == endHour) &&
            (identical(other.endMin, endMin) || other.endMin == endMin));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, condition, temperature, humidity,
      weatherCode, isDay, startHour, startMin, endHour, endMin);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WeatherDataImplCopyWith<_$WeatherDataImpl> get copyWith =>
      __$$WeatherDataImplCopyWithImpl<_$WeatherDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WeatherDataImplToJson(
      this,
    );
  }
}

abstract class _WeatherData implements WeatherData {
  const factory _WeatherData(
      {String condition,
      double temperature,
      int humidity,
      int weatherCode,
      bool isDay,
      int? startHour,
      int? startMin,
      int? endHour,
      int? endMin}) = _$WeatherDataImpl;

  factory _WeatherData.fromJson(Map<String, dynamic> json) =
      _$WeatherDataImpl.fromJson;

  @override
  String get condition;
  @override
  double get temperature;
  @override
  int get humidity;
  @override // WMO weather code from Open-Meteo (0 = clear sky). See:
// https://open-meteo.com/en/docs
  int get weatherCode;
  @override
  bool get isDay;
  @override
  int? get startHour;
  @override
  int? get startMin;
  @override
  int? get endHour;
  @override
  int? get endMin;
  @override
  @JsonKey(ignore: true)
  _$$WeatherDataImplCopyWith<_$WeatherDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
