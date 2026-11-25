import 'package:geolocator/geolocator.dart';
import '../domain/duplicate_detector.dart';
import '../domain/models.dart';
import 'seed_data.dart';

class LocationResult {
  const LocationResult({
    required this.location,
    required this.ward,
    required this.isLiveGps,
  });

  final LatLng location;
  final Ward ward;
  final bool isLiveGps;
}

abstract interface class LocationService {
  Future<LocationResult> getCurrentLocation();
  Ward resolveWard(LatLng location);
}

class DeviceLocationService implements LocationService {
  static const LatLng _chennaiFallback = LatLng(13.0827, 80.2707);

  @override
  Future<LocationResult> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _fallback();
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _fallback();
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );
      final coords = LatLng(pos.latitude, pos.longitude);
      return LocationResult(
        location: coords,
        ward: resolveWard(coords),
        isLiveGps: true,
      );
    } catch (_) {
      return _fallback();
    }
  }

  LocationResult _fallback() => LocationResult(
        location: _chennaiFallback,
        ward: resolveWard(_chennaiFallback),
        isLiveGps: false,
      );

  @override
  Ward resolveWard(LatLng location) {
    var best = SeedData.wards.first;
    var bestDist = double.infinity;
    for (final w in SeedData.wards) {
      final d = DuplicateDetector.haversineMetres(
        location.latitude,
        location.longitude,
        w.centroid.latitude,
        w.centroid.longitude,
      );
      if (d < bestDist) {
        bestDist = d;
        best = w;
      }
    }
    return best;
  }
}
