




import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:ui' as ui;
import 'package:bla_bla_car/api_service/app_constocter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../service/local_cache.dart';
import 'all_order_list_screen.dart';

const Color kPrimaryColor = Color(0xFF008955);
const Color kPrimaryLight = Color(0xFFE8F5EF);

// ─────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────
class CreateCourierScreen extends StatefulWidget {
  const CreateCourierScreen({super.key});
  @override
  State<CreateCourierScreen> createState() => _CreateCourierScreenState();
}

class _CreateCourierScreenState extends State<CreateCourierScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController =
  DraggableScrollableController();

  LatLng? pickupLatLng, dropLatLng;
  String pickupAddress = '', dropAddress = '';
  List<LatLng> routePoints = [];
  double distanceKm = 0, durationMin = 0;
  LatLng _center = const LatLng(38.575522, 68.764755);
  LatLng? userLocation;

  bool _isSelectingPin = false;
  bool _pinModeActive = false;
  bool _isLoadingRoute = false;

  // Order details
  String senderName = '', senderPhone = '';
  String receiverName = '', receiverPhone = '';
  String senderLandmark = '', receiverLandmark = '';
  String packageDesc = '';
  String packageSize = 'Small';
  String specialInstructions = '';

  // Offer price
  String offerPrice = '';
  String payMethod = 'cash';
  String paidBy = 'sender';

  late AnimationController _routeAnim;
  late Animation<double> _routeFade;

  @override
  void initState() {
    super.initState();
    _routeAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _routeFade = CurvedAnimation(parent: _routeAnim, curve: Curves.easeIn);
    _initLocation();
  }

  @override
  void dispose() {
    _routeAnim.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      await Geolocator.requestPermission();
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        userLocation = LatLng(pos.latitude, pos.longitude);
        _center = userLocation!;
      });
      _mapController.move(_center, 15);
    } catch (_) {}
  }

  Future<String> _reverseGeocode(LatLng ll) async {
    try {
      final res = await http.get(
        Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?lat=${ll.latitude}&lon=${ll.longitude}&format=json'),
        headers: {'User-Agent': 'com.qadampayk.app'},
      );
      if (res.statusCode == 200) {
        return json.decode(res.body)['display_name'] ?? 'Unknown';
      }
    } catch (_) {}
    return 'Selected location';
  }

  void _setLocation(bool isPickup, LatLng ll, String address) {
    setState(() {
      if (isPickup) {
        pickupLatLng = ll;
        pickupAddress = address;
      } else {
        dropLatLng = ll;
        dropAddress = address;
      }
    });
    _mapController.move(ll, 15);
    if (pickupLatLng != null && dropLatLng != null) _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    setState(() => _isLoadingRoute = true);
    try {
      final url =
          'http://router.project-osrm.org/route/v1/driving/${pickupLatLng!.longitude},${pickupLatLng!.latitude};${dropLatLng!.longitude},${dropLatLng!.latitude}?overview=full&geometries=geojson';
      final res = await http.get(Uri.parse(url));
      final data = json.decode(res.body);
      final coords = data['routes'][0]['geometry']['coordinates'] as List;
      setState(() {
        routePoints = coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();
        distanceKm = data['routes'][0]['distance'] / 1000;
        durationMin = data['routes'][0]['duration'] / 60;
        _isLoadingRoute = false;
        final base = distanceKm > 50 ? 200 : 50;
        offerPrice = (base + distanceKm * 10).toStringAsFixed(0);
      });
      _routeAnim.forward(from: 0);
      _fitBounds();
    } catch (_) {
      setState(() => _isLoadingRoute = false);
    }
  }

  void _fitBounds() {
    if (pickupLatLng == null || dropLatLng == null) return;
    _mapController.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds(pickupLatLng!, dropLatLng!),
      padding: const EdgeInsets.fromLTRB(60, 160, 60, 360),
    ));
  }

  void _swapLocations() {
    if (pickupLatLng == null || dropLatLng == null) return;
    setState(() {
      final tl = pickupLatLng; final ta = pickupAddress;
      pickupLatLng = dropLatLng; pickupAddress = dropAddress;
      dropLatLng = tl; dropAddress = ta;
    });
    _fetchRoute();
  }

  void _startPinMode(bool isPickup) {
    setState(() { _pinModeActive = true; _isSelectingPin = isPickup; });
    _sheetController.animateTo(0.12,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Move map to ${isPickup ? 'pickup' : 'drop'} point, then tap ✓',
          style: const TextStyle(fontSize: 14)),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _confirmPin() async {
    final center = _mapController.camera.center;
    final address = await _reverseGeocode(center);
    _setLocation(_isSelectingPin, center, address);
    setState(() => _pinModeActive = false);
    _sheetController.animateTo(0.50,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Future<void> _openSearch(bool isPickup) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => _AddressSearchPage(currentLocation: userLocation)),
    );
    if (result != null) {
      _setLocation(isPickup, LatLng(result['lat'], result['lng']), result['address']);
    }
  }

  void _openOrderDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailsSheet(
        initialSenderName: senderName,
        initialSenderPhone: senderPhone,
        initialSenderLandmark: senderLandmark,
        initialReceiverName: receiverName,
        initialReceiverPhone: receiverPhone,
        initialReceiverLandmark: receiverLandmark,
        initialPackageDesc: packageDesc,
        initialPackageSize: packageSize,
        initialSpecialInstructions: specialInstructions,
        onSave: (data) => setState(() {
          senderName = data['senderName']!;
          senderPhone = data['senderPhone']!;
          senderLandmark = data['senderLandmark']!;
          receiverName = data['receiverName']!;
          receiverPhone = data['receiverPhone']!;
          receiverLandmark = data['receiverLandmark']!;
          packageDesc = data['packageDesc']!;
          packageSize = data['packageSize']!;
          specialInstructions = data['specialInstructions']!;
        }),
      ),
    );
  }

  void _openOfferPrice() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OfferPriceSheet(
        initialPrice: offerPrice,
        initialPayMethod: payMethod,
        initialPaidBy: paidBy,
        onSave: (price, method, by) => setState(() {
          offerPrice = price;
          payMethod = method;
          paidBy = by;
        }),
      ),
    );
  }

  // ── Print all data to console (replace with API later) ──
  void _submit()async {
    if (pickupLatLng == null || dropLatLng == null) {
      _snack('Set pickup & drop locations first'); return;
    }
    if (senderPhone.isEmpty || receiverPhone.isEmpty) {
      _snack('Please complete Order Details first'); return;
    }
    // if (packageDesc.isEmpty) {
    //   _snack('Please add package description in Order Details'); return;
    // }


    final orderData = {
      'courier_request': {
        'locations': {
          'pickup': {'address': pickupAddress, 'lat': pickupLatLng!.latitude, 'lng': pickupLatLng!.longitude},
          'drop': {'address': dropAddress, 'lat': dropLatLng!.latitude, 'lng': dropLatLng!.longitude},
          'distance_km': distanceKm,
          'duration_min': durationMin,
          'ride_type': distanceKm > 50 ? 'Intercity' : 'Inner City',
        },
        'sender': {'name': senderName, 'phone': senderPhone, 'landmark': senderLandmark},
        'receiver': {'name': receiverName, 'phone': receiverPhone, 'landmark': receiverLandmark},
        'package': {'description': packageDesc, 'size': packageSize, 'special_instructions': specialInstructions},
        'payment': {'offer_price': offerPrice, 'method': payMethod, 'paid_by': paidBy},
        'created_at': DateTime.now().toIso8601String(),
      }
    };
    await _createCourierRequest();

    if (!mounted) return;

    _showSearchingDriverSheet();

    // ── Console log (structured JSON) ──
    developer.log(
      '📦 COURIER REQUEST:\n${const JsonEncoder.withIndent('  ').convert(orderData)}',
      name: 'CreateCourierScreen',
    );
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📦  COURIER REQUEST SUBMITTED');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📍 PICKUP     : $pickupAddress');
    debugPrint('📍 DROP       : $dropAddress');
    debugPrint('📏 DISTANCE   : ${distanceKm.toStringAsFixed(2)} km');
    debugPrint('⏱️ DURATION   : ${durationMin.toStringAsFixed(0)} min');
    debugPrint('👤 SENDER     : $senderName | $senderPhone | $senderLandmark');
    debugPrint('👤 RECEIVER   : $receiverName | $receiverPhone | $receiverLandmark');
    debugPrint('📦 PACKAGE    : $packageDesc ($packageSize)');
    debugPrint('📝 NOTES      : $specialInstructions');
    debugPrint('💰 PRICE      : TJS $offerPrice | $payMethod | Paid by $paidBy');
    debugPrint('🕐 CREATED AT : ${DateTime.now().toIso8601String()}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // TODO: Uncomment when API is ready
    // await ApiService.createCourierRequest(orderData['courier_request']!);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('🎉 Courier request created!',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      backgroundColor: kPrimaryColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSearchingDriverSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return  _SearchingDriverSheet();
      },
    );
  }

  Future<void> _createCourierRequest() async {
    try {
      final token = await LocalCache.getToken();

      final body = {
        "pickup_location": pickupAddress,
        "drop_location": dropAddress,
        "distance": "${distanceKm.toStringAsFixed(2)}km",
        "time": "${durationMin.toStringAsFixed(0)} min",
        "trip_type": distanceKm > 50 ? "intercity" : "incity",
        "sender_name": senderName,
        "sender_phone": senderPhone,
        "sender_landmark": senderLandmark,
        "receiver_name": receiverName,
        "receiver_phone": receiverPhone,
        "receiver_landmark": receiverLandmark,
        "package_description": packageDesc,
        "package_size": packageSize,
        "instruction": specialInstructions,
        "suggested_price": double.tryParse(offerPrice.toString()) ?? 0,
        "payment_method": payMethod,
        "paid_by": paidBy,
        "pickup_latitude": pickupLatLng!.latitude,
        "pickup_longitude": pickupLatLng!.longitude,
      'drop_latitude' : dropLatLng!.latitude,
    'drop_longitude' : dropLatLng!.longitude,
      };

      final response = await http.post(
        Uri.parse("${App_Constructor().BaseURL}/api/courier/request/create"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["status"] == true) {
        // SUCCESS
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data["message"] ?? "Courier created successfully 🎉",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context);

      } else {
        // ❗ PROPER ERROR DISPLAY
        String errorMessage = data["message"] ?? "Something went wrong";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

    } catch (e) {
      _snack("Network error. Please try again.");
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontSize: 14)),
          behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onMapEvent: (_) { if (_pinModeActive) setState(() {}); },
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.qadampayk.app'),
              if (routePoints.isNotEmpty)
                FadeTransition(opacity: _routeFade,
                    child: PolylineLayer(polylines: [
                      Polyline(points: routePoints, strokeWidth: 5,
                          color: kPrimaryColor, borderColor: Colors.white, borderStrokeWidth: 2),
                    ])),
              if (pickupLatLng != null && !(_pinModeActive && _isSelectingPin))
                MarkerLayer(markers: [Marker(point: pickupLatLng!, width: 44, height: 56,
                    child: _MapPin(color: kPrimaryColor, label: 'P'))]),
              if (dropLatLng != null && !(_pinModeActive && !_isSelectingPin))
                MarkerLayer(markers: [Marker(point: dropLatLng!, width: 44, height: 56,
                    child: _MapPin(color: const Color(0xFF1A1A2E), label: 'D'))]),
            ],
          ),

          if (_pinModeActive)
            Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              _MapPin(color: _isSelectingPin ? kPrimaryColor : const Color(0xFF1A1A2E),
                  label: _isSelectingPin ? 'P' : 'D'),
              const SizedBox(height: 56),
            ])),

          if (_isLoadingRoute)
            Container(color: Colors.black26,
                child: const Center(child: CircularProgressIndicator(color: kPrimaryColor))),

          Positioned(right: 14, bottom: _pinModeActive ? 90 : 390,
              child: _CircleFab(icon: Icons.my_location, onTap: () {
                if (userLocation != null) _mapController.move(userLocation!, 15);
              })),
          Positioned(top: 50,left: 16, child: InkWell(onTap: (){
            Navigator.pop(context);
          },
            child: Container(decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(50),
              color: Colors.black
            ), child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Icon(Icons.arrow_back,color: Colors.white,),
            )),
          )),

          if (pickupLatLng != null && dropLatLng != null && !_pinModeActive)
            Positioned(right: 14, bottom: 445,
                child: _CircleFab(icon: Icons.swap_vert, onTap: _swapLocations)),

          if (_pinModeActive)
            Positioned(bottom: 50, left: 16, right: 16,
                child: Row(children: [
                  Expanded(child: ElevatedButton.icon(
                    onPressed: _confirmPin,
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text('Confirm Location',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: kPrimaryColor, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )),
                  const SizedBox(width: 10),
                  _CircleFab(icon: Icons.close, color: Colors.grey.shade700, onTap: () {
                    setState(() => _pinModeActive = false);
                    _sheetController.animateTo(0.50,
                        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                  }),
                ])),

          if (!_pinModeActive)
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.50,
              minChildSize: 0.12,
              maxChildSize: 0.92,
              snap: true,
              snapSizes: const [0.12, 0.50, 0.92],
              builder: (ctx, scroll) => _MainSheet(
                scrollController: scroll,
                pickupAddress: pickupAddress, dropAddress: dropAddress,
                pickupLatLng: pickupLatLng, dropLatLng: dropLatLng,
                distanceKm: distanceKm, durationMin: durationMin,
                hasRoute: routePoints.isNotEmpty,
                hasOrderDetails: senderPhone.isNotEmpty && packageDesc.isNotEmpty,
                senderName: senderName, receiverName: receiverName,
                packageDesc: packageDesc, packageSize: packageSize,
                offerPrice: offerPrice, payMethod: payMethod, paidBy: paidBy,
                onPickupSearch: () => _openSearch(true),
                onDropSearch: () => _openSearch(false),
                onPickupPin: () => _startPinMode(true),
                onDropPin: () => _startPinMode(false),
                onPickupCurrent: userLocation != null ? () async {
                  final a = await _reverseGeocode(userLocation!);
                  _setLocation(true, userLocation!, a);
                } : null,
                onDropCurrent: userLocation != null ? () async {
                  final a = await _reverseGeocode(userLocation!);
                  _setLocation(false, userLocation!, a);
                } : null,
                onOrderDetailsTap: _openOrderDetails,
                onOfferPriceTap: _openOfferPrice,
                onSubmit: _submit,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MAIN SHEET
// ─────────────────────────────────────────────
class _MainSheet extends StatelessWidget {
  final ScrollController scrollController;
  final String pickupAddress, dropAddress;
  final LatLng? pickupLatLng, dropLatLng;
  final double distanceKm, durationMin;
  final bool hasRoute, hasOrderDetails;
  final String senderName, receiverName, packageDesc, packageSize;
  final String offerPrice, payMethod, paidBy;
  final VoidCallback onPickupSearch, onDropSearch;
  final VoidCallback onPickupPin, onDropPin;
  final VoidCallback? onPickupCurrent, onDropCurrent;
  final VoidCallback onOrderDetailsTap, onOfferPriceTap, onSubmit;

  const _MainSheet({
    required this.scrollController,
    required this.pickupAddress, required this.dropAddress,
    required this.pickupLatLng, required this.dropLatLng,
    required this.distanceKm, required this.durationMin,
    required this.hasRoute, required this.hasOrderDetails,
    required this.senderName, required this.receiverName,
    required this.packageDesc, required this.packageSize,
    required this.offerPrice, required this.payMethod, required this.paidBy,
    required this.onPickupSearch, required this.onDropSearch,
    required this.onPickupPin, required this.onDropPin,
    this.onPickupCurrent, this.onDropCurrent,
    required this.onOrderDetailsTap, required this.onOfferPriceTap,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 24, offset: Offset(0, -4))],
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          Center(child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          )),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.local_shipping_outlined, color: kPrimaryColor, size: 22)),
              const SizedBox(width: 12),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Create Courier', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                Text('Fill details to place a courier request', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ]),
          ),

          // Location fields
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 22, right: 10),
                child: Column(children: [
                  Container(width: 12, height: 12,
                      decoration: const BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle)),
                  Container(width: 2, height: 38, color: Colors.grey.shade300),
                  Container(width: 12, height: 12,
                      decoration: const BoxDecoration(color: Color(0xFF1A1A2E), shape: BoxShape.circle)),
                ]),
              ),
              Expanded(child: Column(children: [
                _LocationField(label: 'Pickup', address: pickupAddress, color: kPrimaryColor,
                    isSet: pickupLatLng != null, onSearch: onPickupSearch,
                    onPin: onPickupPin, onCurrent: onPickupCurrent),
                const SizedBox(height: 10),
                _LocationField(label: 'Drop', address: dropAddress, color: const Color(0xFF1A1A2E),
                    isSet: dropLatLng != null, onSearch: onDropSearch,
                    onPin: onDropPin, onCurrent: onDropCurrent),
              ])),
            ]),
          ),

          // Route strip
          if (hasRoute) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: kPrimaryLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kPrimaryColor.withOpacity(0.15)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _RouteChip(icon: Icons.straighten, label: '${distanceKm.toStringAsFixed(1)} km'),
                  Container(width: 1, height: 20, color: kPrimaryColor.withOpacity(0.2)),
                  _RouteChip(icon: Icons.access_time, label: '${durationMin.toStringAsFixed(0)} min'),
                  Container(width: 1, height: 20, color: kPrimaryColor.withOpacity(0.2)),
                  _RouteChip(icon: distanceKm > 50 ? Icons.train : Icons.directions_car,
                      label: distanceKm > 50 ? 'Intercity' : 'Inner City'),
                ]),
              ),
            ),
          ],

          const SizedBox(height: 22),

          Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ActionCard(
                icon: hasOrderDetails ? Icons.check_circle : Icons.list_alt_outlined,
                title: 'Order Details',
                subtitle: hasOrderDetails
                    ? '${senderName.isNotEmpty ? senderName : 'sender'} → ${receiverName.isNotEmpty ? receiverName : 'receiver'} · $packageSize'
                    : 'Add contacts, package info & instructions',
                isDone: hasOrderDetails, onTap: onOrderDetailsTap,
              )),

          const SizedBox(height: 12),

          Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ActionCard(
                icon: Icons.wallet,
                title: 'Offer Price',
                subtitle: offerPrice.isNotEmpty
                    ? 'TJS $offerPrice  ·  $payMethod  ·  Paid by $paidBy'
                    : 'Set delivery price & payment preference',
                isDone: offerPrice.isNotEmpty,
                badgeLabel: offerPrice.isNotEmpty ? 'TJS $offerPrice' : null,
                onTap: onOfferPriceTap,
              )),

          const SizedBox(height: 28),

          Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: kPrimaryColor, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.check_circle_outline, size: 20),
                  SizedBox(width: 8),
                  Text('Create Request', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ]),
              )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ACTION CARD
