import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';

class CongestionDetectionService {
  // Singleton instance
  static final CongestionDetectionService _instance =
      CongestionDetectionService._internal();
  factory CongestionDetectionService() => _instance;
  CongestionDetectionService._internal();

  // Camera location and facing direction
  static const LatLng cameraLocation = LatLng(10.9985, 75.9918);
  static const LatLng cameraFacingDirection = LatLng(10.9984, 75.9918);

  // Stream controllers for congestion updates
  final _congestionStreamController =
      StreamController<CongestionAlert>.broadcast();
  Stream<CongestionAlert> get congestionStream =>
      _congestionStreamController.stream;

  // Firebase database reference
  late final DatabaseReference _congestionRef;
  StreamSubscription? _congestionSubscription;
  bool _isInitialized = false;

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase reference to the traffic data for camera_001
      _congestionRef = FirebaseDatabase.instance.ref('traffic_data/camera_001');

      _isInitialized = true;

      // Subscribe to congestion updates
      _congestionSubscription = _congestionRef.onValue.listen(
        (event) {
          final data = event.snapshot.value;
          if (data != null) {
            try {
              // Parse the congestion data from Firebase
              final Map<String, dynamic> trafficData =
                  Map<String, dynamic>.from(data as Map);

              // Extract congestion data
              if (trafficData.containsKey('congestion')) {
                final congestionData = Map<String, dynamic>.from(
                  trafficData['congestion'] as Map,
                );

                // Extract and validate level - critical for rerouting
                final dynamic rawLevel = congestionData['level'];
                final int level =
                    rawLevel is int
                        ? rawLevel
                        : int.tryParse(rawLevel.toString()) ?? 0;

                final String status = congestionData['status'] as String;
                final int vehicleCount =
                    congestionData['vehicle_count_roi'] as int;

                // Log the raw congestion data for debugging
                debugPrint(
                  'Raw congestion data: level=$level (${level.runtimeType}), status=$status, vehicleCount=$vehicleCount',
                );

                // Create an alert for any level (we'll filter display in the UI)
                final CongestionLevel congestionLevel = _convertToLevel(level);
                debugPrint(
                  'Converted congestion level: $congestionLevel (from numeric level $level)',
                );

                // Create congestion alert
                final alert = CongestionAlert(
                  level: congestionLevel,
                  description:
                      "$status: $vehicleCount vehicles detected in camera view",
                  timestamp: DateTime.now(),
                  location: cameraLocation,
                  isActive: true,
                );

                // Broadcast the alert
                _congestionStreamController.add(alert);

                debugPrint(
                  'Received congestion alert: ${alert.level} (Level $level) at ${alert.timestamp}',
                );
              }
            } catch (e) {
              debugPrint('Error parsing congestion data: $e');
            }
          }
        },
        onError: (error) {
          debugPrint('Error listening to congestion updates: $error');
        },
      );

