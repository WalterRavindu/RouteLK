import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/bus_data.dart';
import '../services/location_service.dart';
import '../services/firebase_bus_service.dart';
import '../widgets/bus_marker.dart';
<<<<<<< Updated upstream
import '../widgets/route_selector.dart';
import '../widgets/bus_info_card.dart';
=======
>>>>>>> Stashed changes
import '../utils/map_utils.dart';

/// Main page displaying the bus tracking map
class BusMapPage extends StatefulWidget {
  const BusMapPage({super.key});

  @override
  State<BusMapPage> createState() => _BusMapPageState();
}

class _BusMapPageState extends State<BusMapPage> {
  LatLng? myCurrentLocation;
  Map<String, BusData> busData = {};
  final MapController mapController = MapController();
  final FirebaseBusService _busService = FirebaseBusService();

  // Route filtering
  String? selectedRoute;
  List<String> availableRoutes = [];

  // Picked bus message state
  bool _showPickedBusMessage = false;
  String? _pickedBusId;
  Timer? _pickedBusMessageTimer;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _listenToBusLocations();
  }

<<<<<<< Updated upstream
=======
  @override
  void dispose() {
    _busSubscription?.cancel();
    _userLocationSubscription?.cancel();
    _etaDebounceTimer?.cancel();
    _pickedBusMessageTimer?.cancel();
    super.dispose();
  }

>>>>>>> Stashed changes
  /// Initialize user's current location
  Future<void> _initializeLocation() async {
    final location = await LocationService.determinePosition();
    setState(() {
      myCurrentLocation = location;
    });
  }

  /// Listen to Firebase for bus location updates
  void _listenToBusLocations() {
    _busService.listenToBusLocations().listen(
      (updatedBusData) {
        setState(() {
          busData = updatedBusData;
          availableRoutes = _busService.getAvailableRoutes(busData);
<<<<<<< Updated upstream
=======

          // If the preselected route is no longer available, fall back to all routes.
          if (selectedRoute != null &&
              !availableRoutes.contains(selectedRoute)) {
            selectedRoute = null;
          }

          if (hasSelectedBus && !selectedStillExists) {
            _selectedBusId = null;
            _selectedBusEstimate = null;
            _estimateMessage = null;
            _isApproximateEstimate = false;
            _isFetchingEstimate = false;
          }
>>>>>>> Stashed changes
        });
      },
      onError: (error) {
        debugPrint('Error listening to bus locations: $error');
      },
    );
  }

<<<<<<< Updated upstream
=======
  void _maybeAutoFitToBuses() {
    if (!_isMapReady || _hasAdjustedInitialMapView) {
      return;
    }

    final displayBuses = filteredBusData;
    if (displayBuses.isEmpty) {
      return;
    }

    _hasAdjustedInitialMapView = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      MapUtils.fitToBuses(mapController, displayBuses);
    });
  }

  void _listenToUserLocation() {
    _userLocationSubscription = LocationService.positionStream().listen(
      (location) {
        if (!mounted) {
          return;
        }

        setState(() {
          myCurrentLocation = location;
        });

        if (_selectedBusId != null) {
          _scheduleEstimateRefresh();
        }
      },
      onError: (error) {
        debugPrint('Error listening to user location: $error');
      },
    );
  }

  void _onBusTapped(String busId) {
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedBusId = busId;
      _selectedBusEstimate = null;
      _estimateMessage = null;
      _isApproximateEstimate = false;
      _isFetchingEstimate = true;
    });

    _scheduleEstimateRefresh(immediate: true);
  }

  void _scheduleEstimateRefresh({bool immediate = false}) {
    _etaDebounceTimer?.cancel();

    final delay = immediate
        ? Duration.zero
        : const Duration(milliseconds: 1500);
    _etaDebounceTimer = Timer(delay, _refreshSelectedBusEstimate);
  }

  Future<void> _refreshSelectedBusEstimate() async {
    final selectedBusId = _selectedBusId;
    if (selectedBusId == null) {
      return;
    }

    final selectedBus = busData[selectedBusId];
    if (selectedBus == null) {
      return;
    }

    final requestVersion = ++_etaRequestVersion;
    if (mounted) {
      setState(() {
        _isFetchingEstimate = true;
        _estimateMessage = null;
        _isApproximateEstimate = false;
      });
    }

    try {
      final estimate = await _openRouteService.fetchEtaAndDistance(
        from: _startLocation,
        to: selectedBus.location,
      );

      if (!mounted || requestVersion != _etaRequestVersion) {
        return;
      }

      setState(() {
        _selectedBusEstimate = estimate;
        _estimateMessage = null;
        _isApproximateEstimate = false;
        _isFetchingEstimate = false;
      });
    } catch (e) {
      if (!mounted || requestVersion != _etaRequestVersion) {
        return;
      }

      final fallbackEstimate = _buildFallbackEstimate(
        from: _startLocation,
        to: selectedBus.location,
      );

      setState(() {
        _selectedBusEstimate = fallbackEstimate;
        _estimateMessage =
            'Live traffic ETA is temporarily unavailable. Showing an approximate estimate.';
        _isApproximateEstimate = true;
        _isFetchingEstimate = false;
      });

      debugPrint('Error fetching selected bus ETA: $e');
    }
  }

  RouteEstimate _buildFallbackEstimate({
    required LatLng from,
    required LatLng to,
  }) {
    const averageCitySpeedKmPerHour = 28.0;
    final straightLineKm = const Distance().as(LengthUnit.Kilometer, from, to);
    final roadAdjustedDistanceKm = straightLineKm * 1.3;
    final minutes = (roadAdjustedDistanceKm / averageCitySpeedKmPerHour) * 60;

    return RouteEstimate(
      distanceKm: roadAdjustedDistanceKm,
      durationMinutes: minutes.clamp(1, 240).toDouble(),
    );
  }

