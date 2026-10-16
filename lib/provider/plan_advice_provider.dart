import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sky_plan/services/ai_service.dart';
import 'package:sky_plan/services/forecast_service.dart';

part 'plan_advice_provider.g.dart';

const _systemPrompt = '''
You are a weather-planning assistant inside a mobile app.
Reply in plain friendly simple text only (no markdown, no asterisks, no headings), under 90 words.
Start with one verdict line beginning with ✅ (good), ⚠️ (risky) or ❌ (not suitable).
Then give short emoji-led lines covering the main weather issues, practical steps,
and a better time only if there is a significantly better one.
Respect the user's actual activity and timing. Do not claim weather details that
are not supported by the supplied forecast.
''';

@riverpod
class PlanAdvice extends _$PlanAdvice {
  @override
  Future<String?> build() async => null;

  Future<void> getAdvice({
    required String task,
    int? startHour,
    int? startMin,
    int? endHour,
    int? endMin,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard<String?>(() async {
      final anyManualTime = startHour != null ||
          startMin != null ||
          endHour != null ||
          endMin != null;
      final completeManualTime = startHour != null && endHour != null;

      if (anyManualTime && !completeManualTime) {
        throw Exception('Choose both a start and end time, or remove the time range.');
      }

      late final ForecastWindow forecast;
      late final String timingDescription;

      if (completeManualTime) {
        final startMinute = startMin ?? 0;
        final endMinute = endMin ?? 0;
        if (endHour * 60 + endMinute <= startHour * 60 + startMinute) {
          throw Exception('End time must be after start time.');
        }

        forecast = await fetchForecastWindow(
          startHour: startHour,
          endHour: endHour,
        );
        final day = forecast.isTomorrow ? 'tomorrow' : 'today';
        timingDescription =
            'The user selected ${_fmt(startHour, startMinute)} to '
            '${_fmt(endHour, endMinute)} $day. Use this selected clock range.';
      } else {
        // The task may contain a duration such as "2 hours 30 mins".
        // If it doesn't, make a near-term recommendation using the next 3 hours.
        final userDuration = _durationFromTask(task);
        final forecastDuration = userDuration == null
            ? 180
            : userDuration.clamp(1, 24 * 60).toInt();

        forecast = await fetchNextForecastWindow(
          durationMinutes: forecastDuration,
        );

        timingDescription = userDuration == null
            ? 'No clock time or clear duration was selected. Assume the user is '
                'starting soon and assess the next 3 hours.'
            : 'The task text suggests a duration of ${_formatDuration(userDuration)}. '
                'Assume the activity starts soon. The supplied forecast covers '
                'up to the next 24 hours.';
      }

      if (forecast.hours.isEmpty) {
        throw Exception('No forecast available for that time range.');
      }

      final table = forecast.hours.map((h) => h.toPromptLine()).join('\n');
      final prompt = '''
The user's activity, in their own words: $task
Timing: $timingDescription
Hourly forecast for the relevant period:
$table

Assess whether this specific activity is suitable in these weather conditions.
If the user gave a duration in their message, keep it in mind even when no manual
clock-time range was selected. Be practical and specific.
''';

      return askAi(system: _systemPrompt, prompt: prompt);
    });
  }
}

int? _durationFromTask(String task) {
  final text = task.toLowerCase();

  // Prefer explicit numbers, such as "2 hours 30 mins", over vague phrases.
  var totalMinutes = 0;
  final hoursPattern = RegExp(r'(\d+(?:\.\d+)?)\s*(hours?|hrs?|h)\b');
  final minutesPattern = RegExp(r'(\d+(?:\.\d+)?)\s*(minutes?|mins?)\b');

  for (final match in hoursPattern.allMatches(text)) {
    totalMinutes += (double.parse(match.group(1)!) * 60).round();
  }
  for (final match in minutesPattern.allMatches(text)) {
    totalMinutes += double.parse(match.group(1)!).round();
  }
  if (totalMinutes > 0) return totalMinutes;

  if (RegExp(r'\bhalf an hour\b').hasMatch(text)) return 30;
  if (RegExp(r'\b(a few|few) minutes?\b').hasMatch(text)) return 15;
  if (RegExp(r'\b(a couple of|couple of) hours?\b').hasMatch(text)) {
    return 120;
  }
  if (RegExp(r'\b(an hour|one hour)\b').hasMatch(text)) return 60;
  return null;
}

String _formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  if (hours == 0) return '$remainingMinutes minute${remainingMinutes == 1 ? '' : 's'}';
  if (remainingMinutes == 0) return '$hours hour${hours == 1 ? '' : 's'}';
  return '$hours hour${hours == 1 ? '' : 's'} and '
      '$remainingMinutes minute${remainingMinutes == 1 ? '' : 's'}';
}

String _fmt(int hour, int min) {
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  final minute = min.toString().padLeft(2, '0');
  return '$h12:$minute ${hour < 12 ? 'AM' : 'PM'}';
}