// ─────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool isDone;
  final String? badgeLabel;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.title, required this.subtitle,
    required this.isDone, this.badgeLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDone ? kPrimaryLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDone ? kPrimaryColor.withOpacity(0.4) : Colors.grey.shade200, width: 1.5),
          boxShadow: [BoxShadow(
              color: isDone ? kPrimaryColor.withOpacity(0.06) : Colors.black.withOpacity(0.04),
              blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: isDone ? kPrimaryColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: isDone ? Colors.white : Colors.grey.shade600, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                color: isDone ? kPrimaryColor : const Color(0xFF1A1A2E))),
            const SizedBox(height: 3),
            Text(subtitle, style: TextStyle(fontSize: 12,
                color: isDone ? kPrimaryColor.withOpacity(0.8) : Colors.grey.shade500),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 8),
          if (badgeLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: kPrimaryColor, borderRadius: BorderRadius.circular(20)),
              child: Text(badgeLabel!,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            )
          else
            Icon(isDone ? Icons.edit_outlined : Icons.arrow_forward_ios,
                color: isDone ? kPrimaryColor : Colors.grey.shade400, size: 18),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ORDER DETAILS SHEET — professional, single green theme
// ─────────────────────────────────────────────
class _OrderDetailsSheet extends StatefulWidget {
  final String initialSenderName, initialSenderPhone, initialSenderLandmark;
  final String initialReceiverName, initialReceiverPhone, initialReceiverLandmark;
  final String initialPackageDesc, initialPackageSize, initialSpecialInstructions;
  final void Function(Map<String, String>) onSave;

