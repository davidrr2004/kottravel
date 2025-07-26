import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/floating_bottom_navbar.dart';
import '../widgets/location_search_bar.dart';
import '../utils/responsive.dart';
import '../services/congestion_detection_service.dart';
import '../services/route_service.dart';
import '../widgets/congestion_marker.dart';
import 'account_screen.dart';
import 'report_screen.dart';
import 'home_content_screen.dart';
import 'alert_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Screens that will be shown in the app
  final List<Widget> _screens = [
    const HomeContentPage(),
    const AlertScreen(),
    const ReportScreen(),
    const AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Ensure widget is ready for interaction by forcing a rebuild after initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Pre-render a plain colored background for immediate visual feedback
          Container(color: Colors.grey[200]),

          // The map is the base layer - fully interactive
          const _MapBackground(),

          // No gesture interceptor for home screen to allow map interactions

          // Content screens for other tabs
          Positioned.fill(
            child: Offstage(
              offstage: _currentIndex == 0,
              child: IndexedStack(
                index: _currentIndex > 0 ? _currentIndex - 1 : 0,
                children: _screens.sublist(1),
              ),
            ),
          ),

          // Bottom navigation bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FloatingBottomNavbar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() => _currentIndex = index);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MapBackground extends StatefulWidget {
  const _MapBackground();

  @override
  State<_MapBackground> createState() => _MapBackgroundState();
}

class _MapBackgroundState extends State<_MapBackground> {
  // Controller for programmatic map control
  late final MapController _mapController;

  // User location tracking
  LatLng? _userLocation;
  StreamSubscription<Position>? _positionStream;
  bool _locationPermissionChecked = false;

  // Destination and route
  LatLng? _destinationLocation;
  List<LatLng> _routePoints = [];

  // Congestion monitoring
  final CongestionDetectionService _congestionService =
      CongestionDetectionService();
  CongestionAlert? _activeCongestionAlert;
  StreamSubscription? _congestionSubscription;

  // Route management
  final RouteService _routeService = RouteService();
  bool _isShowingAlternateRoute = false;

  // Pre-computed Kottakkal points to avoid recalculating
  static const LatLng kottakkalCenter = LatLng(10.9982, 76.0000);

  // Kottakkal boundary points (~0.5km radius)
  static final LatLng kottakkalSW = LatLng(10.9937, 75.9955);
  static final LatLng kottakkalNE = LatLng(11.0027, 76.0045);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Initialize map immediately to speed up loading
    _fastInitMap();

