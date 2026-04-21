import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Shared GPS helper — call [getLocation] and pass callbacks for the result.
class GpsService {
  GpsService._();

  /// Requests GPS location, reverse-geocodes it, and fires callbacks.
  /// [onSuccess] receives (lat, lon, locationName) where locationName is a
  /// human-readable string like "Kandy, Central Province".
  static Future<void> getLocation(
    BuildContext context, {
    required void Function(double lat, double lon, String locationName) onSuccess,
    required void Function() onLoadingStart,
    required void Function() onLoadingEnd,
  }) async {
    onLoadingStart();

    try {
      // 1. Check if location services are enabled (skip on web)
      if (!kIsWeb) {
        try {
          final serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            onLoadingEnd();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('GPS is disabled. Please turn on Location Services.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }
        } catch (_) {
          // some platforms don't support this check — continue
        }
      }

      // 2. Check / request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          onLoadingEnd();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        onLoadingEnd();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Location permission permanently denied. Enable it in app settings.'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        return;
      }

      // 3. Get GPS position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // 4. Reverse geocode → human-readable name
      final locationName = await _reverseGeocode(position.latitude, position.longitude);

      onLoadingEnd();
      if (context.mounted) {
        onSuccess(position.latitude, position.longitude, locationName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 $locationName'),
            backgroundColor: const Color(0xFF2A7525),
          ),
        );
      }
    } catch (e) {
      onLoadingEnd();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Calls OpenStreetMap Nominatim reverse geocoding API.
  /// Returns a clean location string like "Kandy, Central Province".
  static Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse'
          '?format=json&lat=$lat&lon=$lon&zoom=10&addressdetails=1');

      final response = await http.get(uri, headers: {
        'User-Agent': 'AgriSenseLK/1.0 (agrisense@agrisense.lk)',
        'Accept-Language': 'en',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>? ?? {};

        // Build a clean "City, Province" label
        final city = addr['city']
            ?? addr['town']
            ?? addr['village']
            ?? addr['suburb']
            ?? addr['county']
            ?? '';
        final state = addr['state'] ?? '';

        if (city.isNotEmpty && state.isNotEmpty) return '$city, $state';
        if (city.isNotEmpty) return city.toString();
        if (state.isNotEmpty) return state.toString();

        // Fallback: take first two parts of display_name
        final display = data['display_name']?.toString() ?? '';
        final parts = display.split(',').map((s) => s.trim()).toList();
        if (parts.length >= 2) return '${parts[0]}, ${parts[1]}';
        return display.isNotEmpty ? display : '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
      }
    } catch (_) {
      // Geocoding failed — fall back to coordinate string
    }
    return '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
  }
}