  const _OrderDetailsSheet({
    required this.initialSenderName, required this.initialSenderPhone, required this.initialSenderLandmark,
    required this.initialReceiverName, required this.initialReceiverPhone, required this.initialReceiverLandmark,
    required this.initialPackageDesc, required this.initialPackageSize, required this.initialSpecialInstructions,
    required this.onSave,
  });

  @override
  State<_OrderDetailsSheet> createState() => _OrderDetailsSheetState();
}

class _OrderDetailsSheetState extends State<_OrderDetailsSheet> {
  late final TextEditingController _sName, _sPhone, _sLandmark;
  late final TextEditingController _rName, _rPhone, _rLandmark;
  late final TextEditingController _pkgDesc, _specialInst;
  late String _pkgSize;

  @override
  void initState() {
    super.initState();
    _sName = TextEditingController(text: widget.initialSenderName);
    _sPhone = TextEditingController(text: widget.initialSenderPhone);
    _sLandmark = TextEditingController(text: widget.initialSenderLandmark);
    _rName = TextEditingController(text: widget.initialReceiverName);
    _rPhone = TextEditingController(text: widget.initialReceiverPhone);
    _rLandmark = TextEditingController(text: widget.initialReceiverLandmark);
    _pkgDesc = TextEditingController(text: widget.initialPackageDesc);
    _specialInst = TextEditingController(text: widget.initialSpecialInstructions);
    _pkgSize = widget.initialPackageSize;
  }

