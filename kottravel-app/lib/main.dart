import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/landing_screen.dart';
import 'utils/app_theme.dart';
import 'firebase_options.dart';

// Map preloading globals
final mapPreloader = MapPreloader();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling for duplicate initialization
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // If Firebase is already initialized, catch the error and proceed
    if (e.toString().contains(
      'A Firebase App named "[DEFAULT]" already exists',
    )) {
      debugPrint('Firebase already initialized, continuing...');
    } else {
      // Re-throw if it's a different error
      rethrow;
    }
  }

  // Lock orientation to portrait mode only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Make status bar transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize location services
  await _initializeLocationServices();

  // Start preloading map tiles in background
  mapPreloader.startPreloading();

  runApp(const KottravelApp());
}

/// Initialize location services and request permissions early
Future<void> _initializeLocationServices() async {
  try {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled');
      return;
    }

    // Check initial permission status
    LocationPermission permission = await Geolocator.checkPermission();

    // Request permission if not granted yet
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied');
      return;
    }

    // If we reach here, permissions are granted
    debugPrint('Location permissions granted');
  } catch (e) {
    debugPrint('Error initializing location services: $e');
  }
}

/// A class to preload map tiles for faster initial loading
class MapPreloader {
  // Key map tiles for Kottakkal region (preloaded for faster startup)
  // Focusing only on the most essential tiles for the initial view
  final List<String> _essentialTiles = [
    // Zoom level 14 - main focus level for Kottakkal
    'https://tile.openstreetmap.org/14/6627/4822.png', // Center of Kottakkal
    'https://tile.openstreetmap.org/14/6626/4822.png', // West
    'https://tile.openstreetmap.org/14/6628/4822.png', // East
    'https://tile.openstreetmap.org/14/6627/4821.png', // North
    'https://tile.openstreetmap.org/14/6627/4823.png', // South
    // Zoom level 15 (higher detail for center only)
    'https://tile.openstreetmap.org/15/13254/9644.png', // Center of Kottakkal
    'https://tile.openstreetmap.org/15/13255/9644.png', // East center
    'https://tile.openstreetmap.org/15/13254/9645.png', // South center
    'https://tile.openstreetmap.org/15/13253/9644.png', // West center
    // Zoom level 13 (for context when zooming out)
    'https://tile.openstreetmap.org/13/3313/2411.png', // Center of Kottakkal
  ];

  /// Start preloading map tiles in the background with improved error handling
  void startPreloading() {
    // Run in a microtask to avoid blocking app startup
    scheduleMicrotask(() async {
      int loadedCount = 0;

      for (final tileUrl in _essentialTiles) {
        try {
          // Fetch and cache tile with timeout
          final response = await http
              .get(Uri.parse(tileUrl))
              .timeout(const Duration(seconds: 3));

          if (response.statusCode == 200) {
            loadedCount++;
          }
        } catch (e) {
          // Just ignore errors in preloading, no need to log each one
        }
      }

      debugPrint('Map tiles preloaded: $loadedCount/${_essentialTiles.length}');
    });
  }
}

class KottravelApp extends StatelessWidget {
  const KottravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kottravel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LandingScreen(),
    );
  }
}
