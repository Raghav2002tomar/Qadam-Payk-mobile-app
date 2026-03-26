
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../api_service/app_constocter.dart';
import '../../service/local_cache.dart';

// ─────────────────────────────────────────────────────────────
// This screen is for the SENDER (user) side only.
// It shows a full-screen map with:
//   • Pickup marker (green)
//   • Drop marker (red)
//   • Driver live location marker (blue truck) — polled every 10s
//   • Route from driver to pickup (when driver is en route)
//   • Route from pickup to drop (after driver reaches pickup)
// Only shown for in-city rides that are active (accepted / in_transit)
// There are NO ride start/complete buttons here.
// ─────────────────────────────────────────────────────────────

const Color _kGreen   = Color(0xFF008955);
const Color _kRed     = Color(0xFFE53935);
const Color _kBlue    = Color(0xFF1565C0);
const Color _kDark    = Color(0xFF1C1C1E);
const Color _kSubText = Color(0xFFAAAAAA);

class FullMapScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const FullMapScreen({super.key, required this.order});

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  final MapController _mapCtrl = MapController();

  // ── Routes ────────────────────────────────────────────────
  List<LatLng> _routePickupToDrop = [];  // Main route from pickup to drop
  List<LatLng> _routeDriverToPickup = []; // Route from driver to pickup
  bool _isFetchingRoute = false;
  bool _isFetchingDriverRoute = false;

  // ── Driver live location ──────────────────────────────────
  LatLng? _driverLocation;
  DateTime? _lastUpdated;
  Timer? _liveTimer;
  bool _isFetchingLive = false;

  // ── Status tracking ───────────────────────────────────────
  bool _hasDriverReachedPickup = false;

  // ── Parsed coords ─────────────────────────────────────────
  LatLng? _pickup;
  LatLng? _drop;
  bool _mapReady = false;

  // ── helpers ───────────────────────────────────────────────
  String get _orderId => widget.order["id"]?.toString() ?? "";

  bool get _isInCity {
    final t = (widget.order["trip_type"] ?? "").toString().toLowerCase().trim();
    return t == "incity" || t == "in_city" || t == "in city" || t == "local";
  }

  bool get _isActiveRide {
    final s = (widget.order["status"] ?? "").toString().toLowerCase();
    return s == "accepted" || s == "in_transit" || s == "in transit";
  }

  // ─────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _parseCoords();

    // Always fetch the main route from pickup to drop
    _fetchOsrmRoute();

    // Start live polling only when relevant
    if (_isInCity && _isActiveRide) {
      _fetchDriverLocation();
      _liveTimer = Timer.periodic(
        const Duration(seconds: 10),
            (_) => _fetchDriverLocation(),
      );
    }
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _mapCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  // PARSE COORDINATES FROM ORDER
  // ─────────────────────────────────────────────────────────
  void _parseCoords() {
    final pickLat = double.tryParse(
        widget.order["pickup_latitude"]?.toString() ?? "");
    final pickLng = double.tryParse(
        widget.order["pickup_longitude"]?.toString() ?? "");
    final dropLat = double.tryParse(
        widget.order["drop_latitude"]?.toString() ?? "");
    final dropLng = double.tryParse(
        widget.order["drop_longitude"]?.toString() ?? "");

    if (pickLat != null && pickLng != null) {
      _pickup = LatLng(pickLat, pickLng);
    }
    if (dropLat != null && dropLng != null) {
      _drop = LatLng(dropLat, dropLng);
    }
  }

  LatLng get _mapCenter {
    if (_driverLocation != null && !_hasDriverReachedPickup) {
      // Center on driver when he's on the way to pickup
      return _driverLocation!;
    }
    if (_pickup != null && _drop != null) {
      return LatLng(
        (_pickup!.latitude + _drop!.latitude) / 2,
        (_pickup!.longitude + _drop!.longitude) / 2,
      );
    }
    return _pickup ?? _drop ?? const LatLng(28.6139, 77.2090);
  }

  // ─────────────────────────────────────────────────────────
  // FETCH OSRM ROUTE (Pickup to Drop)
  // ─────────────────────────────────────────────────────────
  Future<void> _fetchOsrmRoute() async {
    if (_pickup == null || _drop == null) return;
    setState(() => _isFetchingRoute = true);

    try {
      final p = _pickup!;
      final d = _drop!;
      final url =
          "http://router.project-osrm.org/route/v1/driving/"
          "${p.longitude},${p.latitude};"
          "${d.longitude},${d.latitude}"
          "?overview=full&geometries=geojson";

      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final coords = (data["routes"][0]["geometry"]["coordinates"] as List)
            .map<LatLng>((c) => LatLng(c[1] as double, c[0] as double))
            .toList();

        if (mounted) setState(() => _routePickupToDrop = coords);
      }
    } catch (e) {
      debugPrint("OSRM route error: $e");
    } finally {
      if (mounted) setState(() => _isFetchingRoute = false);
    }
  }

  // ─────────────────────────────────────────────────────────
  // FETCH ROUTE FROM DRIVER TO PICKUP
  // ─────────────────────────────────────────────────────────
  Future<void> _fetchRouteDriverToPickup() async {
    if (_driverLocation == null || _pickup == null) return;
    if (_hasDriverReachedPickup) return; // No need to fetch if already at pickup

    setState(() => _isFetchingDriverRoute = true);

    try {
      final driver = _driverLocation!;
      final pickup = _pickup!;
      final url =
          "http://router.project-osrm.org/route/v1/driving/"
          "${driver.longitude},${driver.latitude};"
          "${pickup.longitude},${pickup.latitude}"
          "?overview=full&geometries=geojson";

      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final coords = (data["routes"][0]["geometry"]["coordinates"] as List)
            .map<LatLng>((c) => LatLng(c[1] as double, c[0] as double))
            .toList();

        if (mounted) setState(() => _routeDriverToPickup = coords);
      }
    } catch (e) {
      debugPrint("Driver route error: $e");
    } finally {
      if (mounted) setState(() => _isFetchingDriverRoute = false);
    }
  }

  // ─────────────────────────────────────────────────────────
  // FETCH DRIVER LIVE LOCATION
  // GET /api/courier/live-location/{orderId}
  // ─────────────────────────────────────────────────────────
  Future<void> _fetchDriverLocation() async {
    if (_isFetchingLive || _orderId.isEmpty) return;
    setState(() => _isFetchingLive = true);

    try {
      final token = await LocalCache.getToken();
      final res = await http
          .get(
        Uri.parse(
            "${App_Constructor().BaseURL}/api/courier/live-location/$_orderId"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["status"] == true && data["data"] != null) {
          final loc = data["data"] as Map<String, dynamic>;
          final lat = double.tryParse(loc["driver_latitude"]?.toString() ?? "");
          final lng = double.tryParse(loc["driver_longitude"]?.toString() ?? "");
          final updated = loc["last_updated"]?.toString();

          if (lat != null && lng != null && mounted) {
            final newLocation = LatLng(lat, lng);

            // Check if driver has reached pickup (within 50 meters)
            if (_pickup != null) {
              final distanceToPickup = _calculateDistance(
                  lat, lng,
                  _pickup!.latitude, _pickup!.longitude
              );

              if (distanceToPickup < 50 && !_hasDriverReachedPickup) {
                setState(() {
                  _hasDriverReachedPickup = true;
                  _routeDriverToPickup = []; // Clear driver route
                });
              }
            }

            setState(() {
              _driverLocation = newLocation;
              if (updated != null) {
                _lastUpdated = DateTime.tryParse(updated);
              }
            });

            // Fetch route from new driver location to pickup if needed
            if (!_hasDriverReachedPickup) {
              _fetchRouteDriverToPickup();
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Driver live location error: $e");
    } finally {
      if (mounted) setState(() => _isFetchingLive = false);
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371e3; // Earth's radius in meters
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final deltaPhi = (lat2 - lat1) * math.pi / 180;
    final deltaLambda = (lon2 - lon1) * math.pi / 180;

    final a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
        math.cos(phi1) * math.cos(phi2) *
            math.sin(deltaLambda / 2) * math.sin(deltaLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c; // Distance in meters
  }

  DateTime? _driverLocationUpdatedAt;

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return "${diff.inSeconds}s ago";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    return "${diff.inHours}h ago";
  }

  // ─────────────────────────────────────────────────────────
  // BUILD MARKERS
  // ─────────────────────────────────────────────────────────
  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Pickup - ALWAYS show
    if (_pickup != null) {
      markers.add(Marker(
        point: _pickup!,
        width: 44, height: 56,
        alignment: Alignment.bottomCenter,
        child: _LocationPin(
          color: _hasDriverReachedPickup ? _kGreen : _kGreen,
          label: "P",
          isPickup: true,
        ),
      ));
    }

    // Drop - ALWAYS show
    if (_drop != null) {
      markers.add(Marker(
        point: _drop!,
        width: 44, height: 56,
        alignment: Alignment.bottomCenter,
        child: _LocationPin(color: _kRed, label: "D", isPickup: false),
      ));
    }

    // Driver live marker
    if (_isInCity && _isActiveRide && _driverLocation != null) {
      markers.add(Marker(
        point: _driverLocation!,
        width: 60, height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kBlue.withOpacity(0.18),
                border: Border.all(color: _kBlue.withOpacity(0.5), width: 2),
              ),
            ),
            Container(
              width: 34, height: 34,
              decoration: const BoxDecoration(
                  color: _kBlue, shape: BoxShape.circle),
              child: const Icon(Icons.local_shipping,
                  color: Colors.white, size: 18),
            ),
          ],
        ),
      ));
    }

    // Always have at least one marker so flutter_map never gets an empty list
    if (markers.isEmpty) {
      markers.add(Marker(
        point: _mapCenter,
        width: 40, height: 40,
        child: const Icon(Icons.location_pin, color: _kGreen, size: 36),
      ));
    }

    return markers;
  }

  // ─────────────────────────────────────────────────────────
  // BUILD POLYLINES
  // ─────────────────────────────────────────────────────────
  List<Polyline> _buildPolylines() {
    final polylines = <Polyline>[];

    // Route from driver to pickup (shown when driver hasn't reached pickup yet)
    if (_isInCity && _isActiveRide &&
        _driverLocation != null && _pickup != null &&
        !_hasDriverReachedPickup && _routeDriverToPickup.isNotEmpty) {
      polylines.add(
        Polyline(
          points: _routeDriverToPickup,
          strokeWidth: 5,
          color: _kBlue.withOpacity(0.8),
          borderColor: Colors.white,
          borderStrokeWidth: 1.5,
        ),
      );
    }

    // Route from pickup to drop (always show once driver is on the way)
    if (_routePickupToDrop.isNotEmpty) {
      polylines.add(
        Polyline(
          points: _routePickupToDrop,
          strokeWidth: 5,
          color: _hasDriverReachedPickup ? _kGreen : _kGreen.withOpacity(0.4),
          borderColor: Colors.white,
          borderStrokeWidth: 1.5,
        ),
      );
    }
    // Fallback direct line if no route available
    else if (_pickup != null && _drop != null) {
      polylines.add(
        Polyline(
          points: [_pickup!, _drop!],
          strokeWidth: 4,
          color: _kGreen.withOpacity(0.5),
          borderColor: Colors.white30,
          borderStrokeWidth: 1,
        ),
      );
    }

    return polylines;
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final markers = _buildMarkers();
    final polylines = _buildPolylines();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── FULL MAP ───────────────────────────────────────
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: 13.0,
              onMapReady: () => setState(() => _mapReady = true),
            ),
            children: [
              TileLayer(
                urlTemplate:
                "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.qadampayk.app",
              ),
              if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
              MarkerLayer(markers: markers),
            ],
          ),

          // ── TOP BAR ────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    // Back button
                    _CircleButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.pop(context),
                    ),

                    const SizedBox(width: 12),

                    // Title chip
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.order["pickup_location"]
                              ?.toString()
                              .split(",")
                              .first ??
                              "Map View",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Route loading indicator
                    if (_isFetchingRoute || _isFetchingDriverRoute)
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                              color: _kGreen, strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── DRIVER LIVE BADGE (top-left overlay) ──────────
          if (_isInCity && _isActiveRide)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _driverLocation != null
                            ? Colors.greenAccent
                            : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _driverLocation != null
                          ? _hasDriverReachedPickup
                          ? "Driver at pickup • heading to drop"
                          : "Driver en route to pickup"
                          : "Locating driver...",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    if (_isFetchingLive) ...[
                      const SizedBox(width: 6),
                      const SizedBox(
                        width: 10, height: 10,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 1.5),
                      ),
                    ] else ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _fetchDriverLocation,
                        child: const Icon(Icons.refresh,
                            color: Colors.white70, size: 14),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // ── STATUS CHIP (showing current phase) ───────────
          if (_isInCity && _isActiveRide && _driverLocation != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 110,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _hasDriverReachedPickup ? _kGreen : _kBlue,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (_hasDriverReachedPickup ? _kGreen : _kBlue).withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _hasDriverReachedPickup ? Icons.location_on : Icons.route,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _hasDriverReachedPickup ? "HEADING TO DROP" : "HEADING TO PICKUP",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── MAP CONTROLS (bottom-right) ────────────────────
          Positioned(
            bottom: _isInCity && _isActiveRide ? 210 : 120,
            right: 12,
            child: Column(
              children: [
                // Center on driver (only when location available)
                if (_isInCity && _isActiveRide && _driverLocation != null)
                  _CircleButton(
                    icon: Icons.local_shipping,
                    color: _kBlue,
                    onTap: () => _mapCtrl.move(_driverLocation!, 16),
                  ),
                if (_isInCity && _isActiveRide && _driverLocation != null)
                  const SizedBox(height: 8),

                // Center on pickup
                if (_pickup != null)
                  _CircleButton(
                    icon: Icons.location_on,
                    color: _kGreen,
                    onTap: () => _mapCtrl.move(_pickup!, 16),
                  ),
                if (_pickup != null)
                  const SizedBox(height: 8),

                // Center on route
                _CircleButton(
                  icon: Icons.fit_screen,
                  onTap: () => _mapCtrl.move(_mapCenter, 13),
                ),
                const SizedBox(height: 8),

                // Zoom in
                _MapBtn(icon: Icons.add, onTap: () {
                  _mapCtrl.move(
                      _mapCtrl.camera.center, _mapCtrl.camera.zoom + 1);
                }),
                const SizedBox(height: 4),

                // Zoom out
                _MapBtn(icon: Icons.remove, onTap: () {
                  _mapCtrl.move(
                      _mapCtrl.camera.center, _mapCtrl.camera.zoom - 1);
                }),
              ],
            ),
          ),

          // ── BOTTOM INFO PANEL ──────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: _kDark,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Pickup row
                  _RouteInfoRow(
                    dotColor: _kGreen,
                    label: "P",
                    text: widget.order["pickup_location"]?.toString() ?? "—",
                  ),

                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                    child: Row(children: [
                      Container(
                          width: 1, height: 16,
                          color: Colors.white24),
                    ]),
                  ),

                  // Drop row
                  _RouteInfoRow(
                    dotColor: _kRed,
                    label: "D",
                    text: widget.order["drop_location"]?.toString() ?? "—",
                  ),

                  const SizedBox(height: 14),

                  // Stats row
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.straighten,
                        value: widget.order["distance"]?.toString() ?? "—",
                        label: "Distance",
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        icon: Icons.timer_outlined,
                        value: widget.order["time"]?.toString() ?? "—",
                        label: "Est. Time",
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        icon: Icons.currency_rupee,
                        value: widget.order["suggested_price"]?.toString() ?? "—",
                        label: "Price",
                        valueColor: const Color(0xFFFF6B3D),
                      ),
                    ],
                  ),

                  // Driver location info (if active in-city)
                  if (_isInCity && _isActiveRide && _driverLocation != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _kBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _kBlue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                              _hasDriverReachedPickup ? Icons.location_on : Icons.local_shipping,
                              color: _hasDriverReachedPickup ? _kGreen : _kBlue,
                              size: 18
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _hasDriverReachedPickup
                                  ? "Driver is heading to your drop location"
                                  : "Driver is on the way to pick you up",
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13),
                            ),
                          ),
                          if (_lastUpdated != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              _formatTimeAgo(_lastUpdated!),
                              style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11),
                            ),
                          ],
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: _fetchDriverLocation,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _kBlue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.refresh,
                                  color: _kBlue, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SMALL WIDGETS
