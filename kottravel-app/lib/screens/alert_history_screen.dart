import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';

class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({super.key});

  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();
}

class _AlertHistoryScreenState extends State<AlertHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  // Data variables
  List<Map<String, dynamic>> allTrafficHistory = [];
  List<Map<String, dynamic>> displayedHistory = [];
  bool isLoading = true;
  String? errorMessage;

  // Filtering variables
  String _searchQuery = '';
  String _selectedSeverity = 'All';
  String _sortBy = 'timestamp';
  bool _isAscending = false; // Default to newest first

  // Pagination variables
  int _itemsPerPage = 20;
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  // Date range filter
  DateTime? _startDate;
  DateTime? _endDate;

  // Dummy data for traffic history
  List<Map<String, dynamic>> _dummyTrafficData = [];

  @override
  void initState() {
    super.initState();
    _loadTrafficHistoryData();

    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Scroll listener for infinite scrolling
  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreData();
    }
  }

  // Generate dummy traffic data
  List<Map<String, dynamic>> _generateDummyTrafficData() {
    // Different congestion levels and statuses
    final List<Map<String, dynamic>> congestionTypes = [
      {'level': 0, 'status': 'Clear', 'vehicle_count_roi': 0},
      {'level': 1, 'status': 'Light Traffic', 'vehicle_count_roi': 2},
      {'level': 2, 'status': 'Moderate Traffic', 'vehicle_count_roi': 5},
      {'level': 3, 'status': 'Heavy Traffic', 'vehicle_count_roi': 8},
      {'level': 3, 'status': 'Emergency', 'vehicle_count_roi': 10},
    ];

    // Different locations for variety
    final List<String> locations = [
      'Malappuram Road',
      'Edappal Junction',
      'Kottakkal Bypass',
      'Hospital Road',
      'Market Centre',
      'Bus Stand',
    ];

    List<Map<String, dynamic>> dummyData = [];

    // Generate 15 dummy records with different timestamps
    for (int i = 0; i < 15; i++) {
      final randomCongestion = congestionTypes[i % congestionTypes.length];
      final randomLocation = locations[i % locations.length];

      // Create timestamp with decreasing time (newest first)
      final timestamp = DateTime.now().subtract(Duration(hours: i * 2));

      dummyData.add({
        'id': 'dummy_$i',
        'timestamp': timestamp.toIso8601String(),
        'location_id': randomLocation,
        'congestion': {
          'level': randomCongestion['level'],
          'status': randomCongestion['status'],
          'vehicle_count_roi': randomCongestion['vehicle_count_roi'],
        },
        'metadata': {
          'camera': 'CAM-${100 + i}',
          'detection_time_ms': 245 + (i * 10),
          'region': 'Kottakkal',
          'accuracy': '${90 - (i % 8)}%',
        },
      });
    }

    return dummyData;
  }

  // Initial data loading
  Future<void> _loadTrafficHistoryData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Generate dummy data instead of fetching from Firebase
      // This simulates a successful data fetch
      List<Map<String, dynamic>> dummyData = _generateDummyTrafficData();

      // Add a small delay to simulate network request
      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        allTrafficHistory = dummyData;
        displayedHistory = dummyData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading data: ${e.toString()}';
      });
    }
  }

  // Apply all filters and sorting
  void _applyFiltersAndPagination() {
    // Implementation as needed
  }

  // Load more data for infinite scrolling
  Future<void> _loadMoreData() async {
    // Implementation as needed
  }

  // Helper function to get congestion text from level
  String _getCongestionText(int level) {
    switch (level) {
      case 0:
        return 'Clear';
      case 1:
        return 'Light';
      case 2:
        return 'Moderate';
      case 3:
        return 'Heavy';
      default:
        return 'Unknown';
    }
  }

  // Helper function to format timestamp
  String _formatTimestamp(String timestamp) {
    try {
      final DateTime date = DateTime.parse(timestamp);
      return DateFormat('h:mm a').format(date);
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Header with back button, title and refresh button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  // Title
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Traffic History',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.06,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Manrope',
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  // Refresh button
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    onPressed: _loadTrafficHistoryData,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Main content
              if (isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (errorMessage != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadTrafficHistoryData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text(
                            'Try Again',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    children: [
                      // Recent Records Section
                      if (displayedHistory.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.history_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No traffic history data found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Recent Monitoring Section (First 5 records)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Recent Monitoring',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Last 5 Records',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textHint,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Display the first 5 traffic history cards
                                  ...displayedHistory.take(5).map((entry) {
                                    final congestionLevel =
                                        entry['congestion']?['level'] ?? 0;
                                    final congestionStatus =
                                        entry['congestion']?['status'] ??
                                        _getCongestionText(congestionLevel);

                                    // Get color based on congestion level
                                    final Color statusColor =
                                        congestionLevel >= 3
                                            ? Colors.red
                                            : congestionLevel == 2
                                            ? Colors.orange
                                            : AppColors.primary;

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Card(
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          side: BorderSide(
                                            color: statusColor.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  // Status with badge
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: statusColor
                                                          .withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width: 10,
                                                          height: 10,
                                                          decoration:
                                                              BoxDecoration(
                                                                color:
                                                                    statusColor,
                                                                shape:
                                                                    BoxShape
                                                                        .circle,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Text(
                                                          congestionStatus,
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: statusColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Timestamp
                                                  Text(
                                                    _formatTimestamp(
                                                      entry['timestamp'] ?? '',
                                                    ),
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              // Location
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.location_on_outlined,
                                                    size: 16,
                                                    color: Colors.grey[700],
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '${entry['location_id'] ?? 'Unknown'}',
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              // Vehicle count
                                              if (entry['congestion']?['vehicle_count_roi'] !=
                                                  null)
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.directions_car,
                                                      size: 16,
                                                      color: Colors.grey[700],
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      '${entry['congestion']['vehicle_count_roi']} vehicles detected',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                              // Add metadata preview
                                              if (entry['metadata'] != null)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 8,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.info_outline,
                                                        size: 16,
                                                        color: Colors.grey[600],
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'Camera: ${entry['metadata']['camera'] ?? 'Unknown'} | ' +
                                                            'Accuracy: ${entry['metadata']['accuracy'] ?? 'N/A'}',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // All History Section (Remaining records)
                            if (displayedHistory.length > 5)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 5,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Full History',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '${displayedHistory.length - 5} More Records',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textHint,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Display the remaining traffic history cards
                                    ...displayedHistory.skip(5).map((entry) {
                                      final congestionLevel =
                                          entry['congestion']?['level'] ?? 0;
                                      final congestionStatus =
                                          entry['congestion']?['status'] ??
                                          _getCongestionText(congestionLevel);

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Card(
                                          elevation:
                                              1, // Slightly lower elevation to differentiate
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      congestionStatus,
                                                      style: TextStyle(
                                                        fontSize:
                                                            14, // Slightly smaller
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            congestionLevel >= 3
                                                                ? Colors.red
                                                                : congestionLevel ==
                                                                    2
                                                                ? Colors.orange
                                                                : AppColors
                                                                    .primary,
                                                      ),
                                                    ),
                                                    Text(
                                                      _formatTimestamp(
                                                        entry['timestamp'] ??
                                                            '',
                                                      ),
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: 4,
                                                ), // Slightly smaller spacing
                                                Text(
                                                  'Location: ${entry['location_id'] ?? 'Unknown'}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                if (entry['congestion']?['vehicle_count_roi'] !=
                                                    null)
                                                  Text(
                                                    'Vehicles: ${entry['congestion']['vehicle_count_roi']}',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                          ],
                        ),

                      // Bottom padding for better scrolling experience
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
