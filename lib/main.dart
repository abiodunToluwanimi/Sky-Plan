import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_weather_bg/flutter_weather_bg.dart';
import 'package:sky_plan/model/weather_type_mapper.dart';
import 'package:sky_plan/provider/plan_advice_provider.dart';
import 'package:sky_plan/provider/weather_provider.dart';
import 'package:sky_plan/sky_plan.dart';
import 'package:sky_plan/widgets/tasks_box.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final ScrollController _scrollController;
  final TextEditingController _customTaskController = TextEditingController();

  double _overlayOpacity = 0.0;
  final double _maxScrollToFade = 300.0;

  String selectedButton = '';
  bool showContainer = false;
  bool _isCustomMode = false;
  bool _hasSubmittedCustomTask = false;
  TimeOfDay? _customStartTime;
  TimeOfDay? _customEndTime;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(weatherProvider.notifier).fetchLiveWeather().catchError((error) {
        debugPrint('fetchLiveWeather failed: $error');
      });
    });
  }

  void _onScroll() {
    final newOpacity =
        (_scrollController.offset / _maxScrollToFade).clamp(0.0, 1.0);
    if (newOpacity != _overlayOpacity) {
      setState(() => _overlayOpacity = newOpacity);
    }
  }

  void tappedButton(String text) {
    ref.invalidate(planAdviceProvider);
    ref.read(weatherProvider.notifier).clearSelectedTimes();
    FocusScope.of(context).unfocus();
    setState(() {
      selectedButton = text;
      showContainer = true;
      _isCustomMode = false;
      _hasSubmittedCustomTask = false;
      _customTaskController.clear();
      _customStartTime = null;
      _customEndTime = null;
    });
  }

  void _enterCustomMode() {
    if (_isCustomMode) return;

    ref.invalidate(planAdviceProvider);
    ref.read(weatherProvider.notifier).clearSelectedTimes();
    setState(() {
      _isCustomMode = true;
      selectedButton = '';
      showContainer = false;
      _hasSubmittedCustomTask = false;
      _customStartTime = null;
      _customEndTime = null;
    });
  }

  void _resetPlanner() {
    FocusScope.of(context).unfocus();
    ref.invalidate(planAdviceProvider);
    ref.read(weatherProvider.notifier).clearSelectedTimes();
    setState(() {
      selectedButton = '';
      showContainer = false;
      _isCustomMode = false;
      _hasSubmittedCustomTask = false;
      _customTaskController.clear();
      _customStartTime = null;
      _customEndTime = null;
    });
  }

  Future<void> _showTimingOptions() async {
    _enterCustomMode();
    var draftStart = _customStartTime;
    var draftEnd = _customEndTime;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF342C49),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, modalSetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add a time range (optional)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'You can also describe a duration in your message, e.g. “for 2 hours 30 minutes”.',
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.play_arrow, color: Colors.white),
                      title: const Text('Start time',
                          style: TextStyle(color: Colors.white)),
                      trailing: Text(
                        draftStart?.format(sheetContext) ?? 'Choose',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: sheetContext,
                          initialTime: draftStart ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          modalSetState(() => draftStart = picked);
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.flag_outlined, color: Colors.white),
                      title: const Text('End time',
                          style: TextStyle(color: Colors.white)),
                      trailing: Text(
                        draftEnd?.format(sheetContext) ?? 'Choose',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: sheetContext,
                          initialTime: draftEnd ??
                              (draftStart ?? TimeOfDay.now()),
                        );
                        if (picked != null) {
                          modalSetState(() => draftEnd = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _customStartTime = null;
                              _customEndTime = null;
                            });
                            Navigator.of(sheetContext).pop();
                          },
                          child: const Text('Clear time'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _customStartTime = draftStart;
                              _customEndTime = draftEnd;
                            });
                            Navigator.of(sheetContext).pop();
                          },
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sendCustomTask() async {
    final task = _customTaskController.text.trim();
    if (task.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tell Sky Plan what you want to do first.')),
      );
      return;
    }

    if ((_customStartTime == null) != (_customEndTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose both a start and end time, or clear the time range.'),
        ),
      );
      return;
    }

    if (_customStartTime != null && _customEndTime != null) {
      final start = _customStartTime!.hour * 60 + _customStartTime!.minute;
      final end = _customEndTime!.hour * 60 + _customEndTime!.minute;
      if (end <= start) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time.')),
        );
        return;
      }
    }

    FocusScope.of(context).unfocus();
    setState(() => _hasSubmittedCustomTask = true);

    await ref.read(planAdviceProvider.notifier).getAdvice(
          task: task,
          startHour: _customStartTime?.hour,
          startMin: _customStartTime?.minute,
          endHour: _customEndTime?.hour,
          endMin: _customEndTime?.minute,
        );
  }

  Widget _buildCustomComposer(bool isLoading) {
    final selectedTime = _customStartTime != null && _customEndTime != null
        ? '${_customStartTime!.format(context)} – ${_customEndTime!.format(context)}'
        : 'Time is optional';

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _customTaskController,
                onTap: _enterCustomMode,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Tell me what you want to do...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Add a time range',
                    onPressed: _showTimingOptions,
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      selectedTime,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send to Weather Assistant',
                    onPressed: isLoading ? null : _sendCustomTask,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFDED3FF),
                      foregroundColor: const Color(0xFF342C49),
                    ),
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAnswer(AsyncValue<String?> advice) {
    if (!_hasSubmittedCustomTask) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weather Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                advice.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                  error: (error, _) => Text(
                    error.toString().replaceFirst('Exception: ', ''),
                    style: const TextStyle(color: Color(0xFFFFC4C4), height: 1.4),
                  ),
                  data: (text) => Text(
                    text ?? '',
                    style: const TextStyle(color: Colors.white, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _customTaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weatherData = ref.watch(weatherProvider);
    final advice = ref.watch(planAdviceProvider);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: WeatherBg(
              weatherType: weatherTypeFromWmoCode(
                weatherData.weatherCode,
                isDay: weatherData.isDay,
              ),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: _overlayOpacity,
              child: Container(color: const Color.fromARGB(255, 96, 77, 126)),
            ),
          ),
          ListView(
            controller: _scrollController,
            padding: const EdgeInsets.only(
              top: 440,
              left: 20,
              right: 20,
              bottom: 40,
            ),
            children: [
              Center(
                child: Text(
                  '${weatherData.temperature}°C',
                  style: const TextStyle(
                    fontSize: 50,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  weatherData.condition,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Going to?',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_isCustomMode || selectedButton.isNotEmpty || showContainer)
                    IconButton(
                      tooltip: 'Reset planner',
                      onPressed: _resetPlanner,
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    ),
                ],
              ),
              if (!_isCustomMode) ...[
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    TaskBox(
                      title: 'Work',
                      icon: Icons.work_outline,
                      onTap: () => tappedButton('Work'),
                    ),
                    TaskBox(
                      title: 'Travelling',
                      icon: Icons.airplanemode_active,
                      onTap: () => tappedButton('Travelling'),
                    ),
                    TaskBox(
                      title: 'Walk',
                      icon: Icons.directions_walk,
                      onTap: () => tappedButton('Walk'),
                    ),
                    TaskBox(
                      title: 'The Gym',
                      icon: Icons.fitness_center,
                      onTap: () => tappedButton('The Gym'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (showContainer)
                  SkyPlan(
                    selectedButton: selectedButton,
                    showContainer: showContainer,
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Or describe your own plan',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 10),
              ] else ...[
                const SizedBox(height: 12),
                const Text(
                  'What do you have planned?',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 10),
              ],
              KeyedSubtree(
                key: const ValueKey('customTaskComposer'),
                child: _buildCustomComposer(advice.isLoading),
              ),
              if (_isCustomMode) _buildCustomAnswer(advice),
            ],
          ),
        ],
      ),
    );
  }
}
