// lib/screens/media/location_sharing_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:chatbox/constants/styles.dart';
import 'package:chatbox/services/media_service.dart';
import 'package:chatbox/models/user_model.dart';

class LocationSharingScreen extends StatefulWidget {
  final Function(LocationData)? onLocationSelected;

  const LocationSharingScreen({super.key, this.onLocationSelected});

  @override
  State<LocationSharingScreen> createState() => _LocationSharingScreenState();
}

class _LocationSharingScreenState extends State<LocationSharingScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  String _currentAddress = '';
  bool _isLoading = true;
  Set<Marker> _markers = {};

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      final position = await MediaService().getCurrentLocation();
      final address = await MediaService().getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentPosition = position;
        _currentAddress = address;
        _isLoading = false;
        _markers = {
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: InfoWindow(title: 'Your Location', snippet: address),
          ),
        };
      });

      // Move camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Location'),
        actions: [
          TextButton(
            onPressed: _shareLocation,
            child: const Text(
              'Share',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a place...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                filled: true,
                fillColor: AppColors.grey100,
              ),
              onSubmitted: _searchPlace,
            ),
          ),

          // Current location info
          if (_currentPosition != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.grey100,
              child: Row(
                children: [
                  Icon(Icons.location_on, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentAddress,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  TextButton(
                    onPressed: _getCurrentLocation,
                    child: const Text('Update'),
                  ),
                ],
              ),
            ),

          // Map
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition != null
                          ? LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            )
                          : const LatLng(0, 0),
                      zoom: 15,
                    ),
                    markers: _markers,
                    onTap: _onMapTap,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                  ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Current Location'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareLocation,
                    icon: const Icon(Icons.send),
                    label: const Text('Share Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onMapTap(LatLng position) async {
    try {
      final address = await MediaService().getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('selected_location'),
            position: position,
            infoWindow: InfoWindow(
              title: 'Selected Location',
              snippet: address,
            ),
          ),
        };
        _currentAddress = address;
      });

      // Update current position
      _currentPosition = Position(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to get address: $e')));
    }
  }

  Future<void> _searchPlace(String query) async {
    // TODO: Implement place search using Google Places API
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Place search coming soon!')));
  }

  void _shareLocation() {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location first')),
      );
      return;
    }

    final locationData = LocationData(
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      address: _currentAddress,
    );

    if (widget.onLocationSelected != null) {
      widget.onLocationSelected!(locationData);
    }

    Navigator.pop(context);
  }
}
