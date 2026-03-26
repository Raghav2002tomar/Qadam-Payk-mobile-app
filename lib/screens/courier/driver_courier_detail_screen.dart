
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/svg.dart' show SvgPicture;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api_service/app_constocter.dart';
import '../../api_service/logger.dart';
import '../../providers/translate_provider.dart';
import '../../service/local_cache.dart';
import '../auth/SignInScreen.dart';
import '../mainView/provide/ChatProvider.dart';
import 'address_search_screen.dart';
import 'model/CourierModel.dart';

// ==================== CONSTANTS ====================
class AppColors {
  static const Color primary = Color(0xFF6FD94A);
  static const Color primaryLight = Color(0xFF8AE36A);
  static const Color background = Color(0xFF1C1C1E);
  static const Color card = Color(0xFF2A2A2C);
  static const Color price = Color(0xFFFF6B3D);
  static const Color pickup = Color(0xFF6FD94A);
  static const Color drop = Color(0xFF4285F4);
  static const Color error = Color(0xFFEA4335);
  static const Color warning = Color(0xFFFBBC05);
}

class AppStrings {
  static const String baseUrl = "https://qadampayk.com/assets/profile_image/";
}

// ==================== MODELS ====================
enum TripType { incity, intercity, unknown }
enum OrderStatus {
  pending,
  searching,
  accepted,
  started,
  pickedUp,
  inTransit,
  completed,
  cancelled,
  unknown
}

enum DeliveryStage {
  notStarted,
  headingToPickup,
  atPickup,
  headingToDrop,
  atDrop,
  completed
}

extension OrderStatusExt on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'PENDING';
      case OrderStatus.searching:
        return 'SEARCHING';
      case OrderStatus.accepted:
        return 'ACCEPTED';
      case OrderStatus.started:
        return 'STARTED';
      case OrderStatus.pickedUp:
        return 'PICKED UP';
      case OrderStatus.inTransit:
        return 'IN TRANSIT';
      case OrderStatus.completed:
        return 'COMPLETED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
      default:
        return 'UNKNOWN';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
      case OrderStatus.searching:
        return AppColors.warning;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.started:
        return Colors.blue;
      case OrderStatus.pickedUp:
        return AppColors.primary;
      case OrderStatus.inTransit:
        return AppColors.primary;
      case OrderStatus.completed:
        return Colors.purple;
      case OrderStatus.cancelled:
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }
}

// ==================== MAIN SCREEN ====================
class DriverCourierDetailScreen extends StatefulWidget {
  final String courierId;

  const DriverCourierDetailScreen({super.key, required this.courierId});

  @override
  State<DriverCourierDetailScreen> createState() =>
      _DriverCourierDetailScreenState();
}

class _DriverCourierDetailScreenState extends State<DriverCourierDetailScreen> with WidgetsBindingObserver {
  // ==================== CONTROLLERS ====================
  late MapController _mapController;
  final TextEditingController _messageController = TextEditingController(
    text: "I can deliver it safely and on time.",
  );

  // ==================== DATA ====================
  CourierModel? _ride;

  TripType get _tripType {
    if (_ride == null) return TripType.unknown;
    final type = (_ride!.tripType ?? "").toLowerCase().trim();
    if (type == "incity" || type == "in_city" || type == "in city" || type == "local") {
      return TripType.incity;
    }
    if (type == "intercity" || type == "inter_city" || type == "inter city" || type == "outstation") {
      return TripType.intercity;
    }
    return TripType.unknown;
  }

  OrderStatus get _orderStatus {
    if (_ride == null) return OrderStatus.unknown;
    switch (_ride!.status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'searching':
        return OrderStatus.searching;
      case 'accepted':
        return OrderStatus.accepted;
      case 'started':
        return OrderStatus.started;
      case 'picked_up':
        return OrderStatus.pickedUp;
      case 'in_transit':
      case 'in transit':
        return OrderStatus.inTransit;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.unknown;
    }
  }

  // ==================== UI STATE ====================
  bool _isLoading = true;
  bool _isActionInProgress = false;
  String? _errorMessage;
  String? _myOffer;
  DeliveryStage _currentStage = DeliveryStage.notStarted;

  // Bottom sheet state
  bool _isSheetExpanded = false;
  late double _sheetCollapsedHeight;
  late double _sheetExpandedHeight;
  double _sheetHeight = 200;

  // ==================== LOCATION & NAVIGATION ====================
  bool _isTracking = false;
  bool _isAtPickup = false;
  bool _isAtDrop = false;
  bool _pickupConfirmed = false;

  LatLng? _driverLocation;
  double _distanceToPickup = 0;
  double _distanceToDrop = 0;
  double? _heading;

  List<LatLng> _routeToPickup = [];
  List<LatLng> _routeToDrop = [];

  StreamSubscription<Position>? _locationSubscription;
  Timer? _locationUploadTimer;
  StreamSubscription<CompassEvent>? _compassSubscription;
  Position? _lastPosition;

  // Add this for tracking when screen comes back to foreground
  bool _needsRefresh = false;

