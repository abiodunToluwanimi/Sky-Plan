import 'package:geolocator/geolocator.dart';

Position? _cachedPosition;

/// Returns the device location, asking for permission if needed.
/// Cached for the session: the weather background and the AI planner both
/// need it, and there's no reason to hit GPS twice.
Future<Position> getCurrentPosition() async {
  final cached = _cachedPosition;
  if (cached != null) return cached;

  if (!await Geolocator.isLocationServiceEnabled()) {
    throw Exception('Location services are turned off.');
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission was denied.');
    }
  }
  if (permission == LocationPermission.deniedForever) {
    throw Exception(
      'Location permission is permanently denied — enable it in system settings.',
    );
  }

  // Low accuracy is plenty for weather and saves battery.
  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
  );
  return _cachedPosition = position;
}