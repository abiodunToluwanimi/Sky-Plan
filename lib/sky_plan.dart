import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sky_plan/provider/plan_advice_provider.dart';
import 'package:sky_plan/provider/weather_provider.dart';

class SkyPlan extends ConsumerStatefulWidget {
  final String selectedButton;
  bool showContainer = false;

   SkyPlan({super.key, required this.selectedButton, required showContainer});

  @override
  ConsumerState<SkyPlan> createState() => _SkyPlanState();
}

class _SkyPlanState extends ConsumerState<SkyPlan> {
  @override
  Widget build(BuildContext context) {
    final weatherdata = ref.watch(weatherProvider);
    final advice = ref.watch(planAdviceProvider);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        // Blurs the background directly behind this specific widget
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Material(
          // A semi-transparent color for the glass effect
          color: Colors.white.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                   Center(
                     child: Text(
                       widget.selectedButton,
                       style: const TextStyle(
                         fontSize: 23,
                         color: Colors.white,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'How long?',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),
                // 1.
                Row(
                  children: [
                    const Text(
                      'from:  ',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async{
                        final time = await showTimePicker(
                          context: context,
                           initialTime: TimeOfDay.now()
                           );
                           if (time != null){
                            ref.read(weatherProvider.notifier).selectStartTime(time.hour, time.minute);
                           }
                      },
                      child: Text(
                        weatherdata.startHour == null
                        ? 'Set Time'
                        : TimeOfDay(hour: weatherdata.startHour!, minute: weatherdata.startMin!).format(context)
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Icon(Icons.arrow_downward, size: 20),
                const SizedBox(height: 10),
                // 2.
                Row(
                  children: [
                    const Text(
                      'to:  ',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async{
                        final time2 = await showTimePicker(
                          context: context, 
                          initialTime: TimeOfDay.now()
                          );
                          if(time2 != null){
                          ref.read(weatherProvider.notifier).selectEndTime(time2.hour, time2.minute);
                          }
                      },
                      child: Text(
                        weatherdata.endHour == null
                        ? 'Set time'
                        : TimeOfDay(hour: weatherdata.endHour!, minute: weatherdata.endMin!).format(context)
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    // Disabled while a request is in flight (no double taps)
                    onPressed: advice.isLoading
                        ? null
                        : () {
                            if (weatherdata.startHour == null ||
                                weatherdata.endHour == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pick a start and end time first'),
                                ),
                              );
                              return;
                            }
                            ref.read(planAdviceProvider.notifier).getAdvice(
                                  task: widget.selectedButton,
                                  startHour: weatherdata.startHour!,
                                  startMin: weatherdata.startMin ?? 0,
                                  endHour: weatherdata.endHour!,
                                  endMin: weatherdata.endMin ?? 0,
                                );
                          },
                    child: const Text('Can you?'),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Weather Assistant:',
                  style: TextStyle(color: Colors.grey),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 50),
                  child: advice.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (e, _) => Text(
                      e.toString().replaceFirst('Exception: ', ''),
                      style: TextStyle(color: Colors.red[200]),
                    ),
                    data: (text) => Text(
                      text ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}