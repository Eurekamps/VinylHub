import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class UbicacionView extends StatefulWidget {
  const UbicacionView({super.key});

  @override
  State<UbicacionView> createState() => _UbicacionViewState();
}

class _UbicacionViewState extends State<UbicacionView> {
  LatLng? _userLocation;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
  }

  Future<void> _obtenerUbicacion() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ubicación del usuario")),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : (_userLocation == null)
          ? Center(child: Text("No se pudo obtener la ubicación"))
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _userLocation!,
          zoom: 13,
        ),
        markers: {}, // Sin puntero
        circles: {
          Circle(
            circleId: CircleId("circle"),
            center: _userLocation!,
            radius: 2000,
            fillColor: Colors.blue.withOpacity(0.2),
            strokeColor: Colors.blueAccent.withOpacity(0.7),
            strokeWidth: 2,
          ),
        },
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
      ),
    );
  }
}
