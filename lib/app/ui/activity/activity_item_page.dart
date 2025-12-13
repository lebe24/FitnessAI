import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ActivityItemPage extends StatefulWidget {
  const ActivityItemPage({super.key, required this.data});

  final String data;

  @override
  State<ActivityItemPage> createState() => _ActivityItemPageState();
}

class _ActivityItemPageState extends State<ActivityItemPage> {

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: GoogleMap(
        myLocationButtonEnabled: false,
        mapType: MapType.normal,
        initialCameraPosition: _kGooglePlex,
        zoomControlsEnabled: true,
      ),
    );
  }
}