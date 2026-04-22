import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/bus_data.dart';
import '../services/firebase_bus_service.dart';
import '../services/location_service.dart';
import '../utils/map_utils.dart';
import '../widgets/bus_info_card.dart';
import '../widgets/bus_marker.dart';
import '../widgets/route_selector.dart';

/// Main page displaying the bus tracking map.
class BusMapPage extends StatefulWidget {
  const BusMapPage({super.key});

  @override
  State<BusMapPage> createState() => _BusMapPageState();
}

class _BusMapPageState extends State<BusMapPage> {
  final MapController mapController = MapController();
  final FirebaseBusService _busService = FirebaseBusService();

  LatLng? myCurrentLocation;
  Map<String, BusData> busData = {};
  String? selectedRoute;
  List<String> availableRoutes = [];
  StreamSubscription<Map<String, BusData>>? _busSubscription;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _listenToBusLocations();
  }

  @override
  void dispose() {
    _busSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    final location = await LocationService.determinePosition();
    if (!mounted) {
      return;
    }

    setState(() {
      myCurrentLocation = location;
    });
  }

  void _listenToBusLocations() {
    _busSubscription = _busService.listenToBusLocations().listen(
      (updatedBusData) {
        if (!mounted) {
          return;
        }

        setState(() {
          busData = updatedBusData;
          availableRoutes = _busService.getAvailableRoutes(updatedBusData);

          if (selectedRoute != null &&
              !availableRoutes.contains(selectedRoute)) {
            selectedRoute = null;
          }
        });
      },
      onError: (error) {
        debugPrint('Error listening to bus locations: $error');
      },
    );
  }

  Map<String, BusData> get filteredBusData {
    return _busService.filterBusesByRoute(busData, selectedRoute);
  }

  void _viewAllBuses() {
    final displayBuses = filteredBusData;
    if (displayBuses.isNotEmpty) {
      MapUtils.fitToBuses(mapController, displayBuses);
    }
  }

  void _centerOnMyLocation() {
    final location = myCurrentLocation;
    if (location != null) {
      mapController.move(location, 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayBusData = filteredBusData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Tracker - Real-time'),
        backgroundColor: const Color(0xFFFEC205),
      ),
      body: myCurrentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                _buildMap(displayBusData),
                _buildRouteSelector(),
                _buildInfoCards(displayBusData),
              ],
            ),
      floatingActionButton: _buildFloatingButtons(displayBusData),
    );
  }

  Widget _buildMap(Map<String, BusData> displayBusData) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: myCurrentLocation ?? LocationService.defaultLocation,
        initialZoom: 12,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        MarkerLayer(
          markers: [
            if (myCurrentLocation != null)
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
            ...displayBusData.entries
                .map((entry) => BusMarker.create(entry.key, entry.value))
                .toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildRouteSelector() {
    return Positioned(
      top: 16,
      left: 16,
      child: RouteSelector(
        selectedRoute: selectedRoute,
        availableRoutes: availableRoutes,
        onRouteChanged: (route) {
          setState(() {
            selectedRoute = route;
          });
        },
      ),
    );
  }

  Widget _buildInfoCards(Map<String, BusData> displayBusData) {
    Widget child;

    if (busData.isEmpty) {
      child = const WaitingForDataMessage();
    } else if (displayBusData.isEmpty) {
      child = NoBusesMessage(selectedRoute: selectedRoute);
    } else {
      child = BusInfoCard(
        busData: displayBusData,
        selectedRoute: selectedRoute,
      );
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Align(alignment: Alignment.bottomLeft, child: child),
    );
  }

  Widget _buildFloatingButtons(Map<String, BusData> displayBusData) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'center_location',
          mini: true,
          backgroundColor: Colors.blue,
          onPressed: _centerOnMyLocation,
          child: const Icon(Icons.my_location, color: Colors.white),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'view_all_buses',
          mini: true,
          backgroundColor: displayBusData.isEmpty ? Colors.grey : Colors.green,
          onPressed: displayBusData.isEmpty ? null : _viewAllBuses,
          child: const Icon(Icons.fit_screen, color: Colors.white),
        ),
      ],
    );
  }
}