  @override
  void dispose() {
    for (final c in [_sName, _sPhone, _sLandmark, _rName, _rPhone, _rLandmark, _pkgDesc, _specialInst]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_sPhone.text.trim().isEmpty || _rPhone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sender & receiver phone numbers are required'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    // if (_pkgDesc.text.trim().isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    //     content: Text('Package description is required'),
    //     behavior: SnackBarBehavior.floating,
    //   ));
    //   return;
    // }
    widget.onSave({
      'senderName': _sName.text.trim(),
      'senderPhone': _sPhone.text.trim(),
      'senderLandmark': _sLandmark.text.trim(),
      'receiverName': _rName.text.trim(),
      'receiverPhone': _rPhone.text.trim(),
      'receiverLandmark': _rLandmark.text.trim(),
      'packageDesc': _pkgDesc.text.trim(),
      'packageSize': _pkgSize,
      'specialInstructions': _specialInst.text.trim(),
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.60,
      maxChildSize: 0.95,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7F9F8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 40),
          children: [
            // Header card
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 12, 14, 18),
              child: Column(children: [
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(children: [
                  Container(padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.list_alt_outlined, color: kPrimaryColor, size: 22)),
                  const SizedBox(width: 12),
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Order Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Contacts, package & instructions', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 20, color: Colors.black54)),
                  ),
                ]),
              ]),
            ),