  // ==================== GETTERS ====================
  LatLng get pickPoint {
    if (_ride == null) return const LatLng(30.9367, 75.8071);
    final lat = double.tryParse(_ride!.pickupLatitude ?? "");
    final lng = double.tryParse(_ride!.pickupLongitude ?? "");
    if (lat != null && lng != null) return LatLng(lat, lng);
    return const LatLng(30.9367, 75.8071);
  }

  LatLng get dropPoint {
    if (_ride == null) return const LatLng(30.9367, 75.8071);
    final lat = double.tryParse(_ride!.dropLatitude ?? "");
    final lng = double.tryParse(_ride!.dropLongitude ?? "");
    if (lat != null && lng != null) return LatLng(lat, lng);
    return const LatLng(30.9367, 75.8071);
  }

  LatLng get _mapCenter {
    if (_isTracking && _driverLocation != null) {
      return _driverLocation!;
    }
    if (_ride == null) return const LatLng(30.9367, 75.8071);
    return LatLng(
      (pickPoint.latitude + dropPoint.latitude) / 2,
      (pickPoint.longitude + dropPoint.longitude) / 2,
    );
  }

  List<String> get _quickOffers {
    if (_ride == null) return [];
    final base = double.tryParse(_ride!.suggestedPrice) ?? 0;
    return [
      (base).toStringAsFixed(0),
      (base + (base * 0.10)).toStringAsFixed(0),
      (base + (base * 0.20)).toStringAsFixed(0),
    ];
  }

  String get _currentPersonName {
    if (_pickupConfirmed) {
      return _ride!.receiverName ?? "Receiver";
    }
    return _ride!.senderName ?? "Sender";
  }

  String? get _currentPersonPhone {
    if (_pickupConfirmed) {
      return _ride!.receiverPhone;
    }
    return _ride!.senderPhone;
  }

