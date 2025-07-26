import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'congestion_detection_service.dart';

class RouteService {
  // Singleton instance
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal();

  // Congestion detection service
  final CongestionDetectionService _congestionService =
      CongestionDetectionService();

  // Default route state
  bool _isUsingAlternateRoute = false;
  bool _shouldShowRerouteMessage = false;

  // Getters
  bool get isUsingAlternateRoute => _isUsingAlternateRoute;
  bool get shouldShowRerouteMessage => _shouldShowRerouteMessage;

  // Check if we should display alternate route
  void updateRouteStatus({
    required LatLng userLocation,
    required LatLng destination,
    required CongestionLevel currentCongestionLevel,
  }) {
    // Log current status before update
    final bool wasUsingAlternate = _isUsingAlternateRoute;

    debugPrint(
      'Route update: congestion level=${currentCongestionLevel.toString().split('.').last}',
    );

    final shouldReroute = _congestionService.shouldReroute(
      userLocation: userLocation,
      destination: destination,
      congestionLevel: currentCongestionLevel,
    );

    // Update state based on congestion and location
    _isUsingAlternateRoute = shouldReroute;

    // Log route status change
    if (wasUsingAlternate != _isUsingAlternateRoute) {
      debugPrint(
        'Route status changed: now ${_isUsingAlternateRoute ? "USING" : "NOT using"} alternate route',
      );
    }

    // Show message only when switching to alternate route
    if (shouldReroute && !_shouldShowRerouteMessage) {
      _shouldShowRerouteMessage = true;
      debugPrint('Showing reroute message');
    } else if (!shouldReroute) {
      _shouldShowRerouteMessage = false;
    }
  }

  // Get appropriate route points based on current state
  List<LatLng> getCurrentRoutePoints(List<LatLng> normalRoutePoints) {
    if (_isUsingAlternateRoute) {
      return _congestionService.getAlternateRouteCoordinates();
    }

    return normalRoutePoints;
  }

  // Get alternate route coordinates from congestion service
  List<LatLng> getAlternateRouteCoordinates() {
    return _congestionService.getAlternateRouteCoordinates();
  } // Manually toggle between routes (for testing or user preference)

  void toggleAlternateRoute() {
    _isUsingAlternateRoute = !_isUsingAlternateRoute;
    _shouldShowRerouteMessage = _isUsingAlternateRoute;
    debugPrint('Manually toggled alternate route: $_isUsingAlternateRoute');
  }

  // Force showing alternate route (for testing)
  void forceAlternateRoute() {
    _isUsingAlternateRoute = true;
    _shouldShowRerouteMessage = true;
    debugPrint('FORCED alternate route display');
  }

  // Reset route state
  void resetRouteStatus() {
    _isUsingAlternateRoute = false;
    _shouldShowRerouteMessage = false;
    debugPrint('Reset route status');
  }

  // Get color for route display
  Color getRouteColor() {
    return _isUsingAlternateRoute ? Colors.green : Colors.blue;
  }

  // Get route notification message
  String getRouteNotificationMessage(CongestionLevel congestionLevel) {
    if (!_shouldShowRerouteMessage) return '';

    switch (congestionLevel) {
      case CongestionLevel.medium:
        return 'Moderate traffic detected. Taking alternate route via eastern bypass.';
      case CongestionLevel.high:
        return 'Heavy traffic congestion detected. Taking emergency alternate route.';
      default:
        return 'Taking alternate route to avoid traffic.';
    }
  }
}
