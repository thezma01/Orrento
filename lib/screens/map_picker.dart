import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapPickerScreen extends StatefulWidget {
  final Function(double, double) onLocationSelected;

  const MapPickerScreen({Key? key, required this.onLocationSelected})
      : super(key: key);

  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _pickedLocation;
  GoogleMapController? _mapController;
  final loc.Location _location = loc.Location();

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    var permissionGranted = await _location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }

    final currentLocation = await _location.getLocation();
    setState(() {
      _pickedLocation =
          LatLng(currentLocation.latitude!, currentLocation.longitude!);
    });

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_pickedLocation!, 15),
      );
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _pickedLocation = position;
    });
  }

  Future<void> _confirmLocation() async {
    if (_pickedLocation != null) {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _pickedLocation!.latitude,
        _pickedLocation!.longitude,
      );

      Placemark place = placemarks.first;
      String readableAddress =
          "${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}";

      // ✅ Call the required callback
      widget.onLocationSelected(
        _pickedLocation!.latitude,
        _pickedLocation!.longitude,
      );

      // ✅ Also pop the data back
      Navigator.pop(context, {
        'address': readableAddress,
        'latitude': _pickedLocation!.latitude,
        'longitude': _pickedLocation!.longitude,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pick Location")),
      body: _pickedLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
                if (_pickedLocation != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(_pickedLocation!, 15),
                  );
                }
              },
              initialCameraPosition: CameraPosition(
                target: _pickedLocation!,
                zoom: 15,
              ),
              onTap: _onMapTap,
              markers: {
                if (_pickedLocation != null)
                  Marker(
                    markerId: const MarkerId("selected"),
                    position: _pickedLocation!,
                  ),
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _confirmLocation,
        label: const Text("Confirm Location"),
        icon: const Icon(Icons.check),
      ),
    );
  }
}