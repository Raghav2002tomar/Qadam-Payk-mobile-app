import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'address_search_screen.dart';
import 'order_details_sheet.dart';

class CreateCourierScreen extends StatefulWidget {
  const CreateCourierScreen({super.key});

  @override
  State<CreateCourierScreen> createState() => _CreateCourierScreenState();
}

class _CreateCourierScreenState extends State<CreateCourierScreen> {
  final MapController mapController = MapController();

  LatLng? pickupLatLng;
  LatLng? dropLatLng;

  String pickupAddress = "Select pickup location";
  String dropAddress = "Select drop location";

  List<LatLng> routePoints = [];

  double distanceKm = 0;
  double durationMin = 0;

  LatLng currentCenter = const LatLng(28.6139, 77.2090);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition();
    currentCenter = LatLng(position.latitude, position.longitude);
    mapController.move(currentCenter, 15);
  }

  Future<void> _openSearch(bool isPickup) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddressSearchScreen()),
    );

    if (result != null) {
      LatLng latLng = LatLng(result['lat'], result['lng']);
      mapController.move(latLng, 15);

      setState(() {
        if (isPickup) {
          pickupLatLng = latLng;
          pickupAddress = result['address'];
        } else {
          dropLatLng = latLng;
          dropAddress = result['address'];
        }
      });

      if (pickupLatLng != null && dropLatLng != null) {
        _getRoute();
      }
    }
  }

  Future<void> _getRoute() async {
    final url =
        "http://router.project-osrm.org/route/v1/driving/"
        "${pickupLatLng!.longitude},${pickupLatLng!.latitude};"
        "${dropLatLng!.longitude},${dropLatLng!.latitude}"
        "?overview=full&geometries=geojson";

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    final coords = data['routes'][0]['geometry']['coordinates'];

    final dist = data['routes'][0]['distance'];
    final dur = data['routes'][0]['duration'];

    setState(() {
      routePoints = coords
          .map<LatLng>((c) => LatLng(c[1], c[0]))
          .toList();

      distanceKm = dist / 1000;
      durationMin = dur / 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: currentCenter,
              initialZoom: 15,
            ),
            children: [

              TileLayer(
                urlTemplate:
                "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.qadampayk.app",
              ),

              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 5,
                      color: Colors.blue,
                    )
                  ],
                ),

              if (pickupLatLng != null)
                MarkerLayer(markers: [
                  Marker(
                    point: pickupLatLng!,
                    child: const Icon(Icons.location_pin,
                        color: Colors.green, size: 40),
                  )
                ]),

              if (dropLatLng != null)
                MarkerLayer(markers: [
                  Marker(
                    point: dropLatLng!,
                    child: const Icon(Icons.location_pin,
                        color: Colors.red, size: 40),
                  )
                ]),

            ],
          ),

          Positioned(
            top: 50,
            left: 15,
            right: 15,
            child: Column(
              children: [

                _locationTile(
                    title: pickupAddress,
                    color: Colors.green,
                    onTap: () => _openSearch(true)),

                const SizedBox(height: 10),

                _locationTile(
                    title: dropAddress,
                    color: Colors.red,
                    onTap: () => _openSearch(false)),

              ],
            ),
          ),

          if (routePoints.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      "Distance: ${distanceKm.toStringAsFixed(2)} km",
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      "ETA: ${durationMin.toStringAsFixed(0)} mins",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          if (routePoints.isNotEmpty)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => OrderDetailsSheet(
                      pickupAddress: pickupAddress,
                      dropAddress: dropAddress,
                      distanceKm: distanceKm,
                      durationMin: durationMin,
                    ),
                  );
                },

                child: const Text("Continue to Order Details"),
              ),
            ),
        ],
      ),
    );
  }

  Widget _locationTile(
      {required String title,
        required Color color,
        required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.circle, color: color, size: 14),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
      ),
    );
  }
}