  // ==================== LIFECYCLE ====================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mapController = MapController();
    _fetchCourierDetails();
    _initCompass();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sheetCollapsedHeight = MediaQuery.of(context).size.height * 0.25;
    _sheetExpandedHeight = MediaQuery.of(context).size.height * 0.7;
    _sheetHeight = _sheetCollapsedHeight;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopLocationTracking();
    _locationSubscription?.cancel();
    _locationUploadTimer?.cancel();
    _compassSubscription?.cancel();
    _mapController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // Add this to detect when app comes back to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("📱 App resumed - refreshing data");
      _refreshScreenData();
    }
  }

  // Add this to detect when screen is popped back to
  @override
  void didUpdateWidget(DriverCourierDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courierId != widget.courierId) {
      _fetchCourierDetails();
    }
  }

  Future<void> _refreshScreenData() async {
    await _fetchCourierDetails();
    if (_isTracking && _driverLocation != null) {
      _calculateDistances();
    }
  }

  // ==================== API CALLS ====================
  Future<void> _fetchCourierDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await LocalCache.getToken();
      final response = await http.get(
        Uri.parse(
          "${App_Constructor().BaseURL}/api/driver/couriers/${widget.courierId}",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      debugPrint("DETAIL RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded["status"] == true && decoded["data"] != null) {
          setState(() {
            _ride = CourierModel.fromJson(decoded["data"]);
          });

          // Update button states after fetching
          _updateButtonStates();

          // Set the correct stage based on API status
          switch (_orderStatus) {
            case OrderStatus.accepted:
              _currentStage = DeliveryStage.notStarted;
              _pickupConfirmed = false;
              _isAtPickup = false;
              _isAtDrop = false;
              if (_isTracking) _stopLocationTracking();
              break;

            case OrderStatus.started:
              _currentStage = DeliveryStage.headingToPickup;
              _pickupConfirmed = false;
              _isAtPickup = false;
              _isAtDrop = false;
              if (_tripType == TripType.incity && !_isTracking) {
                _startLocationTracking();
              }
              break;

            case OrderStatus.pickedUp:
              _currentStage = DeliveryStage.headingToDrop;
              _pickupConfirmed = true;
              _isAtPickup = true;
              _isAtDrop = false;
              if (_tripType == TripType.incity && !_isTracking) {
                _startLocationTracking();
              }
              break;

            case OrderStatus.inTransit:
              _currentStage = DeliveryStage.headingToDrop;
              _pickupConfirmed = true;
              _isAtPickup = true;
              _isAtDrop = false;
              if (_tripType == TripType.incity && !_isTracking) {
                _startLocationTracking();
              }
              break;

            case OrderStatus.completed:
              _currentStage = DeliveryStage.completed;
              _pickupConfirmed = true;
              _isAtPickup = true;
              _isAtDrop = true;
              _stopLocationTracking();
              break;

            default:
              break;
          }
        } else {
          setState(() {
            _errorMessage = decoded["message"] ?? "Failed to load details";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Error ${response.statusCode}";
        });
      }
    } catch (e) {
      debugPrint("FETCH ERROR: $e");
      setState(() {
        _errorMessage = "Network error. Please check connection.";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Add this helper method to ensure button states are correct
  void _updateButtonStates() {
    if (_ride == null || !_isTracking || _driverLocation == null) return;

    final distanceToPickup = Geolocator.distanceBetween(
      _driverLocation!.latitude,
      _driverLocation!.longitude,
      pickPoint.latitude,
      pickPoint.longitude,
    );

    final distanceToDrop = Geolocator.distanceBetween(
      _driverLocation!.latitude,
      _driverLocation!.longitude,
      dropPoint.latitude,
      dropPoint.longitude,
    );

    setState(() {
      if (_currentStage == DeliveryStage.headingToPickup && !_pickupConfirmed) {
        _isAtPickup = distanceToPickup < 3000;
        if (_isAtPickup) {
          _currentStage = DeliveryStage.atPickup;
        }
      }

      if (_currentStage == DeliveryStage.headingToDrop && _pickupConfirmed) {
        _isAtDrop = distanceToDrop < 3000;
        if (_isAtDrop) {
          _currentStage = DeliveryStage.atDrop;
        }
      }
    });
  }

  Future<void> _sendOffer(String price) async {
    if (_ride == null || price.isEmpty) return;

    setState(() {
      _isActionInProgress = true;
    });

    try {
      final token = await LocalCache.getToken();
      final response = await http.post(
        Uri.parse(
          "${App_Constructor().BaseURL}/api/courier/request/${_ride!.id}/interest",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "driver_price": double.tryParse(price) ?? 0,
          "message": _messageController.text,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["status"] == true) {
        setState(() => _myOffer = price);
        _showToast("💰 Offer sent: TJS $price", isSuccess: true);
        await _fetchCourierDetails();
      } else {
        _showToast(data["message"] ?? "Failed to send offer", isError: true);
      }
    } catch (e) {
      _showToast("Network error", isError: true);
    } finally {
      setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _cancelOrder() async {
    if (_ride == null) return;

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text("Cancel Delivery?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to cancel this delivery?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );

    if (shouldCancel != true) return;

    setState(() => _isActionInProgress = true);

    try {
      final token = await LocalCache.getToken();
      final response = await http.post(
        Uri.parse(
          "${App_Constructor().BaseURL}/api/driver/courier/cancel/${_ride!.id}",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["status"] == true) {
        _showToast("✅ Order cancelled", isSuccess: true);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context, true);
        });
      } else {
        _showToast(data['message'] ?? "Failed to cancel", isError: true);
      }
    } catch (e) {
      _showToast("Network error", isError: true);
    } finally {
      setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _startRide() async {
    if (_ride == null) return;

    setState(() => _isActionInProgress = true);

    try {
      final token = await LocalCache.getToken();
      final response = await http.post(
        Uri.parse(
          "${App_Constructor().BaseURL}/api/courier/update-status/${_ride!.id}",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"status": "started"}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["status"] == true) {
        _showToast("✅ Heading to pickup", isSuccess: true);

        setState(() {
          _currentStage = DeliveryStage.headingToPickup;
        });

        if (_tripType == TripType.incity) {
          await _startLocationTracking();
        }

        await _fetchCourierDetails();
      } else {
        _showToast(data["message"] ?? "Failed to start", isError: true);
      }
    } catch (e) {
      _showToast("Network error", isError: true);
    } finally {
      setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _markPickedUp() async {
    if (_ride == null) return;

    setState(() => _isActionInProgress = true);

    try {
      final token = await LocalCache.getToken();
      final response = await http.post(
        Uri.parse(
          "${App_Constructor().BaseURL}/api/courier/update-status/${_ride!.id}",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"status": "picked_up"}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["status"] == true) {
        setState(() {
          _pickupConfirmed = true;
          _isAtPickup = true;
          _currentStage = DeliveryStage.headingToDrop;
        });

        await _updateToInTransit();

        if (_driverLocation != null) {
          _fetchRoute(_driverLocation!, dropPoint, false);
        }

        _showToast("✅ Package picked up! Heading to drop.", isSuccess: true);
        await _fetchCourierDetails();
      } else {
        _showToast(data['message'] ?? "Failed to mark pickup", isError: true);
      }
    } catch (e) {
      _showToast("Network error", isError: true);
    } finally {
      setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _updateToInTransit() async {
    try {
      final token = await LocalCache.getToken();
      await http.post(
        Uri.parse(
          "${App_Constructor().BaseURL}/api/courier/update-status/${_ride!.id}",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"status": "in_transit"}),
      );
      debugPrint("Auto updated to in_transit");
    } catch (e) {
      debugPrint("Auto update to in_transit failed: $e");
    }
  }

  Future<void> _completeRide() async {
    if (_ride == null) return;

    setState(() => _isActionInProgress = true);

    try {
      final token = await LocalCache.getToken();
      final response = await http.post(
        Uri.parse(
          "${App_Constructor().BaseURL}/api/courier/update-status/${_ride!.id}",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"status": "completed"}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["status"] == true) {
        _showToast("✅ Delivery Completed", isSuccess: true);
        _stopLocationTracking();
        setState(() {
          _currentStage = DeliveryStage.completed;
        });
        await _fetchCourierDetails();
      } else {
        _showToast(data["message"] ?? "Failed to complete", isError: true);
      }
    } catch (e) {
      _showToast("Network error", isError: true);
    } finally {
      setState(() => _isActionInProgress = false);
    }
  }

  // ==================== LOCATION TRACKING ====================
  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showToast("Please enable location services", isWarning: true);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showToast("Location permission denied", isError: true);
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showToast("Location permissions permanently denied", isError: true);
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition();
      _updateLocation(pos);

      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 20,
        ),
      ).listen(_updateLocation);

      _locationUploadTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        if (_lastPosition != null && _ride != null) {
          _uploadLocation(_lastPosition!.latitude, _lastPosition!.longitude);
        }
      });

      setState(() {
        _isTracking = true;
      });

      _showToast("📍 Location tracking started", isSuccess: true);
    } catch (e) {
      debugPrint("Location tracking error: $e");
    }
  }

  void _updateLocation(Position pos) {
    if (!mounted) return;

    _lastPosition = pos;
    final newLoc = LatLng(pos.latitude, pos.longitude);

    setState(() {
      _driverLocation = newLoc;
    });

    _calculateDistances();

    if (_isTracking) {
      _mapController.move(newLoc, 16.0);
    }

    _uploadLocation(pos.latitude, pos.longitude);
  }

  Future<void> _uploadLocation(double lat, double lng) async {
    if (_ride == null) return;

    try {
      final token = await LocalCache.getToken();
      await http.post(
        Uri.parse("${App_Constructor().BaseURL}/api/courier/update-location"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "latitude": lat,
          "longitude": lng,
          "courier_request_id": _ride!.id.toString(),
        }),
      );
    } catch (e) {
      debugPrint("Location upload error: $e");
    }
  }

  void _stopLocationTracking() {
    setState(() {
      _isTracking = false;
    });
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _locationUploadTimer?.cancel();
    _locationUploadTimer = null;
    _showToast("📍 Location tracking stopped", isWarning: true);
  }

  void _calculateDistances() {
    if (_driverLocation == null || _ride == null) return;

    final newDistanceToPickup = Geolocator.distanceBetween(
      _driverLocation!.latitude,
      _driverLocation!.longitude,
      pickPoint.latitude,
      pickPoint.longitude,
    );

    final newDistanceToDrop = Geolocator.distanceBetween(
      _driverLocation!.latitude,
      _driverLocation!.longitude,
      dropPoint.latitude,
      dropPoint.longitude,
    );

    bool needsUpdate = false;

    if (_currentStage == DeliveryStage.headingToPickup && !_pickupConfirmed) {
      final wasAtPickup = _isAtPickup;
      _isAtPickup = newDistanceToPickup < 3000;
      if (_isAtPickup && !wasAtPickup) {
        _currentStage = DeliveryStage.atPickup;
        needsUpdate = true;
        debugPrint("🎯 Reached pickup location! Distance: ${newDistanceToPickup.toStringAsFixed(0)}m");
      }
    }

    if (_currentStage == DeliveryStage.headingToDrop && _pickupConfirmed) {
      final wasAtDrop = _isAtDrop;
      _isAtDrop = newDistanceToDrop < 3000;
      if (_isAtDrop && !wasAtDrop) {
        _currentStage = DeliveryStage.atDrop;
        needsUpdate = true;
        debugPrint("🎯 Reached drop location! Distance: ${newDistanceToDrop.toStringAsFixed(0)}m");
      }
    }

    setState(() {
      _distanceToPickup = newDistanceToPickup;
      _distanceToDrop = newDistanceToDrop;
    });

    if (_routeToPickup.isEmpty && _currentStage == DeliveryStage.headingToPickup && _driverLocation != null) {
      _fetchRoute(_driverLocation!, pickPoint, true);
    }

    if (_pickupConfirmed && _routeToDrop.isEmpty && _driverLocation != null) {
      _fetchRoute(_driverLocation!, dropPoint, false);
    }
  }

  Future<void> _fetchRoute(LatLng start, LatLng end, bool isToPickup) async {
    try {
      final url = "http://router.project-osrm.org/route/v1/driving/"
          "${start.longitude},${start.latitude};"
          "${end.longitude},${end.latitude}?"
          "overview=full&geometries=geojson";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final List coords = data["routes"][0]["geometry"]["coordinates"];
          final route = coords
              .map((c) => LatLng(c[1] as double, c[0] as double))
              .toList();

          setState(() {
            if (isToPickup) {
              _routeToPickup = route;
            } else {
              _routeToDrop = route;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Route fetch error: $e");
    }
  }

  Future<void> _initCompass() async {
    try {
      _compassSubscription = FlutterCompass.events?.listen((event) {
        if (mounted) {
          setState(() {
            _heading = event.heading;
          });
        }
      });
    } catch (e) {
      debugPrint("Compass error: $e");
    }
  }

  // ==================== UTILITIES ====================
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return "${meters.round()} m";
    }
    return "${(meters / 1000).toStringAsFixed(1)} km";
  }

  String _maskPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return "Not available";
    if (_orderStatus != OrderStatus.pending
       ) {
      return phone;
    }
    if (phone.length >= 4) {
      return '*${phone.substring(phone.length - 4)}';
    }
    return '****';
  }

  void _showToast(String message, {
    bool isSuccess = false,
    bool isError = false,
    bool isWarning = false,
  }) {
    Color color = Colors.grey;
    if (isSuccess) color = AppColors.primary;
    if (isError) color = AppColors.error;
    if (isWarning) color = AppColors.warning;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openFullMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullMapView(
          pickPoint: pickPoint,
          dropPoint: dropPoint,
          pickupLabel: _ride!.pickupLocation,
          dropLabel: _ride!.dropLocation,
          rideId: _ride!.id.toString(),
          isStartRideMode: _orderStatus == OrderStatus.accepted,
          tripType: _tripType,
        ),
      ),
    ).then((started) {
      if (started == true) {
        _fetchCourierDetails();
        if (_tripType == TripType.incity) {
          _startLocationTracking();
        }
      }
    });
  }

  void _openChat() async {
    final token = await LocalCache.getToken();
    if (token == null || token.isEmpty) {
      _showToast("Please login first", isWarning: true);
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneNumberScreen()));
      return;
    }

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.startChat(
      context: context,
      otherUserId: _ride!.userId,
      userName: _ride!.senderFullName ?? 'User',
    );
  }

  void _showCustomOfferSheet() {
    if (_ride == null) return;

    final controller = TextEditingController(text: _myOffer ?? _ride!.suggestedPrice);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              "Enter Your Price",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                prefixText: "TJS  ",
                prefixStyle: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _sendOffer(controller.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text("Send Offer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== BUILD METHODS ====================
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    // Force recalculation of button states when building
    if (_isTracking && _driverLocation != null && _ride != null) {
      _calculateDistances();
    }

    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null || _ride == null) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            _buildMap(),
            _buildTopBar(),
            _buildZoomControls(),
            _buildBottomSheet(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Shimmer.fromColors(
        baseColor: Colors.grey.shade800,
        highlightColor: Colors.grey.shade600,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: List.generate(5, (index) => Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
            )),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade600),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? "Something went wrong",
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchCourierDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _mapCenter,
        initialZoom: _isTracking ? 16.0 : 12.0,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
        // Add this to enable caching (required by OSM policy)
        keepAlive: true,
      ),
      children: [
        /// MAP TILES
        // TileLayer(
        //   urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
        //   userAgentPackageName: 'com.qadampayk.app',
        //   maxZoom: 19,
        // ),
        // TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        //     userAgentPackageName: 'com.qadampayk.app'),
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.qadampayk.app',
          maxZoom: 19,
        ),

        /// REQUIRED OSM ATTRIBUTION
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
            ),
          ],
        ),

        // Add proper attribution as required by OSM policy
        // if (!_isTracking)
        //   RichAttributionWidget(
        //     attributions: [
        //       TextSourceAttribute(
        //         text: 'OpenStreetMap contributors',
        //         // You can add a link to your app's privacy policy or OSM page
        //       ),
        //     ],
        //   ),

        if (_isTracking) ...[
          if (!_pickupConfirmed && _routeToPickup.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _routeToPickup,
                  strokeWidth: 6,
                  color: Colors.blue.withOpacity(0.8),
                  borderStrokeWidth: 2,
                  borderColor: Colors.white,
                ),
              ],
            ),
          if (_pickupConfirmed && _routeToDrop.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _routeToDrop,
                  strokeWidth: 6,
                  color: AppColors.primary.withOpacity(0.8),
                  borderStrokeWidth: 2,
                  borderColor: Colors.white,
                ),
              ],
            ),
        ],

        if (!_isTracking || (_routeToPickup.isEmpty && _routeToDrop.isEmpty))
          PolylineLayer(
            polylines: [
              Polyline(
                points: [pickPoint, dropPoint],
                strokeWidth: 3,
                color: AppColors.primary.withOpacity(0.5),
                borderStrokeWidth: 1,
                borderColor: Colors.white30,
              ),
            ],
          ),

        MarkerLayer(
          markers: [
            _buildMarker(
              pickPoint,
              "PICKUP",
              _isAtPickup ? AppColors.warning : AppColors.primary,
              _ride!.pickupLocation,
            ),
            _buildMarker(
              dropPoint,
              "DROP",
              _isAtDrop ? AppColors.primary : AppColors.drop,
              _ride!.dropLocation,
            ),
            if (_isTracking && _driverLocation != null)
              Marker(
                point: _driverLocation!,
                width: 80,
                height: 80,
                child: _buildDriverMarker(),
              ),
          ],
        ),
      ],
    );
  }

  Marker _buildMarker(LatLng point, String label, Color color, String address) {
    final shortAddress = address.length > 30 ? "${address.substring(0, 27)}..." : address;

    return Marker(
      point: point,
      width: 180,
      height: 80,
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
              ],
            ),
            child: Text(
              shortAddress,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Center(
              child: Text(
                label[0],
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_lastPosition != null)
          Container(
            width: _lastPosition!.accuracy * 2,
            height: _lastPosition!.accuracy * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withOpacity(0.1),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
          ),
        if (_heading != null)
          Transform.rotate(
            angle: (_heading! * 3.14159 / 180),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 12),
                ],
              ),
              child: const Icon(Icons.navigation, color: Colors.white, size: 26),
            ),
          )
        else
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 12),
              ],
            ),
            child: const Icon(Icons.directions_car, color: Colors.white, size: 20),
          ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 10,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Back button
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                constraints: const BoxConstraints(maxWidth: 40, maxHeight: 40),
                padding: EdgeInsets.zero,
              ),
            ),

            const SizedBox(width: 8),

            // Refresh button (NEW)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                onPressed: () {
                  _refreshScreenData();
                  _showToast("🔄 Refreshing data...", isSuccess: true);
                },
                constraints: const BoxConstraints(maxWidth: 40, maxHeight: 40),
                padding: EdgeInsets.zero,
              ),
            ),

            const Spacer(),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _orderStatus.color.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _orderStatus.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _orderStatus.displayName,
                    style: TextStyle(
                      color: _orderStatus.color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Full screen button
            if (!_isTracking)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: IconButton(
                  icon: const Icon(Icons.fullscreen, color: Colors.white),
                  onPressed: _openFullMap,
                  constraints: const BoxConstraints(maxWidth: 40, maxHeight: 40),
                  padding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildZoomControls() {
    return Positioned(
      bottom: _sheetHeight + 20,
      right: 12,
      child: Column(
        children: [

          _buildZoomButton(Icons.add, () {
            _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom + 1,
            );
          }),
          const SizedBox(height: 8),
          _buildZoomButton(Icons.remove, () {
            _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom - 1,
            );
          }),
          if (_isTracking && _driverLocation != null) ...[
            const SizedBox(height: 8),
            _buildZoomButton(Icons.my_location, () {
              _mapController.move(_driverLocation!, 16.0);
            }),
          ],
          if (_isTracking) ...[
            const SizedBox(height: 8),
            _buildZoomButton(Icons.close, _stopLocationTracking, color: Colors.red),
          ],
        ],
      ),
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onTap, {Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color == Colors.white ? Colors.white : color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6)],
        ),
        child: Icon(icon, color: color == Colors.white ? Colors.black87 : Colors.white),
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() {
            _sheetHeight -= details.delta.dy;
            _sheetHeight = _sheetHeight.clamp(_sheetCollapsedHeight, _sheetExpandedHeight);
          });
        },
        onVerticalDragEnd: (details) {
          setState(() {
            if (_sheetHeight > (_sheetCollapsedHeight + _sheetExpandedHeight) / 2) {
              _sheetHeight = _sheetExpandedHeight;
              _isSheetExpanded = true;
            } else {
              _sheetHeight = _sheetCollapsedHeight;
              _isSheetExpanded = false;
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _sheetHeight,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, -4)),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: _isSheetExpanded
                    ? _buildExpandedSheet()
                    : _buildCollapsedSheet(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedSheet() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.3), AppColors.primary.withOpacity(0.1)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.5)),
            ),
            child: Center(
              child: Text(
                _currentPersonName.isNotEmpty ? _currentPersonName[0].toUpperCase() : "?",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _pickupConfirmed ? "RECEIVER" : "SENDER",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentPersonName,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                _orderStatus != OrderStatus.pending && _orderStatus != OrderStatus.searching ? Row(
                  children: [
                    Icon(Icons.phone, color: AppColors.primary, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      _maskPhoneNumber(_currentPersonPhone),
                      style: TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                  ],
                ):Row(
                  children: [
                    Icon(Icons.phone, color: AppColors.primary, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      "**********",
                      style: TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Row(
            children: [
              if (_orderStatus != OrderStatus.pending && _orderStatus != OrderStatus.searching)
                _buildIconButton(
                  icon: 'assets/images/chat.svg',
                  onTap: _openChat,
                ),
              const SizedBox(width: 8),
              _buildIconButton(
                icon: Icons.keyboard_arrow_up,
                isAsset: false,
                onTap: () => setState(() {
                  _sheetHeight = _sheetExpandedHeight;
                  _isSheetExpanded = true;
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedSheet() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTripSummary(),
          const SizedBox(height: 16),
          _buildStatusActions(),
          const SizedBox(height: 16),
          _buildLocationCard(),
          const SizedBox(height: 16),
          _buildPackageCard(),
          const SizedBox(height: 16),
          _buildPeopleCards(),
          const SizedBox(height: 16),
          _buildPaymentCard(),
          const SizedBox(height: 16),
          if (_ride!.instruction != null && _ride!.instruction!.isNotEmpty)
            _buildInstructionCard(),
        ],
      ),
    );
  }

  Widget _buildTripSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  "Distance",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _ride!.distance ?? "N/A",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
          Expanded(
            child: Column(
              children: [
                Text(
                  "Est. Time",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _ride!.time ?? "N/A",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
          Expanded(
            child: Column(
              children: [
                Text(
                  "Price",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  "TJS ${_ride!.suggestedPrice}",
                  style: const TextStyle(color: AppColors.price, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildLocationRow(
            label: "PICKUP",
            icon: Icons.circle,
            color: AppColors.primary,
            address: _ride!.pickupLocation,
            landmark: _ride!.senderLandmark,
            isDone: _pickupConfirmed,
          ),
          const SizedBox(height: 8),
          _buildLocationRow(
            label: "DROP",
            icon: Icons.location_on,
            color: AppColors.drop,
            address: _ride!.dropLocation,
            landmark: _ride!.receiverLandmark,
            isDone: _isAtDrop,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required String label,
    required IconData icon,
    required Color color,
    required String address,
    String? landmark,
    required bool isDone,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDone ? AppColors.primary : color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.black, size: 16)
                : Icon(icon, color: Colors.white, size: 16),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              if (landmark != null && landmark.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  "📍 $landmark",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Package Details",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInfoRow("Description", _ride!.packageDescription ?? "Not specified"),
          _buildInfoRow("Size", _ride!.packageSize?.toUpperCase() ?? "Not specified"),
          _buildInfoRow("Trip Type", _ride!.tripType?.toUpperCase() ?? "Not specified"),
        ],
      ),
    );
  }

  Widget _buildPeopleCards() {
    return Row(
      children: [
        Expanded(
          child: _buildPersonCard(
            title: "SENDER",
            name: _ride!.senderName ?? "Unknown",
            phone: _ride!.senderPhone,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPersonCard(
            title: "RECEIVER",
            name: _ride!.receiverName ?? "Unknown",
            phone: _ride!.receiverPhone,
            color: AppColors.drop,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonCard({
    required String title,
    required String name,
    String? phone,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (phone != null) ...[
            const SizedBox(height: 4),
            _orderStatus != OrderStatus.pending && _orderStatus != OrderStatus.searching ? Row(
              children: [
                Icon(Icons.phone, color: AppColors.primary, size: 12),
                const SizedBox(width: 4),
                Text(
                  _maskPhoneNumber(_currentPersonPhone),
                  style: TextStyle(color: AppColors.primary, fontSize: 12),
                ),
              ],
            ):Row(
              children: [
                Icon(Icons.phone, color: AppColors.primary, size: 12),
                const SizedBox(width: 4),
                Text(
                  "**********",
                  style: TextStyle(color: AppColors.primary, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Payment",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInfoRow("Amount", "TJS ${_ride!.suggestedPrice}", isPrice: true),
          _buildInfoRow("Method", _ride!.paymentMethod?.toUpperCase() ?? "Not specified"),
          _buildInfoRow(
            "Paid By",
            _ride!.paidBy?.toUpperCase() ?? "Not specified",
            valueColor: _ride!.paidBy?.toLowerCase() == "sender" ? AppColors.primary : AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Instructions",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _ride!.instruction!,
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isPrice = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isPrice ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? (isPrice ? AppColors.price : Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusActions() {
    if (_orderStatus == OrderStatus.pending || _orderStatus == OrderStatus.searching) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isActionInProgress ? null : _cancelOrder,
              icon: Icon(Icons.cancel, color: _isActionInProgress ? Colors.grey : AppColors.error),
              label: Text(
                _isActionInProgress ? "CANCELLING..." : "CANCEL ORDER",
                style: TextStyle(color: _isActionInProgress ? Colors.grey : AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _isActionInProgress ? Colors.grey : AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isActionInProgress
                  ? null
                  : () => _sendOffer(_ride!.suggestedPrice),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isActionInProgress
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black))
                  : Text("Accept TJS ${_ride!.suggestedPrice}"),
            ),
          ),
          const SizedBox(height: 12),

          Center(
            child: Text(
              _myOffer != null
                  ? "Your offer: TJS $_myOffer  •  tap to change"
                  : "Suggest your price:",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              ..._quickOffers.map(
                    (p) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildQuickOfferButton(
                      p,
                      _isActionInProgress ? null : () => _sendOffer(p),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _isActionInProgress ? null : _showCustomOfferSheet,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _isActionInProgress ? Colors.grey.shade800 : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: _isActionInProgress ? Colors.grey.shade600 : Colors.white60,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _messageController,
            maxLines: 2,
            enabled: !_isActionInProgress,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Message (optional)",
              hintStyle: TextStyle(
                color: _isActionInProgress ? Colors.grey.shade700 : Colors.grey.shade500,
                fontSize: 13,
              ),
              filled: true,
              fillColor: _isActionInProgress ? Colors.grey.shade900 : AppColors.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _isActionInProgress ? Colors.grey.shade700 : AppColors.primary,
                  width: 1.2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_orderStatus == OrderStatus.accepted) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _tripType == TripType.incity
                        ? "Tap START to begin navigation to pickup"
                        : "Tap START to begin delivery",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isActionInProgress ? null : _startRide,
              icon: const Icon(Icons.play_arrow),
              label: Text(
                _tripType == TripType.incity ? "START TRACKING" : "START DELIVERY",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _tripType == TripType.incity ? AppColors.primary : AppColors.warning,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      );
    }

    if (_orderStatus == OrderStatus.started) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.navigation, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "HEADING TO PICKUP",
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${_formatDistance(_distanceToPickup)} remaining",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      if (_distanceToPickup < 3000)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "⚠️ Within pickup zone",
                            style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_currentStage == DeliveryStage.atPickup)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                onPressed: _isActionInProgress ? null : _markPickedUp,
                icon: const Icon(Icons.check_circle, size: 20),
                label: Text(
                  _isActionInProgress
                      ? "PICKING UP..."
                      : "✓ CONFIRM PICKUP (${_formatDistance(_distanceToPickup)})",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            )
          else if (_distanceToPickup < 3000)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "You're ${_formatDistance(_distanceToPickup)} from pickup. Keep going!",
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (_distanceToPickup / 5000).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade800,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 12),
                Text(
                  _distanceToPickup < 3000
                      ? "📍 Almost there! ${_formatDistance(_distanceToPickup)} to pickup"
                      : "Approaching pickup location",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_orderStatus == OrderStatus.pickedUp || _orderStatus == OrderStatus.inTransit) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.route, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "HEADING TO DROP",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${_formatDistance(_distanceToDrop)} remaining",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      if (_distanceToDrop < 3000)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "⚠️ Within drop zone",
                            style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_currentStage == DeliveryStage.atDrop)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                onPressed: _isActionInProgress ? null : _completeRide,
                icon: const Icon(Icons.flag, size: 20),
                label: Text(
                  _isActionInProgress
                      ? "COMPLETING..."
                      : "✓ COMPLETE DELIVERY (${_formatDistance(_distanceToDrop)})",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            )
          else if (_distanceToDrop < 3000)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "You're ${_formatDistance(_distanceToDrop)} from drop. Almost there!",
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (_distanceToDrop / 5000).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade800,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  _distanceToDrop < 3000
                      ? "📍 Almost there! ${_formatDistance(_distanceToDrop)} to drop"
                      : "Approaching drop location",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_orderStatus == OrderStatus.completed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: const Center(
          child: Text(
            "✓ DELIVERY COMPLETED",
            style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildQuickOfferButton(String price, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey.shade800 : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Center(
          child: _isActionInProgress && onTap != null
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          )
              : Text(
            "TJS $price",
            style: TextStyle(
              color: onTap == null ? Colors.grey.shade600 : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required dynamic icon,
    bool isAsset = true,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Center(
          child: isAsset
              ? SvgPicture.asset(icon, color: Colors.white, width: 22, height: 22)
              : Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

// ==================== FULL MAP VIEW ====================
class FullMapView extends StatefulWidget {
  final LatLng pickPoint;
  final LatLng dropPoint;
  final String pickupLabel;
  final String dropLabel;
  final String rideId;
  final bool isStartRideMode;
  final TripType tripType;

  const FullMapView({
    super.key,
    required this.pickPoint,
    required this.dropPoint,
    required this.pickupLabel,
    required this.dropLabel,
    required this.rideId,
    required this.isStartRideMode,
    required this.tripType,
  });

  @override
  State<FullMapView> createState() => _FullMapViewState();
}

class _FullMapViewState extends State<FullMapView> {
  late MapController _mapController;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  bool _isStarting = false;
  LatLng? _driverLocation;
  double? _heading;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchRoute();

    if (widget.tripType == TripType.incity) {
      _initLocationTracking();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchRoute() async {
    setState(() => _isLoadingRoute = true);
    try {
      final p = widget.pickPoint;
      final d = widget.dropPoint;
      final url = "http://router.project-osrm.org/route/v1/driving/"
          "${p.longitude},${p.latitude};${d.longitude},${d.latitude}?overview=full&geometries=geojson";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List coords = data["routes"][0]["geometry"]["coordinates"];
        setState(() {
          _routePoints = coords
              .map((c) => LatLng(c[1] as double, c[0] as double))
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Route fetch error: $e");
    }
    setState(() => _isLoadingRoute = false);
  }

  Future<void> _initLocationTracking() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _driverLocation = LatLng(pos.latitude, pos.longitude));
    } catch (e) {
      debugPrint("Location error: $e");
    }

    FlutterCompass.events?.listen((event) {
      if (mounted) setState(() => _heading = event.heading);
    });
  }

  Future<void> _startRide() async {
    setState(() => _isStarting = true);

    try {
      final token = await LocalCache.getToken();
      final response = await http.post(
        Uri.parse("${App_Constructor().BaseURL}/api/courier/update-status/${widget.rideId}"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"status": "in_transit"}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Delivery Started!")),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint("Start error: $e");
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(
      (widget.pickPoint.latitude + widget.dropPoint.latitude) / 2,
      (widget.pickPoint.longitude + widget.dropPoint.longitude) / 2,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _driverLocation ?? center,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}",
                subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
                userAgentPackageName: "com.qadampayk.app",
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints.isNotEmpty ? _routePoints : [widget.pickPoint, widget.dropPoint],
                    strokeWidth: 5,
                    color: AppColors.primary.withOpacity(0.8),
                    borderStrokeWidth: 2,
                    borderColor: Colors.white,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  _buildMarker(widget.pickPoint, "PICKUP", AppColors.primary),
                  _buildMarker(widget.dropPoint, "DROP", AppColors.drop),
                  if (_driverLocation != null)
                    Marker(
                      point: _driverLocation!,
                      width: 60,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 10)],
                        ),
                        child: const Icon(Icons.navigation, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ],
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
          ),

          if (widget.isStartRideMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.tripType == TripType.incity)
                      Row(
                        children: [
                          Icon(
                            _driverLocation != null ? Icons.location_on : Icons.location_searching,
                            color: _driverLocation != null ? AppColors.primary : AppColors.warning,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _driverLocation != null ? "GPS Ready" : "Acquiring GPS...",
                            style: TextStyle(
                              color: _driverLocation != null ? Colors.white60 : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _isStarting ? null : _startRide,
                        icon: _isStarting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black))
                            : const Icon(Icons.play_arrow),
                        label: Text(_isStarting ? "STARTING..." : "START DELIVERY"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.tripType == TripType.incity ? AppColors.primary : AppColors.warning,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Marker _buildMarker(LatLng point, String label, Color color) {
    return Marker(
      point: point,
      width: 120,
      height: 60,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color),
            ),
            child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      ),
    );
  }
}