            const SizedBox(height: 12),

            // SENDER
            _SectionCard(label: 'Sender', icon: Icons.upload_outlined,
                child: Column(children: [
                  _FormRow(icon: Icons.person_outline, label: 'Full Name', controller: _sName,maxLines: 2,),
                  _RowDivider(),
                  _FormRow(icon: Icons.phone_outlined, label: 'Phone Number *',
                      controller: _sPhone, keyboard: TextInputType.phone,maxLines: 2),
                  _RowDivider(),
                  _FormRow(icon: Icons.location_on_outlined, label: 'Landmark / Area (optional)',
                      controller: _sLandmark,maxLines: 2),
                ])),

            const SizedBox(height: 10),

            // RECEIVER
            _SectionCard(label: 'Receiver', icon: Icons.download_outlined,
                child: Column(children: [
                  _FormRow(icon: Icons.person_outline, label: 'Full Name', controller: _rName,maxLines: 2),
                  _RowDivider(),
                  _FormRow(icon: Icons.phone_outlined, label: 'Phone Number *',
                      controller: _rPhone, keyboard: TextInputType.phone,maxLines: 2),
                  _RowDivider(),
                  _FormRow(icon: Icons.location_on_outlined, label: 'Landmark / Area (optional)',
                      controller: _rLandmark,maxLines: 2),
                ])),

            const SizedBox(height: 10),