>>>>>>> Stashed changes
  /// Get filtered buses based on selected route
  Map<String, BusData> get filteredBusData {
    return _busService.filterBusesByRoute(busData, selectedRoute);
  }

  /// Handle viewing all buses on the map
  void _viewAllBuses() {
    final displayBuses = filteredBusData;
    if (displayBuses.isNotEmpty) {
      MapUtils.fitToBuses(mapController, displayBuses);
    }
  }

  /// Handle centering on user's location
  void _centerOnMyLocation() {
    if (myCurrentLocation != null) {
      mapController.move(myCurrentLocation!, 15);
    }
  }

  void _updateMapCenterLocation(MapPosition position) {
    if (position.center == null) {
      return;
    }

    setState(() {
      _startLocation = position.center!;
    });

    if (_selectedBusId != null) {
      _scheduleEstimateRefresh(immediate: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayBusData = filteredBusData;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bus Tracker - Real-time"),
        backgroundColor: const Color(0xFFfec205),
      ),
<<<<<<< Updated upstream
      body: myCurrentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                _buildMap(displayBusData),
                _buildRouteSelector(),
                _buildInfoCards(displayBusData),
              ],
            ),
=======
      body: Stack(
        children: [
          _buildMap(displayBusData),
          _buildCenterBalloonMarker(),
          _buildRouteMenuButton(),
          _buildRouteSelectorPanel(),
          _buildSelectedBusEtaCard(),
          _buildPickedBusMessage(),
        ],
      ),
>>>>>>> Stashed changes
      floatingActionButton: _buildFloatingButtons(displayBusData),
    );
  }

  /// Build the map widget
  Widget _buildCenterBalloonMarker() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            color: Colors.blue,
            size: 40,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the map widget
  Widget _buildMap(Map<String, BusData> displayBusData) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
<<<<<<< Updated upstream
        initialCenter: LatLng(7.2906, 80.6337), // Kandy center
        initialZoom: 12,
=======
        initialCenter: _startLocation,
        initialZoom: 17,
        onPositionChanged: (MapPosition position, bool hasGesture) {
          if (hasGesture) {
            _updateMapCenterLocation(position);
          }
        },
        onMapReady: () {
          _isMapReady = true;
          _focusUserOnLoad();
          _maybeAutoFitToBuses();
        },
>>>>>>> Stashed changes
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        MarkerLayer(
          markers: [
<<<<<<< Updated upstream
            // User's current location marker
            Marker(
              point: myCurrentLocation!,
              width: 50,
              height: 50,
              child: const Icon(
                Icons.my_location,
                color: Colors.blue,
                size: 40,
              ),
            ),
            // Bus markers
            ...displayBusData.entries
                .map((entry) => BusMarker.create(entry.key, entry.value))
                .toList(),
=======
            if (!_showRouteSelector && myCurrentLocation != null)
              Marker(
                point: myCurrentLocation!,
                width: 28,
                height: 28,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withValues(alpha: 0.25),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
            // Bus markers
            if (!_showRouteSelector)
              ...displayBusData.entries.map(
                (entry) => BusMarker.create(
                  entry.key,
                  entry.value,
                  onTap: () => _onBusTapped(entry.key),
                ),
              ),
>>>>>>> Stashed changes
          ],
        ),
      ],
    );
  }

