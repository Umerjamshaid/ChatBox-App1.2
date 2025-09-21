// lib/services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? country;
  final DateTime timestamp;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.country,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'country': country,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: json['latitude'],
      longitude: json['longitude'],
      address: json['address'],
      city: json['city'],
      country: json['country'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  // Calculate distance between two locations in kilometers
  double distanceTo(LocationData other) {
    return Geolocator.distanceBetween(
          latitude,
          longitude,
          other.latitude,
          other.longitude,
        ) /
        1000; // Convert to kilometers
  }
}

class LocationService {
  // Check location permissions
  Future<bool> checkLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  // Request location permissions
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  // Get current location
  Future<LocationData?> getCurrentLocation() async {
    try {
      // Check permissions first
      if (!await checkLocationPermission()) {
        if (!await requestLocationPermission()) {
          throw Exception('Location permission denied');
        }
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Get address
      String? address;
      String? city;
      String? country;

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          address = placemark.street;
          city = placemark.locality;
          country = placemark.country;
        }
      } catch (e) {
        // Address lookup failed, continue without address
        print('Address lookup failed: $e');
      }

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        city: city,
        country: country,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Get location updates (stream)
  Stream<LocationData> getLocationUpdates() async* {
    if (!await checkLocationPermission()) {
      if (!await requestLocationPermission()) {
        throw Exception('Location permission denied');
      }
    }

    await for (final position in Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Update every 100 meters
      ),
    )) {
      String? address;
      String? city;
      String? country;

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          address = placemark.street;
          city = placemark.locality;
          country = placemark.country;
        }
      } catch (e) {
        // Address lookup failed
      }

      yield LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        city: city,
        country: country,
        timestamp: DateTime.now(),
      );
    }
  }

  // Calculate distance between two points
  double calculateDistance(LocationData point1, LocationData point2) {
    return point1.distanceTo(point2);
  }

  // Find users within radius (this would typically be done on backend)
  List<Map<String, dynamic>> findNearbyUsers(
    LocationData currentLocation,
    List<Map<String, dynamic>> allUsers,
    double radiusKm,
  ) {
    return allUsers.where((user) {
      if (user['location'] == null) return false;

      final userLocation = LocationData.fromJson(user['location']);
      final distance = currentLocation.distanceTo(userLocation);

      return distance <= radiusKm;
    }).toList();
  }

  // Get location settings status
  Future<LocationPermission> checkLocationSettings() async {
    return await Geolocator.checkPermission();
  }

  // Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  // Open app settings
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }
}