            // PACKAGE
            _SectionCard(label: 'Package', icon: Icons.inventory_2_outlined,
                child: Column(children: [
                  // _FormRow(icon: Icons.edit_note_outlined, label: 'Package description *',
                  //     controller: _pkgDesc, maxLines: 3),
                  // _RowDivider(),
                  // Size selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.straighten_outlined, size: 17, color: kPrimaryColor),
                        const SizedBox(width: 8),
                        Text('Package Size', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                      ]),
                      const SizedBox(height: 12),
                      StatefulBuilder(builder: (_, setS) {
                        final sizes = [
                          {'label': 'small', 'icon': Icons.inventory, 'desc': '< 2 kg'},
                          {'label': 'medium', 'icon': Icons.inventory_2, 'desc': '2–10 kg'},
                          {'label': 'large', 'icon': Icons.luggage, 'desc': '> 10 kg'},
                        ];
                        return Row(children: sizes.map((s) {
                          final sel = _pkgSize == s['label'];
                          return Expanded(child: GestureDetector(
                            onTap: () => setS(() => _pkgSize = s['label'] as String),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: EdgeInsets.only(right: s['label'] != 'Large' ? 8 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: sel ? kPrimaryColor : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: sel ? kPrimaryColor : Colors.grey.shade200, width: sel ? 2 : 1),
                              ),
                              child: Column(children: [
                                Icon(s['icon'] as IconData, size: 22, color: sel ? Colors.white : Colors.grey.shade400),
                                const SizedBox(height: 5),
                                Text(s['label'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                                    color: sel ? Colors.white : Colors.grey.shade700)),
                                const SizedBox(height: 2),
                                Text(s['desc'] as String, style: TextStyle(fontSize: 10,
                                    color: sel ? Colors.white60 : Colors.grey.shade400)),
                              ]),
                            ),
                          ));
                        }).toList());
                      }),
                    ]),
                  ),
                  _RowDivider(),
                  _FormRow(icon: Icons.note_alt_outlined, label: 'Special instructions (optional)',
                      controller: _specialInst, maxLines: 2),
                ])),

            const SizedBox(height: 24),

            Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: kPrimaryColor, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Save Order Details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                )),
            SizedBox(height: 16,),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;
  const _SectionCard({required this.label, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(children: [
            Container(width: 3, height: 16,
                decoration: BoxDecoration(color: kPrimaryColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Icon(icon, size: 15, color: kPrimaryColor),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kPrimaryColor)),
          ]),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
        ),
      ]),
    );
  }
}

// Each field: label on top, input below — name & phone in separate rows
class _FormRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final TextInputType keyboard;
  final int maxLines;

  const _FormRow({required this.icon, required this.label, required this.controller,
    this.keyboard = TextInputType.text, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 18, color: kPrimaryColor)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: Colors.grey.shade400, letterSpacing: 0.3)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboard,
            // maxLines: maxLines,
            // minLines: maxLines > 1 ? maxLines : 1,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A2E),
            ),
            decoration: InputDecoration(
              isDense: true, // 👈 makes field compact
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16, // 👈 smaller height
              ),
              hintText: 'Enter here...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8), // 👈 smaller radius
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: kPrimaryColor,
                  width: 1.2,
                ),
              ),
            ),
          )        ])),
      ]),
    );
  }
}

class _RowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 48),
    child: Divider(height: 1, color: Colors.grey.shade100),
  );
}

// ─────────────────────────────────────────────
// OFFER PRICE SHEET — professional, green theme, phone keyboard
// ─────────────────────────────────────────────
class _OfferPriceSheet extends StatefulWidget {
  final String initialPrice, initialPayMethod, initialPaidBy;
  final void Function(String price, String method, String by) onSave;

  const _OfferPriceSheet({required this.initialPrice, required this.initialPayMethod,
    required this.initialPaidBy, required this.onSave});

  @override
  State<_OfferPriceSheet> createState() => _OfferPriceSheetState();
}

class _OfferPriceSheetState extends State<_OfferPriceSheet> {
  late final TextEditingController _priceCtrl;
  late String _payMethod, _paidBy;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(text: widget.initialPrice == '0' ? '' : widget.initialPrice);
    _payMethod = widget.initialPayMethod;
    _paidBy = widget.initialPaidBy;
    // Open phone keyboard on sheet open
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _save() {
    final price = _priceCtrl.text.trim();
    widget.onSave(price.isEmpty ? '0' : price, _payMethod, _paidBy);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 18, 0),
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.currency_rupee_rounded,
                    color: kPrimaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offer Price',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Set amount, payment method & payer',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.close, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Big price input (phone keyboard) ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                /// Currency
                const Text(
                  "TJS", // change to TJS if needed
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(width: 6),

                /// Price Input
                IntrinsicWidth(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      inputDecorationTheme: const InputDecorationTheme(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                    child: TextField(
                      controller: _priceCtrl,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.left,
                      cursorColor: Colors.black,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                      decoration: const InputDecoration(
                        filled: false,
                        fillColor: Colors.transparent,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: "0",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Payment Method ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionLabel(icon: Icons.payment_outlined, text: 'Payment Method'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _PayChip(label: 'cash', icon: Icons.money_outlined,
                    selected: _payMethod == 'cash', onTap: () => setState(() => _payMethod = 'cash'))),
                const SizedBox(width: 10),
                // Expanded(child: _PayChip(label: 'Online', icon: Icons.phone_android_outlined,
                //     selected: _payMethod == 'Online', onTap: () => setState(() => _payMethod = 'Online'))),
                // const SizedBox(width: 10),
                Expanded(child: _PayChip(label: 'card', icon: Icons.credit_card_outlined,
                    selected: _payMethod == 'card', onTap: () => setState(() => _payMethod = 'card'))),
              ]),
            ]),
          ),

          const SizedBox(height: 18),

