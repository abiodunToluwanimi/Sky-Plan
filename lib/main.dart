import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_weather_bg/flutter_weather_bg.dart';
import 'package:sky_plan/provider/plan_advice_provider.dart';
import 'package:sky_plan/provider/weather_provider.dart';
import 'package:sky_plan/sky_plan.dart';
import 'package:sky_plan/model/weather_type_mapper.dart';
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
  // FIX 2: Return ConsumerState<HomePage> instead of _HomePageState
  ConsumerState<HomePage> createState() => _HomePageState();
}

// FIX 3: Extend ConsumerState<HomePage> instead of State<HomePage>
class _HomePageState extends ConsumerState<HomePage> {
  late ScrollController _scrollController;
  double _overlayOpacity = 0.0;
  final double _maxScrollToFade = 300.0;

  String selectedButton = '';
  bool showContainer = false;

  void tappedButton(String text) {
    // New task picked: clear the previous task's recommendation
    ref.invalidate(planAdviceProvider);
    setState(() {
      selectedButton = text;
      showContainer = true;
    });
    
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Kick off the location + Open-Meteo fetch once the first frame is up.
    // Wrapped in a callback because ref isn't safe to use for side effects
    // during initState itself.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(weatherProvider.notifier).fetchLiveWeather().catchError((e) {
        // TODO: surface this properly (snackbar / retry banner) once you
        // decide how you want location-denied / offline states to look.
        debugPrint('fetchLiveWeather failed: $e');
      });
    });
  }

  void _onScroll() {
    double newOpacity = (_scrollController.offset / _maxScrollToFade).clamp(0.0, 1.0);
    
    if (newOpacity != _overlayOpacity) {
      setState(() {
        _overlayOpacity = newOpacity;
      });
    }
  }

  @override
  //for when i move to a newpage
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // provider call
    final weatherData = ref.watch(weatherProvider);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Base Layer: The Background Image
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
          
          // 2. Middle Layer: The Solid Color Overlay that fades in
          Positioned.fill(
            child: Opacity(
              opacity: _overlayOpacity,
              child: Container(
                color: const Color.fromARGB(255, 96, 77, 126),
              ),
            ),
          ),
          
          // 3. Top Layer: The Scrollable Content
          ListView(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 440, left: 20, right: 20, bottom: 40),
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
              
              const Text(
                'Going to?',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              //i could actually put a textBar here for the user to actaully say what they wanna do,
              //and maybe howlong
              //then ai takes the task condition and it check if its the best thing to do under the weather condition

              // THE FIX: GridView tailored for a ListView
              GridView.count(
                crossAxisCount: 2, // Forces exactly 2 items per row
                shrinkWrap: true, // Prevents infinite height errors inside ListView
                physics: const NeverScrollableScrollPhysics(), // Lets the parent ListView handle the scrolling
                crossAxisSpacing: 16, // Horizontal space between boxes
                mainAxisSpacing: 16, // Vertical space between boxes
                childAspectRatio: 1.2, // Adjust this decimal to make boxes taller or shorter
                children: [
                  TaskBox(
                    title: 'Work',
                    icon: Icons.work_outline,
                    onTap: () {
                      tappedButton('Work');
                    },
                  ),
                  TaskBox(
                    title: 'Travelling',
                    icon: Icons.airplanemode_active,
                    onTap: () {
                      tappedButton('Travelling');
                    },
                  ),
                  TaskBox(
                    title: 'Walk',
                    icon: Icons.directions_walk,
                    onTap: () {
                      tappedButton('Walk');
                    },
                  ),
                  TaskBox(
                    title: 'The Gym',
                    icon: Icons.fitness_center,
                    onTap: () {
                      tappedButton('The Gym');
                    },
                  ),
                ],
              ),
              SizedBox(height: 20,),

              //conditional Ui
              if(showContainer)SkyPlan(
                selectedButton: selectedButton,
                showContainer: showContainer,
                ),
            ],
          ),
        ],
      ),
    );
  }
}