// ─────────────────────────────────────────────────────────────

class _LocationPin extends StatelessWidget {
  final Color color;
  final String label;
  final bool isPickup;
  const _LocationPin({
    required this.color,
    required this.label,
    this.isPickup = true
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)
          ],
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ),
      ),
      // Pin tail
      CustomPaint(
        size: const Size(10, 7),
        painter: _PinTail(color: color),
      ),
    ],
  );
}

class _PinTail extends CustomPainter {
  final Color color;
  const _PinTail({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      ui.Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_PinTail o) => o.color != color;
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const _CircleButton(
      {required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 42, height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.18), blurRadius: 8)
        ],
      ),
      child: Icon(icon, color: color ?? Colors.black87, size: 22),
    ),
  );
}

class _MapBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.18), blurRadius: 6)
        ],
      ),
      child: Icon(icon, color: Colors.black87, size: 22),
    ),
  );
}

class _RouteInfoRow extends StatelessWidget {
  final Color dotColor;
  final String label;
  final String text;
  const _RouteInfoRow(
      {required this.dotColor, required this.label, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
            color: dotColor, shape: BoxShape.circle),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white, fontSize: 13, height: 1.3),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? valueColor;
  const _StatChip(
      {required this.icon,
        required this.value,
        required this.label,
        this.valueColor});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border:
        Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 12, color: _kSubText),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: _kSubText, fontSize: 10)),
          ]),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}