          // ── Paid By ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionLabel(icon: Icons.person_outline, text: 'Paid By'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _PaidByChip(label: 'Sender', sublabel: 'Pays at pickup',
                    icon: Icons.upload_outlined, selected: _paidBy == 'sender',
                    onTap: () => setState(() => _paidBy = 'sender'))),
                const SizedBox(width: 10),
                Expanded(child: _PaidByChip(label: 'Receiver', sublabel: 'Pays on delivery',
                    icon: Icons.download_outlined, selected: _paidBy == 'receiver',
                    onTap: () => setState(() => _paidBy = 'receiver'))),
              ]),
            ]),
          ),

          const SizedBox(height: 22),

          // Confirm button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: kPrimaryColor, foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.check_circle_outline, size: 20),
                const SizedBox(width: 8),
                Text(
                  _priceCtrl.text.isEmpty ? 'Confirm Price' : 'Confirm  TJS ${_priceCtrl.text}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 16, color: kPrimaryColor),
    const SizedBox(width: 6),
    Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
  ]);
}

class _PayChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _PayChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected ? kPrimaryColor : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? kPrimaryColor : Colors.grey.shade200, width: selected ? 2 : 1),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 22, color: selected ? Colors.white : Colors.grey.shade400),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.grey.shade600)),
      ]),
    ),
  );
}

class _PaidByChip extends StatelessWidget {
  final String label, sublabel;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _PaidByChip({required this.label, required this.sublabel, required this.icon,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: selected ? kPrimaryColor : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? kPrimaryColor : Colors.grey.shade200, width: selected ? 2 : 1),
      ),
      child: Row(children: [
        Icon(icon, size: 20, color: selected ? Colors.white : Colors.grey.shade400),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
              color: selected ? Colors.white : const Color(0xFF1A1A2E))),
          Text(sublabel, style: TextStyle(fontSize: 10,
              color: selected ? Colors.white60 : Colors.grey.shade400)),
        ]),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────
// ADDRESS SEARCH PAGE
// ─────────────────────────────────────────────
class _AddressSearchPage extends StatefulWidget {
  final LatLng? currentLocation;
  const _AddressSearchPage({this.currentLocation});
  @override
  State<_AddressSearchPage> createState() => _AddressSearchPageState();
}

class _AddressSearchPageState extends State<_AddressSearchPage> {
  final _ctrl = TextEditingController();
  List _results = [];
  List<Map<String, dynamic>> _recent = [];
  bool _loading = false;

  @override
  void initState() { super.initState(); _loadRecent(); }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('recent_locations') ?? [];
    setState(() { _recent = raw.map((e) => json.decode(e) as Map<String, dynamic>).toList(); });
  }

  Future<void> _saveRecent(Map<String, dynamic> loc) async {
    final prefs = await SharedPreferences.getInstance();
    _recent.removeWhere((e) => e['address'] == loc['address']);
    _recent.insert(0, loc);
    if (_recent.length > 5) _recent = _recent.sublist(0, 5);
    await prefs.setStringList('recent_locations', _recent.map((e) => json.encode(e)).toList());
  }

  Future<void> _search(String q) async {
    if (q.length < 3) { setState(() => _results = []); return; }
    setState(() => _loading = true);
    try {
      var url = 'https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=10';
      if (widget.currentLocation != null) {
        url += '&lat=${widget.currentLocation!.latitude}&lon=${widget.currentLocation!.longitude}';
      }
      final res = await http.get(Uri.parse(url), headers: {'User-Agent': 'com.qadampayk.app'});
      if (res.statusCode == 200) setState(() => _results = json.decode(res.body));
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _pick(Map<String, dynamic> loc) { _saveRecent(loc); Navigator.pop(context, loc); }

  @override
  Widget build(BuildContext context) {
    final showRecent = _ctrl.text.length < 3;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Select Location',
            style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.bold)),
      ),
      body: Column(children: [

        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: TextField(
            controller: _ctrl, autofocus: true,
            style: const TextStyle(fontSize: 15),
            onChanged: _search,
            decoration: InputDecoration(
              hintText: 'Search location...',
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.search, color: kPrimaryColor, size: 22),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 20),
                  onPressed: () { _ctrl.clear(); setState(() => _results = []); })
                  : null,
              filled: true, fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            ),
          ),
        ),
        if (_loading) const Padding(padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 3)),
        Expanded(child: Builder(builder: (_) {
          if (showRecent) {
            if (_recent.isEmpty) return _empty(Icons.location_searching, 'Search for a location', 'Enter address or place name');
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Recent', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
                  TextButton(
                    onPressed: () async {
                      final p = await SharedPreferences.getInstance();
                      await p.remove('recent_locations');
                      setState(() => _recent = []);
                    },
                    child: const Text('Clear', style: TextStyle(fontSize: 13, color: kPrimaryColor)),
                  ),
                ]),
              ),
              Expanded(child: ListView.builder(
                padding: EdgeInsets.zero, itemCount: _recent.length,
                itemBuilder: (_, i) => _tile(_recent[i]['address'] ?? '', Icons.history, () => _pick(_recent[i])),
              )),
            ]);
          }
          if (!_loading && _results.isEmpty) return _empty(Icons.search_off, 'No results found', 'Try a different search term');
          return ListView.builder(
            padding: EdgeInsets.zero, itemCount: _results.length,
            itemBuilder: (_, i) {
              final p = _results[i];
              return _tile(p['display_name'], Icons.location_on, () => _pick({
                'lat': double.parse(p['lat']), 'lng': double.parse(p['lon']), 'address': p['display_name'],
              }));
            },
          );
        })),
      ]),
    );
  }

  Widget _tile(String address, IconData icon, VoidCallback onTap) {
    final parts = address.split(',');
    return InkWell(onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 0.8))),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: kPrimaryColor, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(parts[0].trim(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            if (parts.length > 1) ...[
              const SizedBox(height: 2),
              Text(parts.sublist(1).join(',').trim(),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ])),
          Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
        ]),
      ),
    );
  }

  Widget _empty(IconData icon, String title, String sub) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 56, color: Colors.grey.shade300),
      const SizedBox(height: 14),
      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
      const SizedBox(height: 5),
      Text(sub, style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
    ],
  ));

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
}

