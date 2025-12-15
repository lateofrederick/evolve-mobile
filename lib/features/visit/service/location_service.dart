import 'package:geolocator/geolocator.dart';

class LocationService {
  /// returns Position(latitude, longitude)
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if GPS service is enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    // 2. Check Permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // 3. Get Position (High accuracy is vital for geofencing)
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}