      _isInitialized = true;
      debugPrint('Congestion detection service initialized');
    } catch (e) {
      debugPrint('Error initializing congestion detection service: $e');
      rethrow;
    }
  }

  // Check if the user is near the congested area
  bool isNearCongestion(LatLng userLocation, {double thresholdMeters = 500}) {
    // Calculate distance between user and camera location
    final distance = const Distance().as(
      LengthUnit.Meter,
      userLocation,
      cameraLocation,
    );

    return distance <= thresholdMeters;
  }

  // Calculate if user is heading towards congestion
  bool isHeadingTowardsCongestion(LatLng userLocation, LatLng userHeading) {
    // Implementation of directional awareness would go here
    // This is a simplified check
    final distanceToCongestion = const Distance().as(
      LengthUnit.Meter,
      userLocation,
      cameraLocation,
    );

    final distanceFromHeadingToCongestion = const Distance().as(
      LengthUnit.Meter,
      userHeading,
      cameraLocation,
    );

    // If the distance is decreasing, user is heading towards congestion
    return distanceFromHeadingToCongestion < distanceToCongestion;
  }

  // Update congestion status to Emergency
  Future<bool> updateEmergencyStatus() async {
    try {
      if (!_isInitialized) await initialize();

      // Update the congestion status to Emergency
      await _congestionRef.update({
        'congestion': {
          'status': 'Emergency',
          'level': 3, // High congestion level
        },
      });

      debugPrint('Successfully updated congestion status to Emergency');
      return true;
    } catch (e) {
      debugPrint('Error updating congestion status to Emergency: $e');
      return false;
    }
  }

  // Send a manual congestion report (if we implement user reporting)
  Future<void> reportCongestion(
    CongestionLevel level,
    String description,
  ) async {
    try {
      final alert = CongestionAlert(
        level: level,
        description: description,
        timestamp: DateTime.now(),
        location: cameraLocation,
        isActive: true,
      );

      await _congestionRef.push().set(alert.toJson());
      debugPrint('Congestion report sent');
    } catch (e) {
      debugPrint('Error reporting congestion: $e');
      rethrow;
    }
  }

  // Dispose resources
  void dispose() {
    _congestionSubscription?.cancel();
    _congestionStreamController.close();
  }

  // Check if rerouting is needed based on congestion level and route
  bool shouldReroute({
    required LatLng userLocation,
    required LatLng destination,
    required CongestionLevel congestionLevel,
  }) {
    // Log the input congestion level for debugging
    debugPrint('shouldReroute called with congestion level: $congestionLevel');

    // Force rerouting for debugging - comment out in production
    // return true;

    // Only reroute for moderate (level 2) or high (level 3) congestion
    if (congestionLevel == CongestionLevel.medium) {
      debugPrint('✓ Rerouting due to MEDIUM congestion (level 2)');
      return true;
    } else if (congestionLevel == CongestionLevel.high) {
      debugPrint('✓ Rerouting due to HIGH congestion (level 3)');
      return true;
    } else {
      debugPrint(
        '✗ No rerouting: Congestion level is ${congestionLevel.toString().split('.').last}',
      );
      return false;
    }

    // This line should never be reached
    // return true;
  }

  // Get alternate route coordinates to avoid congestion
  List<LatLng> getAlternateRouteCoordinates() {
    // Return the provided alternate route coordinates
    return [
      LatLng(10.989278, 75.993639), // 10°59'21.4"N 75°59'37.1"E
      LatLng(10.989167, 75.994750), // 10°59'21.0"N 75°59'41.1"E
      LatLng(10.990750, 75.996944), // 10°59'26.7"N 75°59'49.0"E
      LatLng(10.990917, 75.996972), // 10°59'27.3"N 75°59'49.1"E
      LatLng(10.991472, 75.996889), // 10°59'29.3"N 75°59'48.8"E
      LatLng(10.992583, 76.001528), // 10°59'33.3"N 76°00'05.5"E
      LatLng(10.993000, 76.002222), // 10°59'34.7"N 76°00'08.0"E
      LatLng(10.993111, 76.002750), // 10°59'35.2"N 76°00'09.9"E
      LatLng(10.993111, 76.003361), // 10°59'35.2"N 76°00'12.1"E
      LatLng(10.993722, 76.005194), // 10°59'37.4"N 76°00'18.7"E
      LatLng(10.993667, 76.007028), // 10°59'37.2"N 76°00'25.3"E
      LatLng(10.993861, 76.009222), // 10°59'37.9"N 76°00'33.2"E
      LatLng(10.994194, 76.009222), // 10°59'39.1"N 76°00'33.2"E
      LatLng(10.994361, 76.009333), // 10°59'39.7"N 76°00'33.6"E
      LatLng(10.994889, 76.009389), // 10°59'41.6"N 76°00'33.8"E
      LatLng(10.997306, 76.009000), // 10°59'50.3"N 76°00'32.4"E
      LatLng(10.997472, 76.008917), // 10°59'50.9"N 76°00'32.1"E
      LatLng(10.997861, 76.008639), // 10°59'52.3"N 76°00'31.1"E
      LatLng(10.998333, 76.008444), // 10°59'54.0"N 76°00'30.4"E
      LatLng(11.000000, 76.007889), // 11°00'00.0"N 76°00'28.4"E
      LatLng(11.001333, 76.007000), // 11°00'04.8"N 76°00'25.2"E
      LatLng(11.001111, 76.006361), // 11°00'04.0"N 76°00'22.9"E
      LatLng(11.000889, 76.003778), // 11°00'03.2"N 76°00'13.6"E
      LatLng(11.003167, 76.004250), // 11°00'11.4"N 76°00'15.3"E
    ];
  }
}

// Helper method to convert numeric level to CongestionLevel enum
CongestionLevel _convertToLevel(int level) {
  switch (level) {
    case 0:
      return CongestionLevel.low; // No Traffic
    case 1:
      return CongestionLevel.low; // Light Traffic
    case 2:
      return CongestionLevel.medium; // Moderate Congestion
    case 3:
      return CongestionLevel.high; // High Congestion
    default:
      return CongestionLevel.low;
  }
}

// Enum for congestion levels
enum CongestionLevel {
  low,
  medium,
  high,
  severe,
} // Class for congestion alerts

class CongestionAlert {
  final CongestionLevel level;
  final String description;
  final DateTime timestamp;
  final LatLng location;
  final bool isActive;

  CongestionAlert({
    required this.level,
    required this.description,
    required this.timestamp,
    required this.location,
    required this.isActive,
  });

  // Convert from Firebase JSON
  factory CongestionAlert.fromJson(Map<String, dynamic> json) {
    return CongestionAlert(
      level: _parseCongestionLevel(json['level']),
      description: json['description'] ?? 'Traffic congestion detected',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      location: LatLng(
        json['location']?['latitude'] ??
            CongestionDetectionService.cameraLocation.latitude,
        json['location']?['longitude'] ??
            CongestionDetectionService.cameraLocation.longitude,
      ),
      isActive: json['isActive'] ?? true,
    );
  }

  // Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'level': level.toString().split('.').last,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'isActive': isActive,
    };
  }

  static CongestionLevel _parseCongestionLevel(String? value) {
    switch (value?.toLowerCase()) {
      case 'low':
        return CongestionLevel.low;
      case 'medium':
        return CongestionLevel.medium;
      case 'high':
        return CongestionLevel.high;
      case 'severe':
        return CongestionLevel.severe;
      default:
        return CongestionLevel.medium; // Default value
    }
  }
}
