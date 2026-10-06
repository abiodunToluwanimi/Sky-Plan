import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sky_plan/services/ai_service.dart';
import 'package:sky_plan/services/forecast_service.dart';

part 'plan_advice_provider.g.dart';

const _systemPrompt = '''
You are a weather planning assistant inside a mobile app.
Reply in plain text only (no markdown, no asterisks, no headings), under 90 words.
Start with one verdict line beginning with ✅ (good), ⚠️ (risky) or ❌ (not suitable).
Then short emoji-led lines covering: the main weather problems for this task,
practical things to do about them, and a better time only if there is a
significantly better one.
''';

/// Holds the AI recommendation. The state is an AsyncValue, so the UI gets
/// loading / error / data for free (the "isLoading" your ToDO mentioned).
@riverpod
class PlanAdvice extends _$PlanAdvice {
  @override
  Future<String?> build() async => null; // nothing requested yet

  Future<void> getAdvice({
    required String task,
    required int startHour,
    required int startMin,
    required int endHour,
    required int endMin,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard<String?>(() async {
      if (endHour * 60 + endMin <= startHour * 60 + startMin) {
        throw Exception('End time must be after start time.');
      }

      final forecast = await fetchForecastWindow(
        startHour: startHour,
        endHour: endHour,
      );
      if (forecast.hours.isEmpty) {
        throw Exception('No forecast available for that time range.');
      }

      final day = forecast.isTomorrow ? 'tomorrow' : 'today';
      final table = forecast.hours.map((h) => h.toPromptLine()).join('\n');

      final prompt = '''
The user wants to do this task: $task
Planned time: ${_fmt(startHour, startMin)} to ${_fmt(endHour, endMin)} $day.

Hourly forecast for that period:
$table

Analyze the weather specifically for this task and time period.
''';

      return askAi(system: _systemPrompt, prompt: prompt);
    });
  }
}

String _fmt(int hour, int min) {
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$h12:${min.toString().padLeft(2, '0')} ${hour < 12 ? 'AM' : 'PM'}';
}