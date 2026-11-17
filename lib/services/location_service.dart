import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class CurrentLocationInfo {
  final double latitude;
  final double longitude;
  final String placeName;

  const CurrentLocationInfo({
    required this.latitude,
    required this.longitude,
    required this.placeName,
  });
}

class LocationService {
  static final Geocoding _geocoding = Geocoding();

  static Future<CurrentLocationInfo> getCurrentLocation() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Turn on your phone location services and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(
        'Allow Sky Plan to access your location in Settings.',
      );
    }

    // Get the current GPS/network position.
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );

    var placeName = 'Current location';

    // Convert coordinates into a readable place name.
    try {
      final placemarks =
          await _geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        placeName = _firstAvailable([
              place.subAdministrativeArea,
              place.locality,
              place.subLocality,
              place.administrativeArea,
            ]) ??
            'Current location';
      }
    } catch (_) {
      // Keep the coordinates even if address lookup fails.
      placeName = 'Current location';
    }

    return CurrentLocationInfo(
      latitude: position.latitude,
      longitude: position.longitude,
      placeName: placeName,
    );
  }

  static String? _firstAvailable(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }
}