    // Setup location tracking with a small delay to ensure the widget is fully built
    Future.delayed(const Duration(milliseconds: 500), () {
      _setupLocationTracking();
      _initializeCongestionMonitoring();
    });
  }

  // Initialize the congestion monitoring service
  Future<void> _initializeCongestionMonitoring() async {
    try {
      await _congestionService.initialize();

      // Listen for congestion alerts
      _congestionSubscription = _congestionService.congestionStream.listen((
        alert,
      ) {
        setState(() {
          _activeCongestionAlert = alert;

          // Check if we need to show alternate route based on congestion level
          if (_destinationLocation != null) {
            _checkAndShowAlternateRoute(alert);
          }
        });

        // Show notification if user is near congestion
        if (_userLocation != null &&
            _congestionService.isNearCongestion(_userLocation!)) {
          _showCongestionNotification(alert);
        }
      });

      debugPrint('Congestion monitoring initialized');
    } catch (e) {
      debugPrint('Error initializing congestion monitoring: $e');
    }
  }

  // Check if we need to show an alternate route based on congestion
  void _checkAndShowAlternateRoute(CongestionAlert alert) {
    debugPrint(
      'Checking alternate route for congestion level: ${alert.level.toString().split('.').last}',
    );

    if (_userLocation == null || _destinationLocation == null) {
      setState(() {
        _isShowingAlternateRoute = false;
      });
      debugPrint(
        'Cannot check for alternate route: user or destination location is null',
      );
      return;
    }

    debugPrint(
      'User location: ${_userLocation!.latitude}, ${_userLocation!.longitude}',
    );
    debugPrint(
      'Destination: ${_destinationLocation!.latitude}, ${_destinationLocation!.longitude}',
    );

    // Update route status using RouteService
    _routeService.updateRouteStatus(
      userLocation: _userLocation!,
      destination: _destinationLocation!,
      currentCongestionLevel: alert.level,
    );

    // Update state based on route service
    final bool wasShowingAlternateRoute = _isShowingAlternateRoute;
    setState(() {
      _isShowingAlternateRoute = _routeService.isUsingAlternateRoute;
    });

    if (_isShowingAlternateRoute != wasShowingAlternateRoute) {
      debugPrint('Alternate route display changed: $_isShowingAlternateRoute');
    }

    // Show notification if rerouting
    if (_routeService.shouldShowRerouteMessage && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_routeService.getRouteNotificationMessage(alert.level)),
          duration: const Duration(seconds: 8),
          backgroundColor: Colors.deepOrange,
        ),
      );

      debugPrint(
        'Created alternate route using RouteService - showing notification',
      );
    }
  }

  // Show notification about congestion
  void _showCongestionNotification(CongestionAlert alert) {
    if (!mounted) return;

    // Only show popup for medium and high congestion (levels 2 and 3)
    if (alert.level == CongestionLevel.medium ||
        alert.level == CongestionLevel.high) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    alert.level == CongestionLevel.high
                        ? Icons.warning_amber_rounded
                        : Icons.info,
                    color: _getCongestionColor(alert.level),
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Text('Traffic Alert'),
                ],
              ),
              content: Text(
                'Traffic Alert: ${_getCongestionText(alert.level)} ahead.',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('DISMISS'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showCongestionDetails(alert);
                  },
                  child: Text('VIEW DETAILS'),
                ),
              ],
            ),
      );
    }
    // For other levels, do nothing
  }

  // Show detailed information about congestion
  void _showCongestionDetails(CongestionAlert alert) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => CongestionAlertDialog(alert: alert),
    );
  }

  // Get the color for a congestion level
  Color _getCongestionColor(CongestionLevel level) {
    switch (level) {
      case CongestionLevel.low:
        return Colors.green;
      case CongestionLevel.medium:
        return Colors.orange;
      case CongestionLevel.high:
        return Colors.red;
      case CongestionLevel.severe:
        return Colors.purple;
    }
  }

  // Get the text description for a congestion level
  String _getCongestionText(CongestionLevel level) {
    switch (level) {
      case CongestionLevel.low:
        return 'Light Traffic';
      case CongestionLevel.medium:
        return 'Moderate Traffic';
      case CongestionLevel.high:
        return 'Heavy Traffic';
      case CongestionLevel.severe:
        return 'Severe Congestion';
    }
  }

  void _fastInitMap() {
    // Use a single post-frame callback with simpler approach to avoid race conditions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Move to center position with default zoom
      _mapController.move(kottakkalCenter, 14.0);

      // Then trigger a rebuild to ensure everything is properly laid out
      setState(() {});
    });
  }

  // Setup location tracking with proper permission handling
  Future<void> _setupLocationTracking() async {
    if (!mounted) return;

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location services are disabled. Please enable them in your device settings.',
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
        _locationPermissionChecked = true;
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          // Permission still denied
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permissions are denied. Your current location cannot be shown.',
                ),
                duration: Duration(seconds: 5),
              ),
            );
          }
          _locationPermissionChecked = true;
          return;
        }
      }

      // Permission permanently denied
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permissions are permanently denied. Please enable them in app settings.',
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
        _locationPermissionChecked = true;
        return;
      }

      // Get initial position
      _locationPermissionChecked = true;
      try {
        final initialPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );

        if (mounted) {
          setState(() {
            _userLocation = LatLng(
              initialPosition.latitude,
              initialPosition.longitude,
            );
            debugPrint('Initial user location: $_userLocation');
          });
        }
      } catch (e) {
        debugPrint('Error getting initial position: $e');
      }

      // Start position stream
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update when moved 10 meters
        ),
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            _userLocation = LatLng(position.latitude, position.longitude);
            debugPrint('Updated user location: $_userLocation');
          });
        }
      });
    } catch (e) {
      debugPrint('Error in location setup: $e');
    }
  }

  // Show emergency confirmation dialog
  void _showEmergencyConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Emergency Alert'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to declare an emergency at this location?',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'This will alert all nearby users and emergency services.',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
              },
              child: Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 2,
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close dialog

                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 16),
                        Text('Sending emergency alert...'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.red.shade700,
                  ),
                );

                // Update status to Emergency
                bool success = await _congestionService.updateEmergencyStatus();

                // Show result notification
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Emergency alert sent successfully'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send emergency alert'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: Text('CONFIRM EMERGENCY'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Cancel position stream
    _positionStream?.cancel();
    _congestionSubscription?.cancel();
    _mapController.dispose();
    _congestionService.dispose();
    super.dispose();
  }

  // Build the user location marker with pulsing animation effect
  Widget _buildUserLocationMarker() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.2),
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse effect
            if (value > 1.0)
              Container(
                width: 24 * value,
                height: 24 * value,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.3 / value),
                  shape: BoxShape.circle,
                ),
              ),

            // Main blue dot
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),

            // Center white dot
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      },
      onEnd: () {
        // Rebuild to continue animation if widget is still mounted
        if (mounted) setState(() {});
      },
    );
  }

  // Method to focus the map on user location or try to get it first
  void _centerOnUserLocation() async {
    if (_userLocation != null) {
      // If we already have location, just move the map
      _mapController.move(_userLocation!, 15.0);
      return;
    }

    // If location permission hasn't been checked yet, check it now
    if (!_locationPermissionChecked) {
      await _setupLocationTracking();
    }

    // Try to get location one more time
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });

        // Move map to the location
        _mapController.move(_userLocation!, 15.0);
      }
    } catch (e) {
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not access your current location'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Method to handle selected location from search
  void _onLocationSelected(LatLng location) {
    setState(() {
      _destinationLocation = location;
      // Clear previous route when a new location is selected
      _routePoints = [];
    });

    // Move map to show the selected location
    _mapController.move(location, 15.0);
  }

  // Method to handle route data
  void _onRouteFound(List<LatLng> routePoints) {
    setState(() {
      _routePoints = routePoints;
    });

    // Adjust map to show the entire route
    if (routePoints.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(routePoints);
      _mapController.fitBounds(
        bounds,
        options: const FitBoundsOptions(padding: EdgeInsets.all(50.0)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Center of Kottakkal
    const LatLng kottakkalCenter = LatLng(10.9982, 76.0000);

    // Create bounds around Kottakkal with some padding to prevent constraint errors
    // We'll make the bounds slightly larger than our desired visible area
    final LatLng paddedSW = LatLng(
      kottakkalSW.latitude - 0.075,
      kottakkalSW.longitude - 0.075,
    );
    final LatLng paddedNE = LatLng(
      kottakkalNE.latitude + 0.075,
      kottakkalNE.longitude + 0.075,
    );
    final LatLngBounds kottakkalBounds = LatLngBounds(paddedSW, paddedNE);

    return Stack(
      children: [
        // Map container
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: kottakkalCenter,
            initialZoom:
                14.0, // Slightly higher zoom to focus more on Kottakkal
            minZoom: 13, // Higher minimum zoom to prevent zooming out too far
            maxZoom: 18,
            // Explicitly enable all interactions for map movement and zoom
            interactiveFlags: InteractiveFlag.all,
            // Use a more flexible bounds constraint with padding
            cameraConstraint: CameraConstraint.containCenter(
              bounds: kottakkalBounds,
            ),
            keepAlive: true, // Ensure map stays alive for better performance
            // Enable tap handler for better interaction
            onTap: (_, __) => setState(() {}), // Force rebuild on tap
          ),
          children: [
            // Optimized map layer with aggressive caching
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'dev.kottravel.app',
              // Optimize tile loading
              tileProvider: NetworkTileProvider(
                headers: {
                  // Add headers to enable aggressive caching
                  'Cache-Control': 'max-age=2592000', // 30 days
                  'Pragma': 'cache',
                },
              ),
              maxNativeZoom: 19,
              backgroundColor:
                  Colors.white, // Provide background color for unloaded areas
              // Performance optimizations
              keepBuffer: 5, // Keep more tiles in memory
              tileSize: 256, // Standard tile size
            ),

            // Draw route polylines
            PolylineLayer(
              polylines: [
                // Main route polyline
                if (_routePoints.isNotEmpty)
                  Polyline(
                    points: _routePoints,
                    color:
                        _routeService.isUsingAlternateRoute
                            ? Colors.grey
                            : Colors.blue,
                    strokeWidth:
                        _routeService.isUsingAlternateRoute ? 3.0 : 4.0,
                    gradientColors:
                        _routeService.isUsingAlternateRoute
                            ? [
                              Colors.grey,
                              Colors.grey.shade600,
                              Colors.grey.shade800,
                            ]
                            : [
                              Colors.blue,
                              Colors.blue.shade700,
                              Colors.blue.shade900,
                            ],
                  ),
                // Alternate route polyline from 10°59'21.4"N 75°59'37.2"E - updates in realtime
                if (_routeService.isUsingAlternateRoute)
                  Polyline(
                    points: _routeService.getAlternateRouteCoordinates(),
                    color:
                        _activeCongestionAlert?.level == CongestionLevel.high
                            ? Colors.orange
                            : Colors.green,
                    strokeWidth:
                        _activeCongestionAlert?.level == CongestionLevel.high
                            ? 5.0
                            : 4.0,
                    gradientColors:
                        _activeCongestionAlert?.level == CongestionLevel.high
                            ? [
                              Colors.orange,
                              Colors.orange.shade700,
                              Colors.deepOrange,
                            ]
                            : [
                              Colors.green,
                              Colors.green.shade700,
                              Colors.green.shade900,
                            ],
                    isDotted:
                        _activeCongestionAlert?.level != CongestionLevel.high,
                  ),
              ],
            ),

            // Marker layers
            MarkerLayer(
              markers: [
                // Rerouting notification banner (when active)
                if (_isShowingAlternateRoute)
                  Marker(
                    width: 250,
                    height: 70, // Increased height to fix overflow
                    point: LatLng(
                      kottakkalNE.latitude - 0.005,
                      kottakkalCenter.longitude,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical:
                            6, // Reduced vertical padding to accommodate content
                      ),
                      decoration: BoxDecoration(
                        color:
                            _activeCongestionAlert?.level ==
                                    CongestionLevel.high
                                ? Colors.deepOrange.withOpacity(0.9)
                                : Colors.green.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _activeCongestionAlert?.level ==
                                    CongestionLevel.high
                                ? "Heavy Traffic Rerouting"
                                : "Active Rerouting",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(
                            height: 1,
                          ), // Reduced spacing between texts
                          Text(
                            _activeCongestionAlert?.level ==
                                    CongestionLevel.high
                                ? "Emergency alternate route active"
                                : "Avoiding moderate congestion on main route",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // User location marker
                if (_userLocation != null)
                  Marker(
                    point: _userLocation!,
                    child: _buildUserLocationMarker(),
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                  ),

                // Destination marker
                if (_destinationLocation != null)
                  Marker(
                    point: _destinationLocation!,
                    width: 30,
                    height: 30,
                    alignment: Alignment.bottomCenter,
                    rotate: false, // Prevent marker from rotating with map
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 30,
                    ),
                  ),

                // Congestion camera marker
                Marker(
                  point: CongestionDetectionService.cameraLocation,
                  width: 60,
                  height: 80,
                  alignment: Alignment.center,
                  rotate: false,
                  child:
                      _activeCongestionAlert != null &&
                              (_activeCongestionAlert!.level ==
                                      CongestionLevel.medium ||
                                  _activeCongestionAlert!.level ==
                                      CongestionLevel.high)
                          ? CongestionMarker(
                            alert: _activeCongestionAlert!,
                            onTap:
                                () => _showCongestionDetails(
                                  _activeCongestionAlert!,
                                ),
                          )
                          : Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.7),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                ),
              ],
            ),
          ],
        ),

        // Search bar positioned slightly lower on the screen
        Builder(
          builder: (context) {
            // Position it a bit lower from the top (8% of screen height)
            return Positioned(
              top: MediaQuery.of(context).size.height * 0.08,
              left: 16,
              right: 16,
              child: LocationSearchBar(
                onLocationSelected: _onLocationSelected,
                onRouteFound: _onRouteFound,
                currentLocation: _userLocation,
              ),
            );
          },
        ),

        // Add a location button at the bottom right, aligned with the navbar
        Builder(
          builder: (context) {
            final responsive = context.responsive;
            return Positioned(
              bottom: responsive.navbarBottomPadding, // Same as navbar
              right: 16,
              child: Container(
                width:
                    responsive.navbarMenuButtonSize, // Match menu button size
                height: responsive.navbarMenuButtonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2CD91E), // AppColors.primary
                      Color(0xFF199F11), // AppColors.onTap
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2CD91E).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _centerOnUserLocation,
                    customBorder: const CircleBorder(),
                    child: Icon(
                      Icons.my_location,
                      size: responsive.navbarIconSize, // Match navbar icon size
                      color: Colors.black87, // AppColors.textSecondary
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Add test button to force alternate route display
        Builder(
          builder: (context) {
            final responsive = context.responsive;
            return Positioned(
              bottom:
                  responsive.navbarBottomPadding +
                  70, // Fixed position to avoid overflow
              right: 16,
              child: Container(
                width: responsive.navbarMenuButtonSize,
                height: responsive.navbarMenuButtonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _routeService.forceAlternateRoute();
                      setState(() {
                        _isShowingAlternateRoute = true;
                      });

                      // Show confirmation
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Alternate route forced to display'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    customBorder: const CircleBorder(),
                    child: Icon(
                      Icons.alt_route,
                      size: responsive.navbarIconSize,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Add emergency button
        Builder(
          builder: (context) {
            final responsive = context.responsive;
            return Positioned(
              bottom: responsive.navbarBottomPadding,
              left:
                  16, // Position to the left side of the screen, aligned with navbar
              child: Container(
                width: responsive.navbarMenuButtonSize,
                height: responsive.navbarMenuButtonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.red.shade500, Colors.red.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _showEmergencyConfirmationDialog(context);
                    },
                    customBorder: const CircleBorder(),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: responsive.navbarIconSize,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
