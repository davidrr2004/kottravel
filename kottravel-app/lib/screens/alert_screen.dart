import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import '../utils/app_theme.dart';
import 'alert_history_screen.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  List<Map<String, dynamic>> trafficHistory = [];
  List<Map<String, dynamic>> alerts = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadTrafficData();
  }

  Future<void> loadTrafficData() async {
    try {
      // Get a reference to the Firebase Realtime Database
      final databaseReference = FirebaseDatabase.instance.ref();

      // Get the traffic_history/camera_001 data
      final trafficSnapshot =
          await databaseReference
              .child('traffic_history')
              .child('camera_001')
              .get();

      if (!trafficSnapshot.exists) {
        print('No traffic history data available');
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Convert snapshot to a map
      final Map<String, dynamic> trafficHistoryData = Map<String, dynamic>.from(
        trafficSnapshot.value as Map,
      );

      List<Map<String, dynamic>> historyList = [];

      trafficHistoryData.forEach((key, value) {
        if (value is Map<String, dynamic> && value['congestion'] != null) {
          historyList.add({
            'timestamp': value['timestamp'] ?? '',
            'vehicle_count': value['congestion']['vehicle_count_roi'] ?? 0,
            'location_id': value['location_id'] ?? 'camera_001',
            'last_detection': value['metadata']?['last_detection'] ?? '',
            'congestion_level': value['congestion']['level'] ?? 0,
            'congestion_status': value['congestion']['status'] ?? 'Unknown',
            'total_detections': value['congestion']['total_detections'] ?? 0,
            'vehicle_types': value['vehicles']?['types'] ?? {},
          });
        }
      });

      // Sort by timestamp (most recent first)
      historyList.sort(
        (a, b) =>
            b['timestamp'].toString().compareTo(a['timestamp'].toString()),
      );

      // Fetch alerts data
      List<Map<String, dynamic>> alertsList = [];
      final alertsSnapshot =
          await databaseReference.child('alerts').child('camera_001').get();

      if (alertsSnapshot.exists) {
        final Map<String, dynamic> alertsData = Map<String, dynamic>.from(
          alertsSnapshot.value as Map,
        );

        alertsData.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            alertsList.add({
              'alert_type': value['alert_type'] ?? '',
              'message': value['message'] ?? '',
              'severity': value['severity'] ?? '',
              'timestamp': value['timestamp'] ?? '',
              'location_id': value['location_id'] ?? '',
            });
          }
        });

        // Sort alerts by timestamp (most recent first)
        alertsList.sort(
          (a, b) =>
              b['timestamp'].toString().compareTo(a['timestamp'].toString()),
        );
      }

      setState(() {
        trafficHistory =
            historyList.take(5).toList(); // Show the 5 most recent entries
        alerts = alertsList.take(5).toList(); // Show the 5 most recent alerts
        isLoading = false;
      });
    } catch (e) {
      print('Error loading traffic data: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load traffic data. Please try again later.';
      });
    }
  }

  Color getTrafficColor(int vehicleCount, String? severity) {
    if (severity != null) {
      switch (severity.toLowerCase()) {
        case 'high':
          return AppColors.extraDeepGreen;
        case 'medium':
          return AppColors.primaryDark;
        case 'low':
          return AppColors.primary;
        default:
          return AppColors.accentGreen;
      }
    }

    // Based on vehicle count
    if (vehicleCount >= 6) {
      return AppColors.extraDeepGreen; // Heavy traffic
    } else if (vehicleCount >= 3) {
      return AppColors.primaryDark; // Moderate traffic
    } else if (vehicleCount >= 1) {
      return AppColors.primary; // Light traffic
    } else {
      return AppColors.accentGreen; // Clear roads
    }
  }

  String getTrafficStatus(int vehicleCount) {
    if (vehicleCount >= 6) {
      return 'Heavy Traffic';
    } else if (vehicleCount >= 3) {
      return 'Moderate Traffic';
    } else if (vehicleCount >= 1) {
      return 'Light Traffic';
    } else {
      return 'Clear Roads';
    }
  }

  IconData getTrafficIcon(int vehicleCount, String? alertType) {
    if (alertType == 'high_congestion') {
      return Icons.traffic;
    }

    if (vehicleCount >= 6) {
      return Icons.traffic;
    } else if (vehicleCount >= 3) {
      return Icons.directions_car;
    } else if (vehicleCount >= 1) {
      return Icons.local_shipping;
    } else {
      return Icons.check_circle;
    }
  }

  String formatTimestamp(String timestamp) {
    try {
      DateTime dt = DateTime.parse(timestamp);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return timestamp.substring(
        timestamp.length > 8 ? timestamp.length - 8 : 0,
      );
    }
  }

  String getEstimatedDelay(int vehicleCount) {
    if (vehicleCount >= 6) {
      return '15-25 mins';
    } else if (vehicleCount >= 3) {
      return '5-10 mins';
    } else if (vehicleCount >= 1) {
      return '2-5 mins';
    } else {
      return '0 mins';
    }
  }

  String _getCongestionText(int level) {
    switch (level) {
      case 3:
        return 'High Congestion';
      case 2:
        return 'Moderate Congestion';
      case 1:
        return 'Light Congestion';
      case 0:
      default:
        return 'Normal Traffic';
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      DateTime dt = DateTime.parse(timestamp);
      return "${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return timestamp;
    }
  }

  Widget _buildMonitoringCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 22),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout
    final size = MediaQuery.of(context).size;

    // Simple responsive values
    final double titleSize = size.width * 0.06;
    final double subtitleSize = size.width * 0.045;
    final double bodySize = size.width * 0.04;
    final double spacing = size.height * 0.02;

    return Scaffold(
      backgroundColor: AppColors.background,
      // AppBar removed for a cleaner look, similar to AccountScreen
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child:
              isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                  : RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        isLoading = true;
                        errorMessage = '';
                      });
                      await loadTrafficData();
                    },
                    color: AppColors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: spacing * 0.2),
                          // Title with consistent styling
                          Text(
                            'Traffic Monitoring',
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Manrope',
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: spacing),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'System Monitoring',
                                style: TextStyle(
                                  fontSize: subtitleSize,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const AlertHistoryScreen(),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.history,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                label: Text(
                                  'View History',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.primary),
                                  backgroundColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Monitoring Cards in a horizontal scrollable row
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                // Camera Status Card
                                _buildMonitoringCard(
                                  title: 'Camera Status',
                                  value: 'Online',
                                  icon: Icons.videocam,
                                  color: AppColors.accentGreen,
                                  subtitle: 'Last checked: 2 mins ago',
                                ),

                                // Server Status Card
                                _buildMonitoringCard(
                                  title: 'Server Status',
                                  value: 'Operational',
                                  icon: Icons.dns,
                                  color: AppColors.accentGreen,
                                  subtitle: 'Response time: 120ms',
                                ),

                                // Processing Load Card
                                _buildMonitoringCard(
                                  title: 'Processing',
                                  value: '65%',
                                  icon: Icons.memory,
                                  color: AppColors.primaryDark,
                                  subtitle: 'CPU utilization',
                                ),

                                // Data Quality Card
                                _buildMonitoringCard(
                                  title: 'Data Quality',
                                  value: '98%',
                                  icon: Icons.data_usage,
                                  color: AppColors.accentGreen,
                                  subtitle: 'Detection confidence',
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: spacing),
                        ],
                      ),
                    ),
                  ),
        ),
      ),
    );
  }
}
