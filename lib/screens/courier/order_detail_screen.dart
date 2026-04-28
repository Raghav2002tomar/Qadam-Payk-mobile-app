//
//
// import 'dart:async';
// import 'dart:convert';
// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';
// import 'package:provider/provider.dart';
//
// import '../../api_service/app_constocter.dart';
// import '../../api_service/logger.dart';
// import '../../providers/translate_provider.dart';
// import '../../service/local_cache.dart';
// import '../auth/SignInScreen.dart';
// import '../mainView/provide/ChatProvider.dart';
//
// // Dark theme colors matching driver UI
// const Color kPrimaryColor = Color(0xFF6FD94A); // Green from driver UI
// const Color kDarkBg = Color(0xFF1C1C1E);
// const Color kCardBg = Color(0xFF2A2A2C);
// const Color kPriceColor = Color(0xFFFF6B3D);
// const Color kSubText = Color(0xFF8E8E93);
//
// class CourierDetailScreen extends StatefulWidget {
//   final String orderId;
//
//   const CourierDetailScreen({
//     super.key,
//     required this.orderId,
//   });
//
//   @override
//   State<CourierDetailScreen> createState() => _CourierDetailScreenState();
// }
//
// class _CourierDetailScreenState extends State<CourierDetailScreen>
//     with TickerProviderStateMixin {
//   late MapController _mapController;
//
//   // Bottom sheet state
//   bool _isBottomSheetExpanded = false;
//   double _bottomSheetHeight = 180; // Collapsed height
//   final double _collapsedHeight = 180;
//   final double _expandedHeight = 550;
//   bool isRefreshing = false; // New state for refresh indicator
//
//   // Data
//   Map<String, dynamic>? orderData;
//   List<dynamic> interests = [];
//   bool isLoading = true;
//   bool isLoadingInterests = false;
//   bool isAcceptingDriver = false;
//   String? errorMessage;
//   String? selectedDriverId;
//
//   // Live location tracking
//   LatLng? _driverLocation;
//   DateTime? _driverLocationUpdatedAt;
//   Timer? _liveLocationTimer;
//   bool _isFetchingLiveLocation = false;
//
//   // Route data
//   List<LatLng> _routePickupToDrop = [];
//   List<LatLng> _routeDriverToPickup = [];
//   bool _isFetchingRoute = false;
//   bool _hasDriverReachedPickup = false;
//   double? _heading;
//
//   // Parsed coordinates
//   LatLng? _pickup;
//   LatLng? _drop;
//
//   String get orderId => widget.orderId;
//
//   bool get _isInCity {
//     final type = (orderData?["trip_type"] ?? "").toString().toLowerCase().trim();
//     return type == "incity" ||
//         type == "in_city" ||
//         type == "in city" ||
//         type == "local";
//   }
//
//   bool get _isActiveRide {
//     final status = (orderData?["status"] ?? "").toString().toLowerCase();
//     return status == "accepted" ||
//         status == "in_transit" ||
//         status == "in transit";
//   }
//
//   bool get _isPending {
//     final status = (orderData?["status"] ?? "").toString().toLowerCase();
//     return status == "pending" || status == "searching";
//   }
//
//   bool get _isCompleted {
//     final status = (orderData?["status"] ?? "").toString().toLowerCase();
//     return status == "completed";
//   }
//
//   String _status(String raw) {
//     switch (raw) {
//       case "pending":
//         return "Searching";
//       case "accepted":
//         return "Accepted";
//       case "in_transit":
//         return "In Transit";
//       case "completed":
//         return "Delivered";
//       default:
//         return raw;
//     }
//   }
//
//   String get displayStatus => _status(orderData?["status"] ?? "");
//
//   // Add this method to get the accepted driver from interests
//   Map<String, dynamic>? _getAcceptedDriver() {
//     if (orderData == null) return null;
//
//     final acceptedDriverId = orderData?["accepted_driver_id"];
//     if (acceptedDriverId == null) return null;
//
//     // Find the driver in interests that matches the accepted_driver_id
//     try {
//       final acceptedInterest = interests.firstWhere(
//             (interest) => interest["driver_id"] == acceptedDriverId,
//         orElse: () => null,
//       );
//
//       if (acceptedInterest != null) {
//         return acceptedInterest["driver"] as Map<String, dynamic>?;
//       }
//     } catch (e) {
//       debugPrint("Error finding accepted driver: $e");
//     }
//
//     return null;
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _mapController = MapController();
//     _fetchOrderDetails();
//     _fetchInterests();
//   }
//
//   @override
//   void dispose() {
//     _mapController.dispose();
//     _liveLocationTimer?.cancel();
//     super.dispose();
//   }
//
//   String _calculateEstimatedTime(double distanceInMeters) {
//     // Assume average speed of 30 km/h in city
//     final speedKmPerHour = 30.0;
//     final distanceKm = distanceInMeters / 1000;
//     final timeHours = distanceKm / speedKmPerHour;
//     final timeMinutes = (timeHours * 60).round();
//
//     if (timeMinutes < 1) return "Less than a minute";
//     if (timeMinutes < 60) return "$timeMinutes min";
//
//     final hours = (timeMinutes / 60).floor();
//     final minutes = timeMinutes % 60;
//     return "$hours hr ${minutes}min";
//   }
//
//
//   // New method to refresh all data
//   Future<void> _refreshData() async {
//     if (isRefreshing) return;
//
//     setState(() {
//       isRefreshing = true;
//     });
//
//     try {
//       // Clear existing route data
//       setState(() {
//         _routePickupToDrop = [];
//         _routeDriverToPickup = [];
//         _driverLocation = null;
//         _hasDriverReachedPickup = false;
//       });
//
//       // Fetch fresh data
//       await Future.wait([
//         _fetchOrderDetails(),
//         _fetchInterests(),
//       ]);
//
//       // Show success toast
//       if (mounted) {
//         Fluttertoast.showToast(
//           msg: "Data refreshed successfully",
//           backgroundColor: kPrimaryColor,
//           textColor: Colors.black,
//           toastLength: Toast.LENGTH_SHORT,
//         );
//       }
//     } catch (e) {
//       debugPrint("Refresh error: $e");
//       if (mounted) {
//         Fluttertoast.showToast(
//           msg: "Failed to refresh data",
//           backgroundColor: Colors.red,
//           textColor: Colors.white,
//           toastLength: Toast.LENGTH_SHORT,
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           isRefreshing = false;
//         });
//       }
//     }
//   }
//
//
//
//   // Parse coordinates from order
// // Parse coordinates from order
// // Parse coordinates from order
//   void _parseCoords() {
//     if (orderData == null) return;
//
//     final pickLat = double.tryParse(
//         orderData?["pickup_latitude"]?.toString() ?? "");
//     final pickLng = double.tryParse(
//         orderData?["pickup_longitude"]?.toString() ?? "");
//     final dropLat = double.tryParse(
//         orderData?["drop_latitude"]?.toString() ?? "");
//     final dropLng = double.tryParse(
//         orderData?["drop_longitude"]?.toString() ?? "");
//
//     // Always set drop if available
//     if (dropLat != null && dropLng != null) {
//       _drop = LatLng(dropLat, dropLng);
//     }
//
//     // Only set pickup if coordinates are available
//     if (pickLat != null && pickLng != null) {
//       _pickup = LatLng(pickLat, pickLng);
//     } else {
//       // If pickup coordinates are missing, try to geocode the address
//       _geocodePickupAddress();
//     }
//
//     // Only fetch route if both points are available
//     if (_pickup != null && _drop != null) {
//       _fetchOsrmRoute();
//     }
//   }
//
// // Geocode pickup address to get coordinates
//   Future<void> _geocodePickupAddress() async {
//     final pickupAddress = orderData?["pickup_location"]?.toString();
//     if (pickupAddress == null || pickupAddress.isEmpty) return;
//
//     try {
//       // Using OpenStreetMap Nominatim API for geocoding (free, no API key required)
//       final encodedAddress = Uri.encodeComponent(pickupAddress);
//       final url = "https://nominatim.openstreetmap.org/search?q=$encodedAddress&format=json&limit=1";
//
//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           'User-Agent': 'QadamPaykApp/1.0', // Required by Nominatim
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data.isNotEmpty) {
//           final lat = double.tryParse(data[0]["lat"]?.toString() ?? "");
//           final lng = double.tryParse(data[0]["lon"]?.toString() ?? "");
//
//           if (lat != null && lng != null && mounted) {
//             setState(() {
//               _pickup = LatLng(lat, lng);
//             });
//
//             // Now fetch the route
//             if (_drop != null) {
//               _fetchOsrmRoute();
//             }
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint("Geocoding error: $e");
//     }
//   }
//
//   LatLng get _mapCenter {
//     // If we have both pickup and drop, center on their midpoint
//     if (_pickup != null && _drop != null) {
//       // Calculate bounds to show entire route
//       final minLat = math.min(_pickup!.latitude, _drop!.latitude);
//       final maxLat = math.max(_pickup!.latitude, _drop!.latitude);
//       final minLng = math.min(_pickup!.longitude, _drop!.longitude);
//       final maxLng = math.max(_pickup!.longitude, _drop!.longitude);
//
//       return LatLng(
//         (minLat + maxLat) / 2,
//         (minLng + maxLng) / 2,
//       );
//     }
//
//     // Fallback to driver location if available
//     if (_driverLocation != null && !_hasDriverReachedPickup && _isActiveRide) {
//       return _driverLocation!;
//     }
//
//     return _pickup ?? _drop ?? const LatLng(28.6139, 77.2090);
//   }
//
//
//   // Fetch OSRM route
// // Fetch OSRM route between two points
//   Future<void> _fetchOsrmRoute({LatLng? start, LatLng? end}) async {
//     final startPoint = start ?? _pickup;
//     final endPoint = end ?? _drop;
//
//     if (startPoint == null || endPoint == null) return;
//
//     setState(() => _isFetchingRoute = true);
//
//     try {
//       final url =
//           "http://router.project-osrm.org/route/v1/driving/"
//           "${startPoint.longitude},${startPoint.latitude};"
//           "${endPoint.longitude},${endPoint.latitude}"
//           "?overview=full&geometries=geojson";
//
//       final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
//
//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         final coords = (data["routes"][0]["geometry"]["coordinates"] as List)
//             .map<LatLng>((c) => LatLng(c[1] as double, c[0] as double))
//             .toList();
//
//         if (mounted) {
//           setState(() {
//             // Determine which route this is based on the points
//             if (startPoint == _driverLocation && endPoint == _pickup) {
//               _routeDriverToPickup = coords;
//             } else if (startPoint == _pickup && endPoint == _drop) {
//               _routePickupToDrop = coords;
//             }
//           });
//         }
//       }
//     } catch (e) {
//       debugPrint("OSRM route error: $e");
//     } finally {
//       if (mounted) setState(() => _isFetchingRoute = false);
//     }
//   }
//
// // Update the _fetchRouteDriverToPickup method
//   Future<void> _fetchRouteDriverToPickup() async {
//     if (_driverLocation == null || _pickup == null) return;
//     if (_hasDriverReachedPickup) return;
//
//     await _fetchOsrmRoute(start: _driverLocation!, end: _pickup!);
//   }
//   // Fetch route from driver to pickup
//   // Future<void> _fetchRouteDriverToPickup() async {
//   //   if (_driverLocation == null || _pickup == null) return;
//   //   if (_hasDriverReachedPickup) return;
//   //
//   //   try {
//   //     final driver = _driverLocation!;
//   //     final pickup = _pickup!;
//   //     final url =
//   //         "http://router.project-osrm.org/route/v1/driving/"
//   //         "${driver.longitude},${driver.latitude};"
//   //         "${pickup.longitude},${pickup.latitude}"
//   //         "?overview=full&geometries=geojson";
//   //
//   //     final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
//   //
//   //     if (res.statusCode == 200) {
//   //       final data = jsonDecode(res.body);
//   //       final coords = (data["routes"][0]["geometry"]["coordinates"] as List)
//   //           .map<LatLng>((c) => LatLng(c[1] as double, c[0] as double))
//   //           .toList();
//   //
//   //       if (mounted) setState(() => _routeDriverToPickup = coords);
//   //     }
//   //   } catch (e) {
//   //     debugPrint("Driver route error: $e");
//   //   }
//   // }
//
//   // Start live location polling
//   void _startLiveLocationPolling() {
//     _liveLocationTimer?.cancel();
//     _fetchDriverLiveLocation();
//     _liveLocationTimer = Timer.periodic(
//       const Duration(seconds: 10),
//           (_) => _fetchDriverLiveLocation(),
//     );
//   }
//
//   void _stopLiveLocationPolling() {
//     _liveLocationTimer?.cancel();
//     _liveLocationTimer = null;
//   }
//
//   // Fetch driver live location
//   Future<void> _fetchDriverLiveLocation() async {
//     if (_isFetchingLiveLocation || orderId.isEmpty) return;
//     setState(() => _isFetchingLiveLocation = true);
//
//     try {
//       final token = await LocalCache.getToken();
//       final response = await http.get(
//         Uri.parse(
//             "${App_Constructor().BaseURL}/api/courier/live-location/$orderId"),
//         headers: {
//           "Authorization": "Bearer $token",
//           "Accept": "application/json",
//         },
//       ).timeout(const Duration(seconds: 8));
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data["status"] == true && data["data"] != null) {
//           final loc = data["data"] as Map<String, dynamic>;
//           final driverLat =
//           double.tryParse(loc["driver_latitude"]?.toString() ?? "");
//           final driverLng =
//           double.tryParse(loc["driver_longitude"]?.toString() ?? "");
//           final updatedAt = loc["last_updated"]?.toString();
//
//           if (driverLat != null && driverLng != null && mounted) {
//             final newLocation = LatLng(driverLat, driverLng);
//
//             // Check if driver has reached pickup
//             if (_pickup != null) {
//               final distanceToPickup = _calculateDistance(
//                   driverLat, driverLng,
//                   _pickup!.latitude, _pickup!.longitude);
//
//               if (distanceToPickup < 50 && !_hasDriverReachedPickup) {
//                 setState(() {
//                   _hasDriverReachedPickup = true;
//                   _routeDriverToPickup = [];
//                 });
//               }
//             }
//
//             setState(() {
//               _driverLocation = newLocation;
//               if (updatedAt != null) {
//                 _driverLocationUpdatedAt = DateTime.tryParse(updatedAt);
//               }
//             });
//
//             if (!_hasDriverReachedPickup) {
//               _fetchRouteDriverToPickup();
//             }
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint("Live location fetch error: $e");
//     } finally {
//       if (mounted) setState(() => _isFetchingLiveLocation = false);
//     }
//   }
//
//   double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
//     const double R = 6371e3;
//     final phi1 = lat1 * math.pi / 180;
//     final phi2 = lat2 * math.pi / 180;
//     final deltaPhi = (lat2 - lat1) * math.pi / 180;
//     final deltaLambda = (lon2 - lon1) * math.pi / 180;
//
//     final a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
//         math.cos(phi1) * math.cos(phi2) *
//             math.sin(deltaLambda / 2) * math.sin(deltaLambda / 2);
//     final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
//
//     return R * c;
//   }
//
//   String _formatTimeAgo(DateTime dt) {
//     final diff = DateTime.now().difference(dt);
//     if (diff.inSeconds < 60) return "${diff.inSeconds}s ago";
//     if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
//     return "${diff.inHours}h ago";
//   }
//
//   String _formatDistance(double meters) {
//     if (meters < 1000) {
//       return "${meters.round()} m";
//     }
//     return "${(meters / 1000).toStringAsFixed(1)} km";
//   }
//
//   // Fetch order details
// // Add this to your _fetchOrderDetails method after setting orderData
//   Future<void> _fetchOrderDetails() async {
//     setState(() {
//       isLoading = true;
//       errorMessage = null;
//     });
//
//     try {
//       final token = await LocalCache.getToken();
//       final response = await http.get(
//         Uri.parse("${App_Constructor().BaseURL}/api/sender/couriers/$orderId"),
//         headers: {
//           "Authorization": "Bearer $token",
//           "Accept": "application/json",
//         },
//       );
//
//       final data = jsonDecode(response.body);
//       debugPrint("Order details response: ${response.body}");
//
//       if (response.statusCode == 200 && data["status"] == true) {
//         setState(() {
//           orderData = data["data"];
//         });
//
//         // Debug driver info
//         if (orderData?["driver"] != null) {
//           debugPrint("Driver data exists: ${orderData!["driver"]}");
//           debugPrint("Driver is Map: ${orderData!["driver"] is Map}");
//           if (orderData!["driver"] is Map) {
//             debugPrint("Driver map: ${orderData!["driver"]}");
//           }
//         } else {
//           debugPrint("No driver data in response");
//         }
//
//         _parseCoords();
//
//         // Start polling only for in-city active rides
//         if (_isInCity && _isActiveRide) {
//           _startLiveLocationPolling();
//         } else {
//           _stopLiveLocationPolling();
//         }
//       } else {
//         setState(() {
//           errorMessage = data["message"] ?? "Failed to load order details";
//         });
//       }
//     } catch (e) {
//       setState(() => errorMessage = "Network error: $e");
//       debugPrint("Fetch order details error: $e");
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//   // Fetch interested drivers
//   Future<void> _fetchInterests() async {
//     setState(() => isLoadingInterests = true);
//     try {
//       final token = await LocalCache.getToken();
//       final response = await http.get(
//         Uri.parse(
//             "${App_Constructor().BaseURL}/api/courier/request/$orderId/interests"),
//         headers: {
//           "Authorization": "Bearer $token",
//           "Content-Type": "application/json",
//         },
//       );
//       final data = jsonDecode(response.body);
//       if (response.statusCode == 200 && data["status"] == true) {
//         setState(() => interests = data["data"] ?? []);
//       }
//     } catch (e) {
//       debugPrint("Fetch interests error: $e");
//     } finally {
//       setState(() => isLoadingInterests = false);
//     }
//   }
//
//   // Accept driver
//   Future<void> _acceptDriver(Map<String, dynamic> interest) async {
//     setState(() => isAcceptingDriver = true);
//
//     try {
//       final token = await LocalCache.getToken();
//       final response = await http.post(
//         Uri.parse(
//             "${App_Constructor().BaseURL}/api/courier/request/$orderId/accept-driver"),
//         headers: {
//           "Authorization": "Bearer $token",
//           "Content-Type": "application/json",
//         },
//         body: jsonEncode({
//           "driver_id": interest["driver_id"].toString(),
//         }),
//       );
//
//       final data = jsonDecode(response.body);
//       if (response.statusCode == 200 && data["status"] == true) {
//         await _fetchOrderDetails();
//         await _fetchInterests();
//
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                   "Driver accepted • ${interest["driver"]?["name"] ?? ""}"),
//               backgroundColor: kPrimaryColor,
//             ),
//           );
//         }
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(data["message"] ?? "Failed to accept driver"),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       debugPrint("Accept driver error: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Network error occurred"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => isAcceptingDriver = false);
//     }
//   }
//
//   void _confirmAcceptDriver(Map<String, dynamic> interest) {
//     final driver = interest["driver"] as Map<String, dynamic>? ?? {};
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         backgroundColor: kCardBg,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         title: const Text("Confirm Driver", style: TextStyle(color: Colors.white)),
//         content: Text(
//           "Accept ${driver["name"] ?? "this driver"} for TJS ${interest["driver_price"]}?",
//           style: const TextStyle(color: Colors.white70),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _acceptDriver(interest);
//             },
//             style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
//             child: const Text("Accept",
//                 style: TextStyle(color: Colors.black)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Open chat with driver
// // Open chat with driver
//   Future<void> _openChat(dynamic driver) async {
//     if (driver == null) return;
//
//     final token = await LocalCache.getToken();
//     if (token == null || token.isEmpty) {
//       Fluttertoast.showToast(
//         msg: context.read<TranslateProvider>().t('txt_login_first'),
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//       );
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => const PhoneNumberScreen(),
//         ),
//       );
//       return;
//     }
//
//     final chatProvider = Provider.of<ChatProvider>(
//       context,
//       listen: false,
//     );
//
//     await chatProvider.startChat(
//       context: context,
//       otherUserId: driver["id"],
//       userName: driver["name"] ?? 'Driver',
//     );
//   }
//
//
//
//   // Build markers for map
//   List<Marker> _buildMarkers() {
//     final markers = <Marker>[];
//
//     if (_pickup != null) {
//       markers.add(Marker(
//         point: _pickup!,
//         width: 44, height: 56,
//         alignment: Alignment.bottomCenter,
//         child: _LocationPin(
//           color: kPrimaryColor,
//           label: "P",
//           isPickup: true,
//         ),
//       ));
//     }
//
//     if (_drop != null) {
//       markers.add(Marker(
//         point: _drop!,
//         width: 44, height: 56,
//         alignment: Alignment.bottomCenter,
//         child: _LocationPin(color: Colors.red, label: "D", isPickup: false),
//       ));
//     }
//
//     if (_isInCity && _isActiveRide && _driverLocation != null) {
//       markers.add(Marker(
//         point: _driverLocation!,
//         width: 60, height: 60,
//         child: Stack(
//           alignment: Alignment.center,
//           children: [
//             Container(
//               width: 52, height: 52,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: Colors.blue.withOpacity(0.18),
//                 border: Border.all(color: Colors.blue.withOpacity(0.5), width: 2),
//               ),
//             ),
//             Container(
//               width: 34, height: 34,
//               decoration: const BoxDecoration(
//                   color: Colors.blue, shape: BoxShape.circle),
//               child: const Icon(Icons.local_shipping,
//                   color: Colors.white, size: 18),
//             ),
//           ],
//         ),
//       ));
//     }
//
//     if (markers.isEmpty) {
//       markers.add(Marker(
//         point: _mapCenter,
//         width: 40, height: 40,
//         child: const Icon(Icons.location_pin, color: kPrimaryColor, size: 36),
//       ));
//     }
//
//     return markers;
//   }
//
//   // Build polylines for map
// // Build polylines for map
//   List<Polyline> _buildPolylines() {
//     final polylines = <Polyline>[];
//
//     // Route from driver to pickup (shown when driver is en route)
//     if (_isInCity && _isActiveRide &&
//         _driverLocation != null && _pickup != null &&
//         !_hasDriverReachedPickup) {
//
//       if (_routeDriverToPickup.isNotEmpty) {
//         polylines.add(
//           Polyline(
//             points: _routeDriverToPickup,
//             strokeWidth: 5,
//             color: Colors.blue.withOpacity(0.8),
//             borderColor: Colors.white,
//             borderStrokeWidth: 1.5,
//           ),
//         );
//       } else {
//         // Fallback to straight line if route not available
//         polylines.add(
//           Polyline(
//             points: [_driverLocation!, _pickup!],
//             strokeWidth: 3,
//             color: Colors.blue.withOpacity(0.5),
//             borderColor: Colors.white30,
//             borderStrokeWidth: 1,
//           ),
//         );
//       }
//     }
//
//     // Route from pickup to drop (always show if both points exist)
//     if (_pickup != null && _drop != null) {
//       if (_routePickupToDrop.isNotEmpty) {
//         polylines.add(
//           Polyline(
//             points: _routePickupToDrop,
//             strokeWidth: 5,
//             color: _hasDriverReachedPickup ? kPrimaryColor : kPrimaryColor.withOpacity(0.6),
//             borderColor: Colors.white,
//             borderStrokeWidth: 1.5,
//           ),
//         );
//       } else {
//         // Fallback to straight line
//         polylines.add(
//           Polyline(
//             points: [_pickup!, _drop!],
//             strokeWidth: 4,
//             color: kPrimaryColor.withOpacity(0.5),
//             borderColor: Colors.white30,
//             borderStrokeWidth: 1,
//           ),
//         );
//       }
//     }
//
//     return polylines;
//   }
//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return Scaffold(
//         backgroundColor: kDarkBg,
//         body: const Center(
//           child: CircularProgressIndicator(
//             color: kPrimaryColor,
//           ),
//         ),
//       );
//     }
//
//     if (errorMessage != null || orderData == null) {
//       return Scaffold(
//         backgroundColor: kDarkBg,
//         body: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.error_outline, size: 64, color: Colors.grey.shade600),
//                 const SizedBox(height: 16),
//                 Text(
//                   errorMessage ?? "Failed to load order",
//                   style: const TextStyle(color: Colors.white70),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 24),
//                 ElevatedButton(
//                   onPressed: _fetchOrderDetails,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: kPrimaryColor,
//                     foregroundColor: Colors.black,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 32,
//                       vertical: 12,
//                     ),
//                   ),
//                   child: const Text("Retry"),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }
//
//     final markers = _buildMarkers();
//     final polylines = _buildPolylines();
//
//     return Scaffold(
//       backgroundColor: kDarkBg,
//       body: Stack(
//         children: [
//           // Full screen map
//           FlutterMap(
//             mapController: _mapController,
//             options: MapOptions(
//               initialCenter: _mapCenter,
//               initialZoom: 13.0,
//             ),
//             children: [
//               TileLayer(
//                 urlTemplate: "https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}",
//                 subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
//                 userAgentPackageName: "com.qadampayk.app",
//               ),
//               if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
//               MarkerLayer(markers: markers),
//             ],
//           ),
//
//           // Top gradient
//           Positioned(
//             top: 0, left: 0, right: 0,
//             child: Container(
//               height: 120,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     Colors.black.withOpacity(0.7),
//                     Colors.transparent,
//                   ],
//                 ),
//               ),
//             ),
//           ),
//
//           // Top bar with back button and status
//           Positioned(
//             top: MediaQuery.of(context).padding.top + 10,
//             left: 12,
//             right: 12,
//             child: Row(
//               children: [
//                 // Back button
//                 _CircleButton(
//                   icon: Icons.arrow_back,
//                   onTap: () => Navigator.pop(context),
//                   dark: true,
//                 ),
//                 const SizedBox(width: 12),
//                 // Status badge
//                 Expanded(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 14, vertical: 8),
//                     decoration: BoxDecoration(
//                       color: kCardBg,
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(color: Colors.white.withOpacity(0.1)),
//                     ),
//                     child: Row(
//                       children: [
//                         Container(
//                           width: 8, height: 8,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: _getStatusColor(),
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Text(
//                           displayStatus,
//                           style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 13,
//                               fontWeight: FontWeight.w600),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 // Order ID
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 12, vertical: 8),
//                   decoration: BoxDecoration(
//                     color: kPrimaryColor,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     "#$orderId",
//                     style: const TextStyle(
//                         color: Colors.black,
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // Live location badge (for active rides)
//           if (_isInCity && _isActiveRide)
//             Positioned(
//               top: MediaQuery.of(context).padding.top + 70,
//               left: 12,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 12, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: kCardBg,
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(color: Colors.white.withOpacity(0.1)),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Container(
//                       width: 8, height: 8,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: _driverLocation != null
//                             ? kPrimaryColor
//                             : Colors.orange,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       _driverLocation != null
//                           ? _hasDriverReachedPickup
//                           ? "Driver at pickup"
//                           : "Driver en route"
//                           : "Locating driver...",
//                       style: TextStyle(
//                           color: Colors.white.withOpacity(0.9),
//                           fontSize: 11,
//                           fontWeight: FontWeight.w500),
//                     ),
//                     if (_driverLocation != null && _driverLocationUpdatedAt != null) ...[
//                       const SizedBox(width: 8),
//                       Text(
//                         _formatTimeAgo(_driverLocationUpdatedAt!),
//                         style: TextStyle(
//                           color: Colors.white.withOpacity(0.5),
//                           fontSize: 10,
//                         ),
//                       ),
//                     ],
//                     const SizedBox(width: 4),
//                     GestureDetector(
//                       onTap: _fetchDriverLiveLocation,
//                       child: Container(
//                         padding: const EdgeInsets.all(4),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                         child: Icon(
//                           Icons.refresh,
//                           color: Colors.white.withOpacity(0.7),
//                           size: 14,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//           // Map controls
//           Positioned(
//             bottom: _bottomSheetHeight + 20,
//             right: 12,
//             child: Column(
//               children: [
//                 if (_isInCity && _isActiveRide && _driverLocation != null)
//                   _CircleButton(
//                     icon: Icons.local_shipping,
//                     color: Colors.blue,
//                     onTap: () => _mapController.move(_driverLocation!, 16),
//                   ),
//                 if (_isInCity && _isActiveRide && _driverLocation != null)
//                   const SizedBox(height: 8),
//                 _CircleButton(
//                   icon: Icons.location_on,
//                   color: kPrimaryColor,
//                   onTap: () => _pickup != null
//                       ? _mapController.move(_pickup!, 16)
//                       : null,
//                 ),
//                 const SizedBox(height: 8),
//                 _CircleButton(
//                   icon: Icons.flag,
//                   color: Colors.red,
//                   onTap: () => _drop != null
//                       ? _mapController.move(_drop!, 16)
//                       : null,
//                 ),
//                 const SizedBox(height: 8),
//                 _MapBtn(icon: Icons.add, onTap: () {
//                   _mapController.move(
//                       _mapController.camera.center,
//                       _mapController.camera.zoom + 1);
//                 }),
//                 const SizedBox(height: 4),
//                 _MapBtn(icon: Icons.remove, onTap: () {
//                   _mapController.move(
//                       _mapController.camera.center,
//                       _mapController.camera.zoom - 1);
//                 }),
//               ],
//             ),
//           ),
//
//           // Collapsible Bottom Sheet
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             child: _buildCollapsibleBottomSheet(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Color _getStatusColor() {
//     switch (displayStatus) {
//       case "Searching":
//         return Colors.orange;
//       case "Accepted":
//         return Colors.blue;
//       case "In Transit":
//         return kPrimaryColor;
//       case "Delivered":
//         return Colors.purple;
//       default:
//         return Colors.grey;
//     }
//   }
//
//   Widget _buildCollapsibleBottomSheet() {
//     return GestureDetector(
//       onVerticalDragUpdate: (details) {
//         setState(() {
//           _bottomSheetHeight -= details.delta.dy;
//           _bottomSheetHeight = _bottomSheetHeight.clamp(_collapsedHeight, _expandedHeight);
//         });
//       },
//       onVerticalDragEnd: (details) {
//         setState(() {
//           if (_bottomSheetHeight > (_collapsedHeight + _expandedHeight) / 2) {
//             _bottomSheetHeight = _expandedHeight;
//             _isBottomSheetExpanded = true;
//           } else {
//             _bottomSheetHeight = _collapsedHeight;
//             _isBottomSheetExpanded = false;
//           }
//         });
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         height: _bottomSheetHeight,
//         decoration: BoxDecoration(
//           color: kDarkBg,
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.5),
//               blurRadius: 20,
//               offset: const Offset(0, -4),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             // Drag handle
//             Container(
//               margin: const EdgeInsets.only(top: 12),
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade700,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             const SizedBox(height: 12),
//
//             // Content
//             Expanded(
//               child: _isBottomSheetExpanded
//                   ? _buildExpandedContent()
//                   : _buildCollapsedContent(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
// // Update the _buildCollapsedContent method to show driver info and chat
//
// // Update the _buildCollapsedContent method to properly check for accepted driver
//
//   Widget _buildCollapsedContent() {
//     final distance = _driverLocation != null && _pickup != null && !_hasDriverReachedPickup
//         ? _formatDistance(_calculateDistance(
//         _driverLocation!.latitude, _driverLocation!.longitude,
//         _pickup!.latitude, _pickup!.longitude))
//         : null;
//
//     // Get the accepted driver from interests
//     final driver = _getAcceptedDriver();
//     final bool hasAcceptedDriver = driver != null && driver.isNotEmpty;
//
//     debugPrint("Ride status: ${orderData?["status"]}, isActive: $_isActiveRide, hasDriver: $hasAcceptedDriver");
//     if (hasAcceptedDriver) {
//       debugPrint("Driver name: ${driver?["name"]}");
//     }
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Row(
//         children: [
//           // Driver/Status Avatar
//           if (hasAcceptedDriver)
//           // Driver avatar when ride is active and driver assigned
//             Stack(
//               children: [
//                 Container(
//                   width: 52,
//                   height: 52,
//                   decoration: BoxDecoration(
//                     color: kPrimaryColor.withOpacity(0.2),
//                     shape: BoxShape.circle,
//                     border: Border.all(color: kPrimaryColor, width: 2),
//                   ),
//                   child: driver!["image"] != null && driver["image"].toString().isNotEmpty
//                       ? ClipOval(
//                     child: Image.network(
//                       "${App_Constructor().BaseURL}/assets/profile_image/${driver["image"]}",
//                       fit: BoxFit.cover,
//                       errorBuilder: (_, __, ___) => Icon(
//                         Icons.person,
//                         size: 28,
//                         color: kPrimaryColor,
//                       ),
//                     ),
//                   )
//                       : Icon(Icons.person, size: 28, color: kPrimaryColor),
//                 ),
//                 // Online indicator (if driver is online)
//                 if (driver["is_online"] == 1)
//                   Positioned(
//                     bottom: 2,
//                     right: 2,
//                     child: Container(
//                       width: 12,
//                       height: 12,
//                       decoration: BoxDecoration(
//                         color: kPrimaryColor,
//                         shape: BoxShape.circle,
//                         border: Border.all(color: kDarkBg, width: 2),
//                       ),
//                     ),
//                   ),
//               ],
//             )
//           else
//           // Status icon when no driver assigned
//             Container(
//               width: 52,
//               height: 52,
//               decoration: BoxDecoration(
//                 color: _getStatusColor().withOpacity(0.2),
//                 shape: BoxShape.circle,
//                 border: Border.all(color: _getStatusColor().withOpacity(0.5)),
//               ),
//               child: Icon(
//                 _isPending ? Icons.search :
//                 _isCompleted ? Icons.check_circle :
//                 Icons.local_shipping,
//                 color: _getStatusColor(),
//                 size: 26,
//               ),
//             ),
//
//           const SizedBox(width: 12),
//
//           // Main info - Driver details or Order status
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 if (hasAcceptedDriver) ...[
//                   // Driver name and rating
//                   Row(
//                     children: [
//                       Text(
//                         driver!["name"] ?? "Driver",
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 15,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(width: 6),
//                       // You can add rating here if available
//                       // For now, showing a default or removing
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   // Vehicle info
//                   if (driver["vehicle"] != null) ...[
//                     Text(
//                       "${driver["vehicle"]["brand"] ?? ""} ${driver["vehicle"]["model"] ?? ""} • ${driver["vehicle"]["number_plate"] ?? ""}",
//                       style: TextStyle(
//                         fontSize: 11,
//                         color: Colors.grey.shade400,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 2),
//                   ],
//                   // Status with distance
//                   Row(
//                     children: [
//                       Container(
//                         width: 6,
//                         height: 6,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: _getStatusColor(),
//                         ),
//                       ),
//                       const SizedBox(width: 4),
//                       Text(
//                         _hasDriverReachedPickup ? "Heading to drop" : "Heading to pickup",
//                         style: TextStyle(
//                           color: _getStatusColor(),
//                           fontSize: 11,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       if (distance != null) ...[
//                         const SizedBox(width: 4),
//                         Text(
//                           "• $distance",
//                           style: TextStyle(
//                             color: Colors.grey.shade400,
//                             fontSize: 11,
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ] else ...[
//                   // Order status when no driver
//                   Row(
//                     children: [
//                       Text(
//                         _isPending ? "Finding drivers..." : displayStatus,
//                         style: TextStyle(
//                           color: _getStatusColor(),
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       if (distance != null && _isActiveRide) ...[
//                         const SizedBox(width: 8),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 6,
//                             vertical: 2,
//                           ),
//                           decoration: BoxDecoration(
//                             color: kCardBg,
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: Text(
//                             distance,
//                             style: TextStyle(
//                               color: kPrimaryColor,
//                               fontSize: 10,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     orderData?["pickup_location"]?.toString().split(',').first ?? "Pickup",
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 13,
//                       fontWeight: FontWeight.w600,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     "→ ${orderData?["drop_location"]?.toString().split(',').first ?? "Drop"}",
//                     style: TextStyle(
//                       fontSize: 11,
//                       color: Colors.grey.shade400,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ],
//             ),
//           ),
//
//           const SizedBox(width: 8),
//
//           // Action buttons
//           Row(
//             children: [
//               // Chat button - ONLY show if there's an accepted driver
//               if (hasAcceptedDriver)
//                 InkWell(
//                   onTap: () => _openChat(driver),
//                   child: Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: kPrimaryColor.withOpacity(0.15),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
//                     ),
//                     child: SvgPicture.asset(
//                       'assets/images/chat.svg',
//                       color: kPrimaryColor,
//                       width: 22,
//                       height: 22,
//                     ),
//                   ),
//                 ),
//
//               if (hasAcceptedDriver)
//                 const SizedBox(width: 8),
//
//               // Expand indicator
//               Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: kCardBg,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.white.withOpacity(0.1)),
//                 ),
//                 child: Icon(
//                   Icons.keyboard_arrow_up,
//                   color: Colors.grey.shade400,
//                   size: 20,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildExpandedContent() {
//     // Get driver outside the widget tree
//     final driver = _getAcceptedDriver();
//
//     return SingleChildScrollView(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Route summary
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: kCardBg,
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(color: Colors.white.withOpacity(0.1)),
//             ),
//             child: Column(
//               children: [
//                 _buildRouteRow(
//                   icon: Icons.circle,
//                   color: kPrimaryColor,
//                   label: "PICKUP",
//                   value: orderData?["pickup_location"]?.toString() ?? "",
//                 ),
//                 const Padding(
//                   padding: EdgeInsets.only(left: 8),
//                   child: Icon(Icons.more_vert, color: Colors.grey, size: 16),
//                 ),
//                 _buildRouteRow(
//                   icon: Icons.location_on,
//                   color: Colors.red,
//                   label: "DROP",
//                   value: orderData?["drop_location"]?.toString() ?? "",
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//
//           // Assigned Driver Info (if ride is active and driver exists)
//           if (_isActiveRide && driver != null) ...[
//             _buildSectionTitle("Your Driver"),
//             const SizedBox(height: 8),
//             _buildDriverInfoCard(driver),
//             const SizedBox(height: 16),
//           ],
//
//           // Live location status (for active rides)
//           if (_isInCity && _isActiveRide && _driverLocation != null) ...[
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.blue.withOpacity(0.15),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.blue.withOpacity(0.3)),
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.blue.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: const Icon(Icons.location_on, color: Colors.blue, size: 20),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           _hasDriverReachedPickup
//                               ? "Driver heading to drop"
//                               : "Driver heading to pickup",
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 14,
//                           ),
//                         ),
//                         if (_driverLocationUpdatedAt != null)
//                           Text(
//                             "Last updated ${_formatTimeAgo(_driverLocationUpdatedAt!)}",
//                             style: TextStyle(
//                               fontSize: 11,
//                               color: Colors.grey.shade400,
//                             ),
//                           ),
//                         if (!_hasDriverReachedPickup && _driverLocation != null && _pickup != null) ...[
//                           const SizedBox(height: 4),
//                           Text(
//                             "Distance to pickup: ${_formatDistance(_calculateDistance(
//                                 _driverLocation!.latitude, _driverLocation!.longitude,
//                                 _pickup!.latitude, _pickup!.longitude))}",
//                             style: TextStyle(
//                               fontSize: 11,
//                               color: kPrimaryColor,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),
//           ],
//
//           // Package details
//           _buildSectionTitle("Package Details"),
//           const SizedBox(height: 8),
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: kCardBg,
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(color: Colors.white.withOpacity(0.1)),
//             ),
//             child: Column(
//               children: [
//                 _buildInfoRow("Description", orderData?["package_description"] ?? "-"),
//                 _buildInfoRow("Size", orderData?["package_size"] ?? "-"),
//                 _buildInfoRow("Type", orderData?["trip_type"] ?? "-"),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//
//           // Payment info
//           _buildSectionTitle("Payment"),
//           const SizedBox(height: 8),
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: kCardBg,
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(color: Colors.white.withOpacity(0.1)),
//             ),
//             child: Column(
//               children: [
//                 _buildInfoRow(
//                   "Amount",
//                   "TJS ${orderData?["suggested_price"] ?? "-"}",
//                   valueColor: kPriceColor,
//                 ),
//                 _buildInfoRow("Method", orderData?["payment_method"] ?? "-"),
//                 _buildInfoRow("Paid By", orderData?["paid_by"] ?? "-"),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),
//
//           // People info
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: _buildPersonCard(
//                   title: "SENDER",
//                   name: orderData?["sender_name"] ?? "-",
//                   phone: orderData?["sender_phone"],
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: _buildPersonCard(
//                   title: "RECEIVER",
//                   name: orderData?["receiver_name"] ?? "-",
//                   phone: orderData?["receiver_phone"],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//
//           // Instructions (if any)
//           if ((orderData?["instruction"] ?? "").toString().isNotEmpty) ...[
//             _buildSectionTitle("Instructions"),
//             const SizedBox(height: 8),
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: kCardBg,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.white.withOpacity(0.1)),
//               ),
//               child: Text(
//                 orderData?["instruction"] ?? "",
//                 style: TextStyle(
//                   color: Colors.white.withOpacity(0.9),
//                   fontStyle: FontStyle.italic,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//           ],
//
//           // Interested drivers (for pending orders)
//           if (_isPending) ...[
//             _buildSectionTitle("Interested Drivers (${interests.length})"),
//             const SizedBox(height: 8),
//             if (isLoadingInterests)
//               const Center(
//                 child: Padding(
//                   padding: EdgeInsets.all(20),
//                   child: CircularProgressIndicator(color: kPrimaryColor),
//                 ),
//               )
//             else if (interests.isEmpty)
//               Container(
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   color: kCardBg,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: Colors.white.withOpacity(0.1)),
//                 ),
//                 child: Center(
//                   child: Column(
//                     children: [
//                       Icon(Icons.people_outline, size: 48, color: Colors.grey.shade600),
//                       const SizedBox(height: 12),
//                       Text(
//                         "No drivers yet",
//                         style: TextStyle(color: Colors.grey.shade400),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         "Drivers interested in your order will appear here",
//                         style: TextStyle(
//                           color: Colors.grey.shade600,
//                           fontSize: 12,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//               )
//             else
//               ...interests.map((interest) => _buildDriverCard(interest)).toList(),
//           ],
//
//           // Completed status
//           if (_isCompleted) ...[
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.green.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: Colors.green.withOpacity(0.3)),
//               ),
//               child: const Column(
//                 children: [
//                   Icon(Icons.check_circle, color: Colors.green, size: 40),
//                   SizedBox(height: 8),
//                   Text(
//                     "Delivery Completed",
//                     style: TextStyle(
//                       color: Colors.green,
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildRouteRow({
//     required IconData icon,
//     required Color color,
//     required String label,
//     required String value,
//   }) {
//     return Row(
//       children: [
//         Container(
//           width: 24,
//           height: 24,
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.2),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(icon, color: color, size: 14),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 11,
//                   color: Colors.grey.shade400,
//                 ),
//               ),
//               Text(
//                 value,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 13,
//                   fontWeight: FontWeight.w500,
//                 ),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildSectionTitle(String title) {
//     return Text(
//       title,
//       style: const TextStyle(
//         color: Colors.white,
//         fontSize: 14,
//         fontWeight: FontWeight.bold,
//       ),
//     );
//   }
//
//   Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey.shade400,
//             ),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//               color: valueColor ?? Colors.white,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPersonCard({
//     required String title,
//     required String name,
//     String? phone,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: kCardBg,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.white.withOpacity(0.1)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 10,
//               color: kPrimaryColor,
//               fontWeight: FontWeight.w600,
//               letterSpacing: 0.5,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             name,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 13,
//               fontWeight: FontWeight.w600,
//             ),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//           if (phone != null) ...[
//             const SizedBox(height: 4),
//             Row(
//               children: [
//                 Icon(Icons.phone, size: 10, color: kPrimaryColor),
//                 const SizedBox(width: 4),
//                 Text(
//                   phone,
//                   style: TextStyle(
//                     fontSize: 11,
//                     color: kPrimaryColor,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
// // Update the _buildDriverInfoCard method
//   Widget _buildDriverInfoCard(Map<String, dynamic> driver) {
//     final vehicle = driver["vehicle"] as Map<String, dynamic>? ?? {};
//     final vehicleInfo =
//     "${vehicle["brand"] ?? ""} ${vehicle["model"] ?? ""}".trim();
//     final numberPlate = vehicle["number_plate"] ?? "";
//
//     // Construct image URL properly
//     String? imageUrl;
//     if (driver["image"] != null && driver["image"].toString().isNotEmpty) {
//       imageUrl = "${App_Constructor().BaseURL}/assets/profile_image/${driver["image"]}";
//     }
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: kCardBg,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: kPrimaryColor.withOpacity(0.3), width: 1.5),
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               // Driver avatar with status
//               Stack(
//                 children: [
//                   Container(
//                     width: 70,
//                     height: 70,
//                     decoration: BoxDecoration(
//                       color: kPrimaryColor.withOpacity(0.1),
//                       shape: BoxShape.circle,
//                       border: Border.all(color: kPrimaryColor, width: 2),
//                     ),
//                     child: imageUrl != null
//                         ? ClipOval(
//                       child: Image.network(
//                         imageUrl,
//                         fit: BoxFit.cover,
//                         errorBuilder: (_, __, ___) => Icon(
//                           Icons.person,
//                           size: 35,
//                           color: kPrimaryColor,
//                         ),
//                       ),
//                     )
//                         : Icon(Icons.person, size: 35, color: kPrimaryColor),
//                   ),
//                   if (driver["is_online"] == 1)
//                     Positioned(
//                       bottom: 2,
//                       right: 2,
//                       child: Container(
//                         width: 16,
//                         height: 16,
//                         decoration: BoxDecoration(
//                           color: kPrimaryColor,
//                           shape: BoxShape.circle,
//                           border: Border.all(color: kDarkBg, width: 2),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//               const SizedBox(width: 16),
//
//               // Driver details
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Text(
//                           driver["name"] ?? "Driver",
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         // You can add rating here if available
//                       ],
//                     ),
//                     const SizedBox(height: 6),
//                     if (vehicleInfo.isNotEmpty)
//                       Text(
//                         vehicleInfo,
//                         style: TextStyle(
//                           fontSize: 13,
//                           color: Colors.grey.shade300,
//                         ),
//                       ),
//                     if (numberPlate.isNotEmpty)
//                       Container(
//                         margin: const EdgeInsets.only(top: 4),
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 2,
//                         ),
//                         decoration: BoxDecoration(
//                           color: kPrimaryColor.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                         child: Text(
//                           numberPlate,
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: kPrimaryColor,
//                             fontWeight: FontWeight.w600,
//                             letterSpacing: 1,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//
//               // Large chat button
//               InkWell(
//                 onTap: () => _openChat(driver),
//                 child: Container(
//                   padding: const EdgeInsets.all(14),
//                   decoration: BoxDecoration(
//                     color: kPrimaryColor,
//                     borderRadius: BorderRadius.circular(14),
//                     boxShadow: [
//                       BoxShadow(
//                         color: kPrimaryColor.withOpacity(0.3),
//                         blurRadius: 8,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: SvgPicture.asset(
//                     'assets/images/chat.svg',
//                     color: Colors.black,
//                     width: 24,
//                     height: 24,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//
//           // Additional driver stats (optional)
//           const SizedBox(height: 16),
//           // Row(
//           //   children: [
//           //     _buildDriverStat(
//           //       icon: Icons.star,
//           //       label: "Rating",
//           //       value: "4.8",
//           //     ),
//           //     _buildDriverStat(
//           //       icon: Icons.assignment_turned_in,
//           //       label: "Deliveries",
//           //       value: "150+",
//           //     ),
//           //     _buildDriverStat(
//           //       icon: Icons.access_time,
//           //       label: "Member",
//           //       value: "2025",
//           //     ),
//           //   ],
//           // ),
//         ],
//       ),
//     );
//   }
// // Add this helper method for driver stats
//   Widget _buildDriverStat({
//     required IconData icon,
//     required String label,
//     required String value,
//   }) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 8),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.05),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Column(
//           children: [
//             Icon(icon, color: kPrimaryColor, size: 16),
//             const SizedBox(height: 4),
//             Text(
//               value,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 13,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             Text(
//               label,
//               style: TextStyle(
//                 color: Colors.grey.shade500,
//                 fontSize: 9,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDriverCard(Map<String, dynamic> interest) {
//     final driver = interest["driver"] as Map<String, dynamic>? ?? {};
//     final vehicle = driver["vehicle"] as Map<String, dynamic>? ?? {};
//     final driverName = driver["name"] ?? "Unknown Driver";
//     final offerPrice = interest["driver_price"]?.toString() ?? "0";
//     final message = interest["message"] ?? "";
//     final vehicleInfo =
//     "${vehicle["brand"] ?? ""} ${vehicle["model"] ?? ""}".trim();
//     final numberPlate = vehicle["number_plate"] ?? "";
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: kCardBg,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.white.withOpacity(0.1)),
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               // Driver avatar
//               Container(
//                 width: 50,
//                 height: 50,
//                 decoration: BoxDecoration(
//                   color: kPrimaryColor.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: driver["profile_image"] != null
//                     ? ClipOval(
//                   child: Image.network(
//                     driver["profile_image"],
//                     fit: BoxFit.cover,
//                     errorBuilder: (_, __, ___) => const Icon(
//                         Icons.person,
//                         size: 24,
//                         color: kPrimaryColor),
//                   ),
//                 )
//                     : const Icon(Icons.person, size: 24, color: kPrimaryColor),
//               ),
//               const SizedBox(width: 12),
//
//               // Driver info
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       driverName,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     if (vehicleInfo.isNotEmpty) ...[
//                       const SizedBox(height: 2),
//                       Text(
//                         vehicleInfo,
//                         style: TextStyle(
//                           fontSize: 11,
//                           color: Colors.grey.shade400,
//                         ),
//                       ),
//                     ],
//                     if (numberPlate.isNotEmpty) ...[
//                       const SizedBox(height: 2),
//                       Text(
//                         numberPlate,
//                         style: TextStyle(
//                           fontSize: 10,
//                           color: kPrimaryColor,
//                         ),
//                       ),
//                     ],
//                     if (message.isNotEmpty) ...[
//                       const SizedBox(height: 4),
//                       Text(
//                         '"$message"',
//                         style: TextStyle(
//                           fontSize: 11,
//                           color: Colors.grey.shade500,
//                           fontStyle: FontStyle.italic,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//
//               // Price and actions
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Text(
//                     "TJS $offerPrice",
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: kPriceColor,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Chat button
//                       InkWell(
//                         onTap: () => _openChat(driver),
//                         child: Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             color: kPrimaryColor.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: SvgPicture.asset(
//                             'assets/images/chat.svg',
//                             color: kPrimaryColor,
//                             width: 18,
//                             height: 18,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       // Accept button (for pending orders)
//                       if (_isPending)
//                         InkWell(
//                           onTap: () => _confirmAcceptDriver(interest),
//                           child: Container(
//                             padding: const EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: kPrimaryColor,
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: const Icon(
//                               Icons.check,
//                               color: Colors.black,
//                               size: 16,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // Custom widgets with dark theme
// class _LocationPin extends StatelessWidget {
//   final Color color;
//   final String label;
//   final bool isPickup;
//   const _LocationPin({
//     required this.color,
//     required this.label,
//     this.isPickup = true,
//   });
//
//   @override
//   Widget build(BuildContext context) => Column(
//     mainAxisSize: MainAxisSize.min,
//     children: [
//       Container(
//         width: 34,
//         height: 34,
//         decoration: BoxDecoration(
//           color: color,
//           shape: BoxShape.circle,
//           border: Border.all(color: Colors.white, width: 2.5),
//           boxShadow: [
//             BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)
//           ],
//         ),
//         child: Center(
//           child: Text(
//             label,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 13,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ),
//       // Pin tail
//       Container(
//         width: 10,
//         height: 7,
//         decoration: BoxDecoration(
//           color: color,
//           borderRadius: const BorderRadius.only(
//             bottomLeft: Radius.circular(2),
//             bottomRight: Radius.circular(2),
//           ),
//         ),
//       ),
//     ],
//   );
// }
//
// class _CircleButton extends StatelessWidget {
//   final IconData icon;
//   final VoidCallback onTap;
//   final Color? color;
//   final bool dark;
//   const _CircleButton({
//     required this.icon,
//     required this.onTap,
//     this.color,
//     this.dark = false,
//   });
//
//   @override
//   Widget build(BuildContext context) => GestureDetector(
//     onTap: onTap,
//     child: Container(
//       width: 40,
//       height: 40,
//       decoration: BoxDecoration(
//         color: dark ? kCardBg : Colors.white,
//         shape: BoxShape.circle,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.3),
//             blurRadius: 8,
//           ),
//         ],
//       ),
//       child: Icon(
//         icon,
//         color: color ?? (dark ? Colors.white : Colors.black87),
//         size: 20,
//       ),
//     ),
//   );
// }
//
// class _MapBtn extends StatelessWidget {
//   final IconData icon;
//   final VoidCallback onTap;
//   const _MapBtn({required this.icon, required this.onTap});
//
//   @override
//   Widget build(BuildContext context) => GestureDetector(
//     onTap: onTap,
//     child: Container(
//       width: 40,
//       height: 40,
//       decoration: BoxDecoration(
//         color: kCardBg,
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.3),
//             blurRadius: 6,
//           ),
//         ],
//       ),
//       child: Icon(icon, color: Colors.white, size: 20),
//     ),
//   );
// }


import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../api_service/app_constocter.dart';
import '../../api_service/logger.dart';
import '../../providers/translate_provider.dart';
import '../../service/local_cache.dart';
import '../auth/SignInScreen.dart';
import '../mainView/provide/ChatProvider.dart';

// Dark theme colors matching driver UI
const Color kPrimaryColor = Color(0xFF6FD94A); // Green from driver UI
const Color kDarkBg = Color(0xFF1C1C1E);
const Color kCardBg = Color(0xFF2A2A2C);
const Color kPriceColor = Color(0xFFFF6B3D);
const Color kSubText = Color(0xFF8E8E93);

class CourierDetailScreen extends StatefulWidget {
  final String orderId;

  const CourierDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<CourierDetailScreen> createState() => _CourierDetailScreenState();
}

class _CourierDetailScreenState extends State<CourierDetailScreen>
    with TickerProviderStateMixin {
  late MapController _mapController;

  // Bottom sheet state
  bool _isBottomSheetExpanded = false;
  double _bottomSheetHeight = 180; // Collapsed height
  final double _collapsedHeight = 180;
  final double _expandedHeight = 550;

  // Data
  Map<String, dynamic>? orderData;
  List<dynamic> interests = [];
  bool isLoading = true;
  bool isLoadingInterests = false;
  bool isAcceptingDriver = false;
  bool isRefreshing = false; // New state for refresh indicator
  String? errorMessage;
  String? selectedDriverId;

  // Live location tracking
  LatLng? _driverLocation;
  DateTime? _driverLocationUpdatedAt;
  Timer? _liveLocationTimer;
  bool _isFetchingLiveLocation = false;

  // Route data
  List<LatLng> _routePickupToDrop = [];
  List<LatLng> _routeDriverToPickup = [];
  bool _isFetchingRoute = false;
  bool _hasDriverReachedPickup = false;
  double? _heading;

  // Parsed coordinates
  LatLng? _pickup;
  LatLng? _drop;

  String get orderId => widget.orderId;

  bool get _isInCity {
    final type = (orderData?["trip_type"] ?? "").toString().toLowerCase().trim();
    return type == "incity" ||
        type == "in_city" ||
        type == "in city" ||
        type == "local";
  }

  bool get _isActiveRide {
    final status = (orderData?["status"] ?? "").toString().toLowerCase();
    return status == "accepted" ||
        status == "in_transit" ||
        status == "in transit";
  }

  bool get _isPending {
    final status = (orderData?["status"] ?? "").toString().toLowerCase();
    return status == "pending" || status == "searching";
  }

  bool get _isCompleted {
    final status = (orderData?["status"] ?? "").toString().toLowerCase();
    return status == "completed";
  }

  String _status(String raw) {
    switch (raw) {
      case "pending":
        return "Searching";
      case "accepted":
        return "Accepted";
      case "in_transit":
        return "In Transit";
      case "completed":
        return "Delivered";
      default:
        return raw;
    }
  }

  String get displayStatus => _status(orderData?["status"] ?? "");

  // Add this method to get the accepted driver from interests
  Map<String, dynamic>? _getAcceptedDriver() {
    if (orderData == null) return null;

    final acceptedDriverId = orderData?["accepted_driver_id"];
    if (acceptedDriverId == null) return null;

    // Find the driver in interests that matches the accepted_driver_id
    try {
      final acceptedInterest = interests.firstWhere(
            (interest) => interest["driver_id"] == acceptedDriverId,
        orElse: () => null,
      );

      if (acceptedInterest != null) {
        return acceptedInterest["driver"] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint("Error finding accepted driver: $e");
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchOrderDetails();
    _fetchInterests();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _liveLocationTimer?.cancel();
    super.dispose();
  }

  // New method to refresh all data
  Future<void> _refreshData() async {
    if (isRefreshing) return;

    setState(() {
      isRefreshing = true;
    });

    try {
      // Clear existing route data
      setState(() {
        _routePickupToDrop = [];
        _routeDriverToPickup = [];
        _driverLocation = null;
        _hasDriverReachedPickup = false;
      });

      // Fetch fresh data
      await Future.wait([
        _fetchOrderDetails(),
        _fetchInterests(),
      ]);

      // Show success toast
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Data refreshed successfully",
          backgroundColor: kPrimaryColor,
          textColor: Colors.black,
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    } catch (e) {
      debugPrint("Refresh error: $e");
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Failed to refresh data",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isRefreshing = false;
        });
      }
    }
  }

  String _calculateEstimatedTime(double distanceInMeters) {
    // Assume average speed of 30 km/h in city
    final speedKmPerHour = 30.0;
    final distanceKm = distanceInMeters / 1000;
    final timeHours = distanceKm / speedKmPerHour;
    final timeMinutes = (timeHours * 60).round();

    if (timeMinutes < 1) return "Less than a minute";
    if (timeMinutes < 60) return "$timeMinutes min";

    final hours = (timeMinutes / 60).floor();
    final minutes = timeMinutes % 60;
    return "$hours hr ${minutes}min";
  }


  // Parse coordinates from order
  void _parseCoords() {
    if (orderData == null) return;

    final pickLat = double.tryParse(
        orderData?["pickup_latitude"]?.toString() ?? "");
    final pickLng = double.tryParse(
        orderData?["pickup_longitude"]?.toString() ?? "");
    final dropLat = double.tryParse(
        orderData?["drop_latitude"]?.toString() ?? "");
    final dropLng = double.tryParse(
        orderData?["drop_longitude"]?.toString() ?? "");

    // Always set drop if available
    if (dropLat != null && dropLng != null) {
      _drop = LatLng(dropLat, dropLng);
    }

    // Only set pickup if coordinates are available
    if (pickLat != null && pickLng != null) {
      _pickup = LatLng(pickLat, pickLng);
    } else {
      // If pickup coordinates are missing, try to geocode the address
      _geocodePickupAddress();
    }

    // Only fetch route if both points are available
    if (_pickup != null && _drop != null) {
      _fetchOsrmRoute();
    }
  }

// Geocode pickup address to get coordinates
  Future<void> _geocodePickupAddress() async {
    final pickupAddress = orderData?["pickup_location"]?.toString();
    if (pickupAddress == null || pickupAddress.isEmpty) return;

    try {
      // Using OpenStreetMap Nominatim API for geocoding (free, no API key required)
      final encodedAddress = Uri.encodeComponent(pickupAddress);
      final url = "https://nominatim.openstreetmap.org/search?q=$encodedAddress&format=json&limit=1";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'QadamPaykApp/1.0', // Required by Nominatim
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]["lat"]?.toString() ?? "");
          final lng = double.tryParse(data[0]["lon"]?.toString() ?? "");

          if (lat != null && lng != null && mounted) {
            setState(() {
              _pickup = LatLng(lat, lng);
            });

            // Now fetch the route
            if (_drop != null) {
              _fetchOsrmRoute();
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }
  }

  LatLng get _mapCenter {
    // If we have both pickup and drop, center on their midpoint
    if (_pickup != null && _drop != null) {
      // Calculate bounds to show entire route
      final minLat = math.min(_pickup!.latitude, _drop!.latitude);
      final maxLat = math.max(_pickup!.latitude, _drop!.latitude);
      final minLng = math.min(_pickup!.longitude, _drop!.longitude);
      final maxLng = math.max(_pickup!.longitude, _drop!.longitude);

      return LatLng(
        (minLat + maxLat) / 2,
        (minLng + maxLng) / 2,
      );
    }

    // Fallback to driver location if available
    if (_driverLocation != null && !_hasDriverReachedPickup && _isActiveRide) {
      return _driverLocation!;
    }

    return _pickup ?? _drop ?? const LatLng(28.6139, 77.2090);
  }


  // Fetch OSRM route
  Future<void> _fetchOsrmRoute({LatLng? start, LatLng? end}) async {
    final startPoint = start ?? _pickup;
    final endPoint = end ?? _drop;

    if (startPoint == null || endPoint == null) return;

    setState(() => _isFetchingRoute = true);

    try {
      final url =
          "http://router.project-osrm.org/route/v1/driving/"
          "${startPoint.longitude},${startPoint.latitude};"
          "${endPoint.longitude},${endPoint.latitude}"
          "?overview=full&geometries=geojson";

      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final coords = (data["routes"][0]["geometry"]["coordinates"] as List)
            .map<LatLng>((c) => LatLng(c[1] as double, c[0] as double))
            .toList();

        if (mounted) {
          setState(() {
            // Determine which route this is based on the points
            if (startPoint == _driverLocation && endPoint == _pickup) {
              _routeDriverToPickup = coords;
            } else if (startPoint == _pickup && endPoint == _drop) {
              _routePickupToDrop = coords;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("OSRM route error: $e");
    } finally {
      if (mounted) setState(() => _isFetchingRoute = false);
    }
  }

// Update the _fetchRouteDriverToPickup method
  Future<void> _fetchRouteDriverToPickup() async {
    if (_driverLocation == null || _pickup == null) return;
    if (_hasDriverReachedPickup) return;

    await _fetchOsrmRoute(start: _driverLocation!, end: _pickup!);
  }

  // Start live location polling
  void _startLiveLocationPolling() {
    _liveLocationTimer?.cancel();
    _fetchDriverLiveLocation();
    _liveLocationTimer = Timer.periodic(
      const Duration(seconds: 10),
          (_) => _fetchDriverLiveLocation(),
    );
  }

  void _stopLiveLocationPolling() {
    _liveLocationTimer?.cancel();
    _liveLocationTimer = null;
  }

  // Fetch driver live location
  Future<void> _fetchDriverLiveLocation() async {
    if (_isFetchingLiveLocation || orderId.isEmpty) return;
    setState(() => _isFetchingLiveLocation = true);

    try {
      final token = await LocalCache.getToken();
      final response = await http.get(
        Uri.parse(
            "${App_Constructor().BaseURL}/api/courier/live-location/$orderId"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["status"] == true && data["data"] != null) {
          final loc = data["data"] as Map<String, dynamic>;
          final driverLat =
          double.tryParse(loc["driver_latitude"]?.toString() ?? "");
          final driverLng =
          double.tryParse(loc["driver_longitude"]?.toString() ?? "");
          final updatedAt = loc["last_updated"]?.toString();

          if (driverLat != null && driverLng != null && mounted) {
            final newLocation = LatLng(driverLat, driverLng);

            // Check if driver has reached pickup
            if (_pickup != null) {
              final distanceToPickup = _calculateDistance(
                  driverLat, driverLng,
                  _pickup!.latitude, _pickup!.longitude);

              if (distanceToPickup < 50 && !_hasDriverReachedPickup) {
                setState(() {
                  _hasDriverReachedPickup = true;
                  _routeDriverToPickup = [];
                });
              }
            }

            setState(() {
              _driverLocation = newLocation;
              if (updatedAt != null) {
                _driverLocationUpdatedAt = DateTime.tryParse(updatedAt);
              }
            });

            if (!_hasDriverReachedPickup) {
              _fetchRouteDriverToPickup();
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Live location fetch error: $e");
    } finally {
      if (mounted) setState(() => _isFetchingLiveLocation = false);
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371e3;
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final deltaPhi = (lat2 - lat1) * math.pi / 180;
    final deltaLambda = (lon2 - lon1) * math.pi / 180;

    final a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
        math.cos(phi1) * math.cos(phi2) *
            math.sin(deltaLambda / 2) * math.sin(deltaLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return "${diff.inSeconds}s ago";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    return "${diff.inHours}h ago";
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return "${meters.round()} m";
    }
    return "${(meters / 1000).toStringAsFixed(1)} km";
  }

  // Fetch order details
  Future<void> _fetchOrderDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await LocalCache.getToken();
      final response = await http.get(
        Uri.parse("${App_Constructor().BaseURL}/api/sender/couriers/$orderId"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      final data = jsonDecode(response.body);
      debugPrint("Order details response: ${response.body}");

      if (response.statusCode == 200 && data["status"] == true) {
        setState(() {
          orderData = data["data"];
        });

        _parseCoords();

        // Start polling only for in-city active rides
        if (_isInCity && _isActiveRide) {
          _startLiveLocationPolling();
        } else {
          _stopLiveLocationPolling();
        }
      } else {
        setState(() {
          errorMessage = data["message"] ?? "Failed to load order details";
        });
      }
    } catch (e) {
      setState(() => errorMessage = "Network error: $e");
      debugPrint("Fetch order details error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Fetch interested drivers
  Future<void> _fetchInterests() async {
    setState(() => isLoadingInterests = true);
    try {
      final token = await LocalCache.getToken();
      final response = await http.get(
        Uri.parse(
            "${App_Constructor().BaseURL}/api/courier/request/$orderId/interests"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["status"] == true) {
        setState(() => interests = data["data"] ?? []);
      }
    } catch (e) {
      debugPrint("Fetch interests error: $e");
    } finally {
      setState(() => isLoadingInterests = false);
    }
  }

  // Accept driver
  Future<void> _acceptDriver(Map<String, dynamic> interest) async {
    setState(() => isAcceptingDriver = true);

    try {
      final token = await LocalCache.getToken();
      final response = await http.post(
        Uri.parse(
            "${App_Constructor().BaseURL}/api/courier/request/$orderId/accept-driver"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "driver_id": interest["driver_id"].toString(),
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["status"] == true) {
        await _fetchOrderDetails();
        await _fetchInterests();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Driver accepted • ${interest["driver"]?["name"] ?? ""}"),
              backgroundColor: kPrimaryColor,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data["message"] ?? "Failed to accept driver"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Accept driver error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Network error occurred"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isAcceptingDriver = false);
    }
  }

  void _confirmAcceptDriver(Map<String, dynamic> interest) {
    final driver = interest["driver"] as Map<String, dynamic>? ?? {};
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Confirm Driver", style: TextStyle(color: Colors.white)),
        content: Text(
          "Accept ${driver["name"] ?? "this driver"} for TJS ${interest["driver_price"]}?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptDriver(interest);
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
            child: const Text("Accept",
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // Open chat with driver
  Future<void> _openChat(dynamic driver) async {
    if (driver == null) return;

    final token = await LocalCache.getToken();
    if (token == null || token.isEmpty) {
      Fluttertoast.showToast(
        msg: context.read<TranslateProvider>().t('txt_login_first'),
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PhoneNumberScreen(),
        ),
      );
      return;
    }

    final chatProvider = Provider.of<ChatProvider>(
      context,
      listen: false,
    );

    await chatProvider.startChat(
      context: context,
      otherUserId: driver["id"],
      userName: driver["name"] ?? 'Driver',
    );
  }



  // Build markers for map
  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    if (_pickup != null) {
      markers.add(Marker(
        point: _pickup!,
        width: 44, height: 56,
        alignment: Alignment.bottomCenter,
        child: _LocationPin(
          color: kPrimaryColor,
          label: "P",
          isPickup: true,
        ),
      ));
    }

    if (_drop != null) {
      markers.add(Marker(
        point: _drop!,
        width: 44, height: 56,
        alignment: Alignment.bottomCenter,
        child: _LocationPin(color: Colors.red, label: "D", isPickup: false),
      ));
    }

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
                color: Colors.blue.withOpacity(0.18),
                border: Border.all(color: Colors.blue.withOpacity(0.5), width: 2),
              ),
            ),
            Container(
              width: 34, height: 34,
              decoration: const BoxDecoration(
                  color: Colors.blue, shape: BoxShape.circle),
              child: const Icon(Icons.local_shipping,
                  color: Colors.white, size: 18),
            ),
          ],
        ),
      ));
    }

    if (markers.isEmpty) {
      markers.add(Marker(
        point: _mapCenter,
        width: 40, height: 40,
        child: const Icon(Icons.location_pin, color: kPrimaryColor, size: 36),
      ));
    }

    return markers;
  }

  // Build polylines for map
  List<Polyline> _buildPolylines() {
    final polylines = <Polyline>[];

    // Route from driver to pickup (shown when driver is en route)
    if (_isInCity && _isActiveRide &&
        _driverLocation != null && _pickup != null &&
        !_hasDriverReachedPickup) {

      if (_routeDriverToPickup.isNotEmpty) {
        polylines.add(
          Polyline(
            points: _routeDriverToPickup,
            strokeWidth: 5,
            color: Colors.blue.withOpacity(0.8),
            borderColor: Colors.white,
            borderStrokeWidth: 1.5,
          ),
        );
      } else {
        // Fallback to straight line if route not available
        polylines.add(
          Polyline(
            points: [_driverLocation!, _pickup!],
            strokeWidth: 3,
            color: Colors.blue.withOpacity(0.5),
            borderColor: Colors.white30,
            borderStrokeWidth: 1,
          ),
        );
      }
    }

    // Route from pickup to drop (always show if both points exist)
    if (_pickup != null && _drop != null) {
      if (_routePickupToDrop.isNotEmpty) {
        polylines.add(
          Polyline(
            points: _routePickupToDrop,
            strokeWidth: 5,
            color: _hasDriverReachedPickup ? kPrimaryColor : kPrimaryColor.withOpacity(0.6),
            borderColor: Colors.white,
            borderStrokeWidth: 1.5,
          ),
        );
      } else {
        // Fallback to straight line
        polylines.add(
          Polyline(
            points: [_pickup!, _drop!],
            strokeWidth: 4,
            color: kPrimaryColor.withOpacity(0.5),
            borderColor: Colors.white30,
            borderStrokeWidth: 1,
          ),
        );
      }
    }

    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: kDarkBg,
        body: const Center(
          child: CircularProgressIndicator(
            color: kPrimaryColor,
          ),
        ),
      );
    }

    if (errorMessage != null || orderData == null) {
      return Scaffold(
        backgroundColor: kDarkBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey.shade600),
                const SizedBox(height: 16),
                Text(
                  errorMessage ?? "Failed to load order",
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _fetchOrderDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final markers = _buildMarkers();
    final polylines = _buildPolylines();

    return Scaffold(
      backgroundColor: kDarkBg,
      body: Stack(
        children: [
          // Full screen map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}",
                subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
                userAgentPackageName: "com.qadampayk.app",
              ),
              if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
              MarkerLayer(markers: markers),
            ],
          ),

          // Top gradient
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Top bar with back button, refresh button, status and order ID
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 12,
            right: 12,
            child: Row(
              children: [
                // Back button
                _CircleButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                  dark: true,
                ),
                const SizedBox(width: 8),

                // Refresh button (NEW)
                _CircleButton(
                  icon: Icons.refresh,
                  onTap: _refreshData,
                  dark: true,
                  isLoading: isRefreshing, // New parameter to show loading state
                ),
                const SizedBox(width: 12),

                // Status badge
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: kCardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getStatusColor(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          displayStatus,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Order ID
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "#$orderId",
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Live location badge (for active rides)
          if (_isInCity && _isActiveRide)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _driverLocation != null
                            ? kPrimaryColor
                            : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _driverLocation != null
                          ? _hasDriverReachedPickup
                          ? "Driver at pickup"
                          : "Driver en route"
                          : "Locating driver...",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                    if (_driverLocation != null && _driverLocationUpdatedAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _formatTimeAgo(_driverLocationUpdatedAt!),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _fetchDriverLiveLocation,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.refresh,
                          color: Colors.white.withOpacity(0.7),
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Map controls
          Positioned(
            bottom: _bottomSheetHeight + 20,
            right: 12,
            child: Column(
              children: [
                if (_isInCity && _isActiveRide && _driverLocation != null)
                  _CircleButton(
                    icon: Icons.local_shipping,
                    color: Colors.blue,
                    onTap: () => _mapController.move(_driverLocation!, 16),
                  ),
                if (_isInCity && _isActiveRide && _driverLocation != null)
                  const SizedBox(height: 8),
                _CircleButton(
                  icon: Icons.location_on,
                  color: kPrimaryColor,
                  onTap: () => _pickup != null
                      ? _mapController.move(_pickup!, 16)
                      : null,
                ),
                const SizedBox(height: 8),
                _CircleButton(
                  icon: Icons.flag,
                  color: Colors.red,
                  onTap: () => _drop != null
                      ? _mapController.move(_drop!, 16)
                      : null,
                ),
                const SizedBox(height: 8),
                _MapBtn(icon: Icons.add, onTap: () {
                  _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1);
                }),
                const SizedBox(height: 4),
                _MapBtn(icon: Icons.remove, onTap: () {
                  _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1);
                }),
              ],
            ),
          ),

          // Collapsible Bottom Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildCollapsibleBottomSheet(),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (displayStatus) {
      case "Searching":
        return Colors.orange;
      case "Accepted":
        return Colors.blue;
      case "In Transit":
        return kPrimaryColor;
      case "Delivered":
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCollapsibleBottomSheet() {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _bottomSheetHeight -= details.delta.dy;
          _bottomSheetHeight = _bottomSheetHeight.clamp(_collapsedHeight, _expandedHeight);
        });
      },
      onVerticalDragEnd: (details) {
        setState(() {
          if (_bottomSheetHeight > (_collapsedHeight + _expandedHeight) / 2) {
            _bottomSheetHeight = _expandedHeight;
            _isBottomSheetExpanded = true;
          } else {
            _bottomSheetHeight = _collapsedHeight;
            _isBottomSheetExpanded = false;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _bottomSheetHeight,
        decoration: BoxDecoration(
          color: kDarkBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Content
            Expanded(
              child: _isBottomSheetExpanded
                  ? _buildExpandedContent()
                  : _buildCollapsedContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedContent() {
    final distance = _driverLocation != null && _pickup != null && !_hasDriverReachedPickup
        ? _formatDistance(_calculateDistance(
        _driverLocation!.latitude, _driverLocation!.longitude,
        _pickup!.latitude, _pickup!.longitude))
        : null;

    // Get the accepted driver from interests
    final driver = _getAcceptedDriver();
    final bool hasAcceptedDriver = driver != null && driver.isNotEmpty;

    debugPrint("Ride status: ${orderData?["status"]}, isActive: $_isActiveRide, hasDriver: $hasAcceptedDriver");
    if (hasAcceptedDriver) {
      debugPrint("Driver name: ${driver?["name"]}");
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Driver/Status Avatar
          if (hasAcceptedDriver)
          // Driver avatar when ride is active and driver assigned
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: kPrimaryColor, width: 2),
                  ),
                  child: driver!["image"] != null && driver["image"].toString().isNotEmpty
                      ? ClipOval(
                    child: Image.network(
                      "${App_Constructor().BaseURL}/assets/profile_image/${driver["image"]}",
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        size: 28,
                        color: kPrimaryColor,
                      ),
                    ),
                  )
                      : Icon(Icons.person, size: 28, color: kPrimaryColor),
                ),
                // Online indicator (if driver is online)
                if (driver["is_online"] == 1)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: kDarkBg, width: 2),
                      ),
                    ),
                  ),
              ],
            )
          else
          // Status icon when no driver assigned
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: _getStatusColor().withOpacity(0.5)),
              ),
              child: Icon(
                _isPending ? Icons.search :
                _isCompleted ? Icons.check_circle :
                Icons.local_shipping,
                color: _getStatusColor(),
                size: 26,
              ),
            ),

          const SizedBox(width: 12),

          // Main info - Driver details or Order status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasAcceptedDriver) ...[
                  // Driver name and rating
                  Row(
                    children: [
                      Text(
                        driver!["name"] ?? "Driver",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Vehicle info
                  if (driver["vehicle"] != null) ...[
                    Text(
                      "${driver["vehicle"]["brand"] ?? ""} ${driver["vehicle"]["model"] ?? ""} • ${driver["vehicle"]["number_plate"] ?? ""}",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],
                  // Status with distance
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getStatusColor(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _hasDriverReachedPickup ? "Heading to drop" : "Heading to pickup",
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (distance != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          "• $distance",
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ] else ...[
                  // Order status when no driver
                  Row(
                    children: [
                      Text(
                        _isPending ? "Finding drivers..." : displayStatus,
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (distance != null && _isActiveRide) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kCardBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            distance,
                            style: TextStyle(
                              color: kPrimaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    orderData?["pickup_location"]?.toString().split(',').first ?? "Pickup",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "→ ${orderData?["drop_location"]?.toString().split(',').first ?? "Drop"}",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Action buttons
          Row(
            children: [
              // Chat button - ONLY show if there's an accepted driver
              if (hasAcceptedDriver)
                InkWell(
                  onTap: () => _openChat(driver),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
                    ),
                    child: SvgPicture.asset(
                      'assets/images/chat.svg',
                      color: kPrimaryColor,
                      width: 22,
                      height: 22,
                    ),
                  ),
                ),

              if (hasAcceptedDriver)
                const SizedBox(width: 8),

              // Expand indicator
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    // Get driver outside the widget tree
    final driver = _getAcceptedDriver();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                _buildRouteRow(
                  icon: Icons.circle,
                  color: kPrimaryColor,
                  label: "PICKUP",
                  value: orderData?["pickup_location"]?.toString() ?? "",
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.more_vert, color: Colors.grey, size: 16),
                ),
                _buildRouteRow(
                  icon: Icons.location_on,
                  color: Colors.red,
                  label: "DROP",
                  value: orderData?["drop_location"]?.toString() ?? "",
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Assigned Driver Info (if ride is active and driver exists)
          if (_isActiveRide && driver != null) ...[
            _buildSectionTitle("Your Driver"),
            const SizedBox(height: 8),
            _buildDriverInfoCard(driver),
            const SizedBox(height: 16),
          ],

          // Live location status (for active rides)
          if (_isInCity && _isActiveRide && _driverLocation != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on, color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasDriverReachedPickup
                              ? "Driver heading to drop"
                              : "Driver heading to pickup",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (_driverLocationUpdatedAt != null)
                          Text(
                            "Last updated ${_formatTimeAgo(_driverLocationUpdatedAt!)}",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        if (!_hasDriverReachedPickup && _driverLocation != null && _pickup != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            "Distance to pickup: ${_formatDistance(_calculateDistance(
                                _driverLocation!.latitude, _driverLocation!.longitude,
                                _pickup!.latitude, _pickup!.longitude))}",
                            style: TextStyle(
                              fontSize: 11,
                              color: kPrimaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Package details
          _buildSectionTitle("Package Details"),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                _buildInfoRow("Description", orderData?["package_description"] ?? "-"),
                _buildInfoRow("Size", orderData?["package_size"] ?? "-"),
                _buildInfoRow("Type", orderData?["trip_type"] ?? "-"),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment info
          _buildSectionTitle("Payment"),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  "Amount",
                  "TJS ${orderData?["suggested_price"] ?? "-"}",
                  valueColor: kPriceColor,
                ),
                _buildInfoRow("Method", orderData?["payment_method"] ?? "-"),
                _buildInfoRow("Paid By", orderData?["paid_by"] ?? "-"),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // People info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildPersonCard(
                  title: "SENDER",
                  name: orderData?["sender_name"] ?? "-",
                  phone: orderData?["sender_phone"],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPersonCard(
                  title: "RECEIVER",
                  name: orderData?["receiver_name"] ?? "-",
                  phone: orderData?["receiver_phone"],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Instructions (if any)
          if ((orderData?["instruction"] ?? "").toString().isNotEmpty) ...[
            _buildSectionTitle("Instructions"),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                orderData?["instruction"] ?? "",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Interested drivers (for pending orders)
          if (_isPending) ...[
            _buildSectionTitle("Interested Drivers (${interests.length})"),
            const SizedBox(height: 8),
            if (isLoadingInterests)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: kPrimaryColor),
                ),
              )
            else if (interests.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 48, color: Colors.grey.shade600),
                      const SizedBox(height: 12),
                      Text(
                        "No drivers yet",
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Drivers interested in your order will appear here",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...interests.map((interest) => _buildDriverCard(interest)).toList(),
          ],

          // Completed status
          if (_isCompleted) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 40),
                  SizedBox(height: 8),
                  Text(
                    "Delivery Completed",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRouteRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade400,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonCard({
    required String title,
    required String name,
    String? phone,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: kPrimaryColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (phone != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone, size: 10, color: kPrimaryColor),
                const SizedBox(width: 4),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 11,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDriverInfoCard(Map<String, dynamic> driver) {
    final vehicle = driver["vehicle"] as Map<String, dynamic>? ?? {};
    final vehicleInfo =
    "${vehicle["brand"] ?? ""} ${vehicle["model"] ?? ""}".trim();
    final numberPlate = vehicle["number_plate"] ?? "";

    // Construct image URL properly
    String? imageUrl;
    if (driver["image"] != null && driver["image"].toString().isNotEmpty) {
      imageUrl = "${App_Constructor().BaseURL}/assets/profile_image/${driver["image"]}";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Driver avatar with status
              Stack(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: kPrimaryColor, width: 2),
                    ),
                    child: imageUrl != null
                        ? ClipOval(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.person,
                          size: 35,
                          color: kPrimaryColor,
                        ),
                      ),
                    )
                        : Icon(Icons.person, size: 35, color: kPrimaryColor),
                  ),
                  if (driver["is_online"] == 1)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: kDarkBg, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Driver details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          driver["name"] ?? "Driver",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (vehicleInfo.isNotEmpty)
                      Text(
                        vehicleInfo,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    if (numberPlate.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          numberPlate,
                          style: TextStyle(
                            fontSize: 12,
                            color: kPrimaryColor,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Large chat button
              InkWell(
                onTap: () => _openChat(driver),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                    'assets/images/chat.svg',
                    color: Colors.black,
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> interest) {
    final driver = interest["driver"] as Map<String, dynamic>? ?? {};
    final vehicle = driver["vehicle"] as Map<String, dynamic>? ?? {};
    final driverName = driver["name"] ?? "Unknown Driver";
    final offerPrice = interest["driver_price"]?.toString() ?? "0";
    final message = interest["message"] ?? "";
    final vehicleInfo =
    "${vehicle["brand"] ?? ""} ${vehicle["model"] ?? ""}".trim();
    final numberPlate = vehicle["number_plate"] ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Driver avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: driver["profile_image"] != null
                    ? ClipOval(
                  child: Image.network(
                    driver["profile_image"],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 24,
                        color: kPrimaryColor),
                  ),
                )
                    : const Icon(Icons.person, size: 24, color: kPrimaryColor),
              ),
              const SizedBox(width: 12),

              // Driver info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (vehicleInfo.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        vehicleInfo,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                    if (numberPlate.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        numberPlate,
                        style: TextStyle(
                          fontSize: 10,
                          color: kPrimaryColor,
                        ),
                      ),
                    ],
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '"$message"',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Price and actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "TJS $offerPrice",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kPriceColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Chat button
                      InkWell(
                        onTap: () => _openChat(driver),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SvgPicture.asset(
                            'assets/images/chat.svg',
                            color: kPrimaryColor,
                            width: 18,
                            height: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Accept button (for pending orders)
                      if (_isPending)
                        InkWell(
                          onTap: () => _confirmAcceptDriver(interest),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kPrimaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.black,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom widgets with dark theme
class _LocationPin extends StatelessWidget {
  final Color color;
  final String label;
  final bool isPickup;
  const _LocationPin({
    required this.color,
    required this.label,
    this.isPickup = true,
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      // Pin tail
      Container(
        width: 10,
        height: 7,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(2),
            bottomRight: Radius.circular(2),
          ),
        ),
      ),
    ],
  );
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final bool dark;
  final bool isLoading; // New parameter

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.color,
    this.dark = false,
    this.isLoading = false, // Default to false
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isLoading ? null : onTap, // Disable tap when loading
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: dark ? kCardBg : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: isLoading
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: kPrimaryColor,
          strokeWidth: 2,
        ),
      )
          : Icon(
        icon,
        color: color ?? (dark ? Colors.white : Colors.black87),
        size: 20,
      ),
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
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}