// ─────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────
class _LocationField extends StatelessWidget {
  final String label, address;
  final Color color;
  final bool isSet;
  final VoidCallback onSearch, onPin;
  final VoidCallback? onCurrent;

  const _LocationField({required this.label, required this.address, required this.color,
    required this.isSet, required this.onSearch, required this.onPin, this.onCurrent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSet ? kPrimaryLight.withOpacity(0.5) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isSet ? kPrimaryColor.withOpacity(0.4) : Colors.grey.shade200, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          onTap: onSearch,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                    color: isSet ? kPrimaryColor : Colors.grey.shade500, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(
                  isSet ? address : 'Tap to search or use options below',
                  style: TextStyle(fontSize: 13,
                      color: isSet ? const Color(0xFF1A1A2E) : Colors.grey.shade400,
                      fontWeight: isSet ? FontWeight.w500 : FontWeight.normal),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ])),
              Icon(Icons.search, color: isSet ? kPrimaryColor : Colors.grey.shade400, size: 20),
            ]),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: isSet ? kPrimaryColor.withOpacity(0.15) : Colors.grey.shade200)),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
          ),
          child: Row(children: [
            _QuickAction(icon: Icons.push_pin_outlined, label: 'Pin on Map', onTap: onPin),
            if (onCurrent != null) ...[
              Container(width: 1, height: 28, color: Colors.grey.shade200),
              _QuickAction(icon: Icons.my_location, label: 'My Location', onTap: onCurrent!),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(children: [
        Icon(icon, size: 14, color: kPrimaryColor),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: kPrimaryColor, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _MapPin extends StatelessWidget {
  final Color color;
  final String label;
  const _MapPin({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Container(
      width: 38, height: 38,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))]),
      child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
    ),
    CustomPaint(size: const Size(12, 16), painter: _PinTailPainter(color)),
  ]);
}

class _PinTailPainter extends CustomPainter {
  final Color color;
  _PinTailPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = ui.Path()..moveTo(size.width / 2, size.height)..lineTo(0, 0)..lineTo(size.width, 0)..close();
    canvas.drawShadow(path, Colors.black38, 3, true);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _CircleFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _CircleFab({required this.icon, required this.onTap, this.color = kPrimaryColor});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 44, height: 44,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Icon(icon, color: color, size: 22)),
  );
}

class _RouteChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _RouteChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, color: kPrimaryColor, size: 16),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kPrimaryColor)),
  ]);
}


class _SearchingDriverSheet extends StatefulWidget {
  const _SearchingDriverSheet();

  @override
  State<_SearchingDriverSheet> createState() => _SearchingDriverSheetState();
}

class _SearchingDriverSheetState extends State<_SearchingDriverSheet>
    with TickerProviderStateMixin {

  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _dotController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  void _goToListScreen() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderListScreen(isDriverMode: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF3FFF8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            /// Drag Handle
            Container(
              height: 5,
              width: 70,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 30),

            /// Animated Truck With Glow + Rotation
            Stack(
              alignment: Alignment.center,
              children: [

                /// Rotating Glow Ring
                RotationTransition(
                  turns: _rotateController,
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Colors.green.withOpacity(0.1),
                          Colors.green,
                          Colors.green.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ),

                /// Pulsing Truck
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          size: 45,
                          color: Color(0xFF008955),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 25),

            /// Title
            const Text(
              "Searching Best Driver",
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            /// Animated Dots
            AnimatedBuilder(
              animation: _dotController,
              builder: (context, child) {
                int dotCount =
                    (_dotController.value * 3).floor() + 1;
                String dots = '.' * dotCount;

                return Text(
                  "Finding nearby drivers$dots",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                );
              },
            ),

            const SizedBox(height: 25),

            /// Modern Progress Indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const LinearProgressIndicator(
                minHeight: 6,
                color: Color(0xFF008955),
                backgroundColor: Color(0xFFE0F5EA),
              ),
            ),

            const SizedBox(height: 35),

            /// View Details Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _goToListScreen,
                style: ElevatedButton.styleFrom(
                  elevation: 3,
                  backgroundColor: const Color(0xFF008955),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "View Request Details",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}