import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sky_plan/services/ai_service.dart';
import 'package:sky_plan/services/forecast_service.dart';

part 'plan_advice_provider.g.dart';

const _systemPrompt = '''
You're a friendly weather buddy inside a mobile app, like a friend who just checked the forecast for them.
Reply in plain text only (no markdown, no asterisks, no headings), under 80 words.

First, answer exactly what the user asked:
- Sun or heat question: give the feels-like temperature and UV level first.
- Rain question: say how heavy it will be (use the mm and the light/moderate/heavy label, not just the chance), and when it peaks.
- "Can I go?" question: open with ✅, ⚠️ or ❌ and one short friendly sentence.

Then add only the tips that matter for their activity: what to bring or wear, and a better time only if it is clearly better. Mention wind only if it is strong (over 30 km/h) or relevant.
Use the real numbers from the forecast instead of vague words.
For short activities (like a 30 minute walk), judge only the part of the hour that overlaps with the activity.
If the user is leaving later (like "class in 2 hours"), tell them what it will be like at that time, and mention the trip there if it matters.
Match the user's tone. If they write casually, be casual.
If forecast values seem to conflict (e.g. drizzle but 0 mm), say it simply, like "maybe a light sprinkle, nothing serious".
Use at most 2 or 3 emojis. Never mention anything that is not in the forecast.
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
        // The task text may say "for 2 hours 30 mins" (a duration) or
        // "in 2 hours" (a start time). Handle both.
        final timing = _timingFromTask(task);
        final startOffset = timing.startOffsetMinutes;
        final duration = (timing.durationMinutes ?? (startOffset > 0 ? 60 : 180))
            .clamp(1, 24 * 60)
            .toInt();

        forecast = await fetchNextForecastWindow(
          durationMinutes: duration,
          startOffsetMinutes: startOffset,
        );
        final label = forecast.windowLabel ?? '';

        if (startOffset > 0) {
          timingDescription =
              'The user needs to be out in ${_formatDuration(startOffset)} '
              '($label). Focus on the weather at that time, and mention the '
              'conditions between now and then if they matter (the table may '
              'include those earlier hours).';
        } else if (timing.durationMinutes != null) {
          timingDescription =
              'The activity starts now and lasts ${_formatDuration(duration)} '
              '($label).';
        } else {
          timingDescription =
              'No clock time or clear duration was given. Assume the user is '
              'starting now and assess the next 3 hours ($label).';
        }
      }

      if (forecast.hours.isEmpty) {
        throw Exception('No forecast available for that time range.');
      }

      final table = forecast.hours.map((h) => h.toPromptLine()).join('\n');
      final prompt = '''
The user's message, in their own words: $task
Timing: $timingDescription
Hourly forecast for the relevant period:
$table

Answer the user's actual question first (heat/sun, how heavy the rain, or whether
they can go), then give practical tips. Respect the timing above.
''';

      return askAi(system: _systemPrompt, prompt: prompt);
    });
  }
}

typedef _Timing = ({int startOffsetMinutes, int? durationMinutes});

/// Splits the task text into "when it starts" and "how long it lasts".
/// "class in 2hrs" -> starts in 120 minutes.
/// "walk for 30 mins" -> lasts 30 minutes, starts now.
_Timing _timingFromTask(String task) {
  var text = task.toLowerCase();
  var startOffset = 0;

  final startPattern = RegExp(
    r'\bin\s+(?:(\d+(?:\.\d+)?)\s*(hours?|hrs?|h|minutes?|mins?)'
    r'|(an hour|half an hour|a couple of hours|a few minutes))\b',
  );
  final match = startPattern.firstMatch(text);

  if (match != null) {
    if (match.group(1) != null) {
      final value = double.parse(match.group(1)!);
      final unit = match.group(2)!;
      startOffset = unit.startsWith('h') ? (value * 60).round() : value.round();
    } else {
      startOffset = switch (match.group(3)) {
        'an hour' => 60,
        'half an hour' => 30,
        'a couple of hours' => 120,
        _ => 15,
      };
    }
    // Remove it so "in 2 hrs" is not also counted as a 2 hour duration.
    text = text.replaceRange(match.start, match.end, ' ');
  }

  return (
    startOffsetMinutes: startOffset.clamp(0, 24 * 60).toInt(),
    durationMinutes: _durationFromTask(text),
  );
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