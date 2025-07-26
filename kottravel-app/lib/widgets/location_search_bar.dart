import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/open_route_service.dart';
import '../utils/app_theme.dart';

class LocationSearchBar extends StatefulWidget {
  final Function(LatLng) onLocationSelected;
  final Function(List<LatLng>) onRouteFound;
  final LatLng? currentLocation;

  const LocationSearchBar({
    super.key,
    required this.onLocationSelected,
    required this.onRouteFound,
    this.currentLocation,
  });

  @override
  State<LocationSearchBar> createState() => _LocationSearchBarState();
}

class _LocationSearchBarState extends State<LocationSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  List<GeocodingResult> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  LatLng? _selectedLocation;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showResults = true;
    });

    try {
      final results = await OpenRouteService.searchLocation(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
      }
    }
  }

  Future<void> _getRoute() async {
    if (_selectedLocation != null && widget.currentLocation != null) {
      try {
        final routeResult = await OpenRouteService.getRoute(
          start: widget.currentLocation!,
          end: _selectedLocation!,
        );

        if (routeResult != null && mounted) {
          widget.onRouteFound(routeResult.points);

          // Show route summary
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Distance: ${routeResult.formattedDistance}, Duration: ${routeResult.formattedDuration}',
              ),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(label: 'DISMISS', onPressed: () {}),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to calculate route')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select a destination and ensure your current location is available',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Change container background when a location is selected
    final containerColor =
        _selectedLocation != null
            ? AppColors.secondary.withOpacity(
              0.9,
            ) // Light green background when selected
            : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.9, // 90% of screen width
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          decoration: BoxDecoration(
            color: containerColor, // Conditionally set background color
            borderRadius: BorderRadius.circular(25), // Consistent border radius
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 4),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search location',
                        prefixIcon: Icon(
                          Icons.search,
                          color:
                              _selectedLocation != null
                                  ? AppColors.primary
                                  : Colors.grey,
                        ),
                        suffixIcon:
                            _searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _selectedLocation = null;
                                      _showResults = false;
                                      _searchResults = [];
                                    });
                                  },
                                )
                                : null,
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 5,
                        ),
                        fillColor: Colors.transparent,
                        filled: true,
                      ),
                      onChanged: (value) {
                        if (value.length > 2) {
                          _searchLocation(value);
                        } else if (value.isEmpty) {
                          setState(() {
                            _showResults = false;
                            _searchResults = [];
                          });
                        }
                      },
                    ),
                  ),
                  if (_selectedLocation != null)
                    IconButton(
                      icon: const Icon(Icons.directions),
                      onPressed: _getRoute,
                      color: AppColors.primary,
                    ),
                ],
              ),
              if (_showResults) ...[
                const Divider(height: 1, thickness: 1),
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_searchResults.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No results found'),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        25,
                      ), // Match parent border radius
                      color: Colors.white,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        25,
                      ), // Match parent border radius
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return ListTile(
                            leading: Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              result.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(result.label),
                            onTap: () {
                              setState(() {
                                _selectedLocation = result.location;
                                _searchController.text = result.label;
                                _showResults = false;
                              });
                              widget.onLocationSelected(result.location);
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
