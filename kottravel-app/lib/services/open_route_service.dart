import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../config/api_key.dart';

class OpenRouteService {
  // Add your API key here - you should store this securely in a config file
  // and never commit it to version control
  static const String apiKey = ApiKeys.openRouteService;
  static const String baseUrl = 'https://api.openrouteservice.org';

  // Distance calculation using Haversine formula
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    // Convert latitude and longitude from degrees to radians
    final double lat1 = point1.latitude * (pi / 180);
    final double lon1 = point1.longitude * (pi / 180);
    final double lat2 = point2.latitude * (pi / 180);
    final double lon2 = point2.longitude * (pi / 180);

    // Haversine formula
    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;
    final double a =
        pow(sin(dLat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);
    final double c = 2 * asin(sqrt(a));

    // Distance in kilometers
    return earthRadius * c;
  }

  // Kottakkal coordinates (center point)
  static const double kottakkalLat = 10.9982;
  static const double kottakkalLng = 76.0000;
  static const double searchRadiusKm = 10.0; // 10km radius around Kottakkal

  // Geocode a search query to get location coordinates
  static Future<List<GeocodingResult>> searchLocation(String query) async {
    try {
      // Add Kottakkal as context to the search query and restrict by proximity
      final response = await http.get(
        Uri.parse(
          '$baseUrl/geocode/search?api_key=$apiKey&text=$query, Kottakkal&focus.point.lat=$kottakkalLat&focus.point.lon=$kottakkalLng&boundary.circle.lat=$kottakkalLat&boundary.circle.lon=$kottakkalLng&boundary.circle.radius=$searchRadiusKm',
        ),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;

        final List<GeocodingResult> results = [];

        // Process and filter results
        for (var feature in features) {
          final properties = feature['properties'];
          final geometry = feature['geometry'];
          final coordinates = geometry['coordinates'] as List;

          // Get coordinates (GeoJSON format is [longitude, latitude])
          final LatLng location = LatLng(coordinates[1], coordinates[0]);

          // Calculate distance from Kottakkal center
          final double distanceFromKottakkal = calculateDistance(
            location,
            const LatLng(kottakkalLat, kottakkalLng),
          );

          // Only include results that are within our search radius
          if (distanceFromKottakkal <= searchRadiusKm) {
            // Create result with additional context
            final String name =
                properties['name'] as String? ?? 'Unknown location';
            String label = properties['label'] as String? ?? 'Unknown location';

            // Add distance to the label
            String distanceText = '';
            if (distanceFromKottakkal < 1.0) {
              // If less than 1km, show in meters
              distanceText = '(${(distanceFromKottakkal * 1000).round()} m)';
            } else {
              // Otherwise show in kilometers
              distanceText = '(${distanceFromKottakkal.toStringAsFixed(1)} km)';
            }

            // If Kottakkal is not in the label, append it for context
            if (!label.toLowerCase().contains('kottakkal')) {
              label += ', Kottakkal $distanceText';
            } else {
              label += ' $distanceText';
            }

            results.add(
              GeocodingResult(name: name, label: label, location: location),
            );
          }
        }

        // Sort results by distance from Kottakkal center
        results.sort((a, b) {
          final distA = calculateDistance(
            a.location,
            const LatLng(kottakkalLat, kottakkalLng),
          );

          final distB = calculateDistance(
            b.location,
            const LatLng(kottakkalLat, kottakkalLng),
          );

          return distA.compareTo(distB);
        });

        return results;
      } else {
        throw Exception('Failed to search location: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching location: $e');
      return [];
    }
  }

  // Calculate route between two points
  // Helper method to decode the polyline string
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  static Future<RouteResult?> getRoute({
    required LatLng start,
    required LatLng end,
    String profile =
        'driving-car', // Options: driving-car, foot-walking, cycling-regular
  }) async {
    try {
      final body = jsonEncode({
        'coordinates': [
          [start.longitude, start.latitude],
          [end.longitude, end.latitude],
        ],
        'instructions': true,
        'format': 'json',
      });

      final response = await http.post(
        Uri.parse('$baseUrl/v2/directions/$profile'),
        headers: {
          'Authorization': apiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if there are routes in the response
        if (data['routes'] == null || (data['routes'] as List).isEmpty) {
          return null;
        }

        final route = data['routes'][0];
        final geometry = route['geometry'];
        final summary = route['summary'];

        // Decode the polyline geometry
        final List<LatLng> points = _decodePolyline(geometry);

        return RouteResult(
          points: points,
          distance: summary['distance'].toDouble(), // in meters
          duration: summary['duration'].toDouble(), // in seconds
        );
      } else {
        throw Exception(
          'Failed to get route: ${response.statusCode}, ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error getting route: $e');
      return null;
    }
  }
}

class GeocodingResult {
  final String name;
  final String label;
  final LatLng location;

  GeocodingResult({
    required this.name,
    required this.label,
    required this.location,
  });
}

class RouteResult {
  final List<LatLng> points;
  final double distance; // in meters
  final double duration; // in seconds

  RouteResult({
    required this.points,
    required this.distance,
    required this.duration,
  });

  String get formattedDistance {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    } else {
      return '${distance.toStringAsFixed(0)} m';
    }
  }

  String get formattedDuration {
    final int minutes = (duration / 60).floor();
    final int hours = (minutes / 60).floor();

    if (hours > 0) {
      final int remainingMinutes = minutes % 60;
      return '$hours hr ${remainingMinutes > 0 ? '$remainingMinutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }
}