<<<<<<< Updated upstream
  /// Build route selector widget
  Widget _buildRouteSelector() {
=======
  Widget _buildSelectedBusEtaCard() {
    if (_showRouteSelector) {
      return const SizedBox.shrink();
    }

    final selectedBusId = _selectedBusId;
    if (selectedBusId == null) {
      return const SizedBox.shrink();
    }

    final selectedBus = busData[selectedBusId];
    if (selectedBus == null) {
      return const SizedBox.shrink();
    }

    final crowdColor = selectedBus.occupancyColor;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final arrivalLabel = _selectedBusEstimate != null
        ? 'Bus arriving in ${_selectedBusEstimate!.durationMinutes.toStringAsFixed(0)} mins'
        : (_isFetchingEstimate
              ? 'Bus arriving in ...'
              : 'Bus arrival time is being prepared');

    return Positioned(
      left: 12,
      right: 12,
      bottom: 10 + bottomInset,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_bus, color: crowdColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bus $selectedBusId - ${selectedBus.route}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedBusId = null;
                        _selectedBusEstimate = null;
                        _estimateMessage = null;
                        _isApproximateEstimate = false;
                        _isFetchingEstimate = false;
                      });
                    },
                    child: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_filled,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        arrivalLabel,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (_isFetchingEstimate)
                const Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Refreshing distance and ETA...'),
                  ],
                )
              else if (_selectedBusEstimate != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_estimateMessage != null)
                      Text(
                        _estimateMessage!,
                        style: TextStyle(
                          color: _isApproximateEstimate
                              ? Colors.orange.shade900
                              : Colors.black87,
                          fontSize: 12,
                          fontWeight: _isApproximateEstimate
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    if (_estimateMessage != null) const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetric(
                            icon: Icons.route,
                            label: _isApproximateEstimate
                                ? 'Approx Distance'
                                : 'Distance',
                            value:
                                '${_selectedBusEstimate!.distanceKm.toStringAsFixed(2)} km',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetric(
                            icon: Icons.people_alt,
                            label: 'Crowd Level',
                            value: selectedBus.occupancyLevel,
                            valueColor: selectedBus.occupancyColor,
                            iconColor: selectedBus.occupancyColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: _buildPickBusTile(selectedBusId)),
                      ],
                    ),
                  ],
                )
              else
                const Text('Preparing route details...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickedBusMessage() {
    if (!_showPickedBusMessage || _pickedBusId == null) {
      return const SizedBox.shrink();
    }

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Positioned(
      left: 12,
      right: 12,
      bottom: 320 + bottomInset,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bus $_pickedBusId picked successfully',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickBusTile(String busId) {
    return Material(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          _pickedBusMessageTimer?.cancel();
          setState(() {
            _pickedBusId = busId;
            _showPickedBusMessage = true;
          });
          _pickedBusMessageTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _showPickedBusMessage = false;
              });
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pick Bus',
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      busId,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor ?? Colors.deepOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteMenuButton() {
>>>>>>> Stashed changes
    return Positioned(
      top: 10,
      left: 10,
      child: RouteSelector(
        selectedRoute: selectedRoute,
        availableRoutes: availableRoutes,
        onRouteChanged: (newRoute) {
          setState(() {
            selectedRoute = newRoute;
          });
        },
      ),
    );
  }

<<<<<<< Updated upstream
  /// Build info cards (bus info, no buses, or waiting)
  Widget _buildInfoCards(Map<String, BusData> displayBusData) {
    Widget infoCard;

    if (displayBusData.isNotEmpty) {
      infoCard = BusInfoCard(
        busData: displayBusData,
        selectedRoute: selectedRoute,
      );
    } else if (busData.isNotEmpty) {
      infoCard = NoBusesMessage(selectedRoute: selectedRoute);
    } else {
      infoCard = const WaitingForDataMessage();
    }

    return Positioned(top: 10, right: 10, child: infoCard);
=======
  Widget _buildRouteSelectorPanel() {
    final routeItems = <String?>[null, ...availableRoutes];

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_showRouteSelector,
        child: AnimatedOpacity(
          opacity: _showRouteSelector ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: Container(
            color: Colors.black38,
            child: SafeArea(
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedSlide(
                  offset: _showRouteSelector
                      ? Offset.zero
                      : const Offset(-1, 0),
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: Material(
                    color: Colors.white,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.route,
                                  color: Colors.deepOrange,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Select Route',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Close routes',
                                  onPressed: () {
                                    setState(() {
                                      _showRouteSelector = false;
                                    });
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView.builder(
                              itemCount: routeItems.length,
                              itemBuilder: (context, index) {
                                final route = routeItems[index];
                                final isSelected = selectedRoute == route;

                                return ListTile(
                                  leading: Icon(
                                    route == null
                                        ? Icons.public
                                        : Icons.alt_route,
                                    color: isSelected
                                        ? Colors.deepOrange
                                        : Colors.black54,
                                  ),
                                  title: Text(route ?? 'All Routes'),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.deepOrange,
                                        )
                                      : null,
                                  selected: isSelected,
                                  selectedTileColor: Colors.deepOrange
                                      .withValues(alpha: 0.08),
                                  onTap: () {
                                    setState(() {
                                      selectedRoute = route;
                                      _showRouteSelector = false;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
>>>>>>> Stashed changes
  }

  /// Build floating action buttons
  Widget _buildFloatingButtons(Map<String, BusData> displayBusData) {
    if (_showRouteSelector) {
      return const SizedBox.shrink();
    }

    final isEtaCardVisible =
        _selectedBusId != null && busData.containsKey(_selectedBusId);
    final bottomLift = isEtaCardVisible ? 180.0 : 0.0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomLift),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // View all buses button
          if (displayBusData.isNotEmpty)
            FloatingActionButton(
              heroTag: 'viewAllBusesBtn',
              mini: true,
              onPressed: _viewAllBuses,
              backgroundColor: Colors.green,
              child: const Icon(Icons.directions_bus),
            ),
          const SizedBox(height: 10),
          // Center on my location button
          FloatingActionButton(
            heroTag: 'myLocationBtn',
            mini: true,
            onPressed: _centerOnMyLocation,
            backgroundColor: Colors.deepOrange,
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}
