import 'dart:convert';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../providers/translate_provider.dart';
import '../../../service/colors.dart';
import '../../../service/local_cache.dart';
import 'InterestedPassengersScreen.dart';
import 'RideDetailScreen.dart';

// ---------------- MAIN SCREEN ----------------
class DriverRideStatusScreen extends StatefulWidget {
  const DriverRideStatusScreen({super.key});

  @override
  State<DriverRideStatusScreen> createState() => _DriverRideStatusScreenState();
}

class _DriverRideStatusScreenState extends State<DriverRideStatusScreen>
    with TickerProviderStateMixin {
  late TabController _parentTabController;
  late TabController _requestChildTabController;
  late TabController _bookingChildTabController;

  List<DriverRide> _requests = [];
  List<DriverRide> _bookings = [];

  bool _isLoadingRequests = false;
  bool _isLoadingBookings = false;

  @override
  void initState() {
    super.initState();
    _parentTabController = TabController(length: 2, vsync: this);
    _requestChildTabController = TabController(length: 3, vsync: this);
    _bookingChildTabController = TabController(length: 3, vsync: this);

    fetchPassengerRequests();
    fetchBookingRequests();
  }

  Future<void> fetchPassengerRequests() async {
    setState(() => _isLoadingRequests = true);
    final token = await LocalCache.getToken();
    try {
      final response = await http.get(
        Uri.parse('https://qadampayk.com/api/get-all-rides-createdByDriver'),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json"
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            _requests = (data['data'] as List)
                .map((e) => DriverRide.fromJson(e))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Exception: $e");
    }
    setState(() => _isLoadingRequests = false);
  }

  Future<void> fetchBookingRequests() async {
    setState(() => _isLoadingBookings = true);
    final token = await LocalCache.getToken();
    try {
      final response = await http.get(
        Uri.parse('https://qadampayk.com/api/get-passengers-booking-requests'),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json"
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            _bookings = (data['data'] as List)
                .map((e) => DriverRide.fromJson(e))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Exception: $e");
    }
    setState(() => _isLoadingBookings = false);
  }

  @override
  void dispose() {
    _parentTabController.dispose();
    _requestChildTabController.dispose();
    _bookingChildTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translate = context.watch<TranslateProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("${translate.t('txt_rides_and_bookings')}"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TabBar(
              controller: _parentTabController,
              indicator: BoxDecoration(
                color: AppTheme.seedPrimary,
                borderRadius: BorderRadius.circular(30),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: "${translate.t('txt_my_requests')}"),
                Tab(text: "${translate.t('txt_my_bookings')}"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _parentTabController,
        children: [
          _buildChildTabView(
              _requestChildTabController, _requests, _isLoadingRequests, translate),
          _buildChildTabView(
              _bookingChildTabController, _bookings, _isLoadingBookings, translate),
        ],
      ),
    );
  }

  Widget _buildChildTabView(
      TabController tabController,
      List<DriverRide> list,
      bool isLoading,
      TranslateProvider translate) {
    return Column(
      children: [
        TabBar(
          controller: tabController,
          indicator: BoxDecoration(
            color: AppTheme.seedPrimary,
            borderRadius: BorderRadius.circular(20),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade500,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: '${translate.t('txt_pending')}'),
            Tab(text: '${translate.t('txt_completed')}'),
            Tab(text: '${translate.t('txt_cancelled')}'),
          ],
          onTap: (index) => setState(() => tabController.index = index),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
            controller: tabController,
            children: [
              _buildRideListByStatus(list, "pending", translate),
              _buildRideListByStatus(list, "completed", translate),
              _buildRideListByStatus(list, "cancelled", translate),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRideListByStatus(
      List<DriverRide> list, String status, TranslateProvider translate) {
    final filtered = list.where((r) {
      switch (status) {
        case "pending":
          return r.status == "pending" ||
              r.status == "active" ||
              r.status == "confirmed";
        case "completed":
          return r.status == "completed";
        case "cancelled":
          return r.status == "cancelled";
        default:
          return false;
      }
    }).toList();

    if (filtered.isEmpty) {
      return Center(child: Text("${translate.t('txt_no_ride_details')}"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return PassengerRideCard(ride: filtered[index]);
      },
    );
  }
}

// ----------------- RIDE CARD -----------------
class PassengerRideCard extends StatelessWidget {
  final DriverRide ride;
  const PassengerRideCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final translate = context.watch<TranslateProvider>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InterestedPassengersScreen(rideId: ride.id),
            ),
          );
        },
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 2,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${ride.pickupLocation} → ${ride.destination}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    _buildStatusBadge(ride.status, translate),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTripDetailsGrid(ride, translate),
                if (ride.services.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const _RideDivider(),
                  const SizedBox(height: 12),
                  // _buildServicesSection(ride.services),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, TranslateProvider translate) {
    Color backgroundColor;
    Color textColor;
    String displayStatus = status;
    switch (status) {
      case 'completed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        displayStatus = "${translate.t('txt_completed')}";
        break;
      case 'cancelled':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        displayStatus = "${translate.t('txt_cancelled')}";
        break;
      case 'confirmed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        displayStatus = "${translate.t('txt_confirm')}";
        break;
      default:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        displayStatus = "${translate.t('txt_pending')}";
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildTripDetailsGrid(DriverRide ride, TranslateProvider translate) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                  Icons.event, "${translate.t('txt_date')}", ride.rideDate ?? "N/A"),
            ),
            if (ride.rideTime != null)
              Expanded(
                child: _buildDetailItem(Icons.access_time,
                    "${translate.t('txt_ride_status_time')}", ride.rideTime!),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(Icons.event_seat,
                  "${translate.t('txt_ride_status_seats')}", "${ride.numberOfSeats}"),
            ),
            if (ride.price != null && ride.price!.isNotEmpty)
              Expanded(
                child: _buildDetailItem(null,
                    "${translate.t('txt_ride_status_budget')} c", ride.price!,
                    valueColor: AppTheme.seedPrimary),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData? icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
        ],
        Text(
          "$label: ",
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection(List<RideService> services) {
    return Wrap(
      spacing: 8,
      children: services.map((s) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (s.serviceImage.isNotEmpty)
              Image.network("https://qadampayk.com/assets/services_images/${s.serviceImage}", height: 20, width: 20),
            const SizedBox(width: 4),
            Text(s.name),
          ],
        );
      }).toList(),
    );
  }
}

// ----------------- RIDE DIVIDER -----------------
class _RideDivider extends StatelessWidget {
  final double height;
  final double dashWidth;
  final double dashSpacing;
  final Color color;

  const _RideDivider({
    super.key,
    this.height = 1,
    this.dashWidth = 4,
    this.dashSpacing = 4,
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount =
        (constraints.maxWidth / (dashWidth + dashSpacing)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
                (_) =>
                Container(width: dashWidth, height: height, color: color.withOpacity(0.4)),
          ),
        );
      },
    );
  }
}

// ----------------- MODELS -----------------
class DriverRide {
  final int id;
  final String pickupLocation;
  final String destination;
  final String? rideDate;
  final String? rideTime;
  final int numberOfSeats;
  final String? price;
  final String status;
  final List<RideService> services;

  DriverRide({
    required this.id,
    required this.pickupLocation,
    required this.destination,
    this.rideDate,
    this.rideTime,
    required this.numberOfSeats,
    this.price,
    required this.status,
    this.services = const [],
  });

  factory DriverRide.fromJson(Map<String, dynamic> json) {
    return DriverRide(
      id: json['id'] ?? 0,
      pickupLocation: json['pickup_location'] ?? '',
      destination: json['destination'] ?? '',
      rideDate: json['ride_date'],
      rideTime: json['ride_time'],
      numberOfSeats: json['number_of_seats'] ?? 0,
      price: json['price']?.toString(),
      status: json['status'] ?? "pending",
      services: (json['services'] as List? ?? [])
          .map((e) => RideService.fromJson(e))
          .toList(),
    );
  }
}

class RideService {
  final String serviceImage;
  final String name;

  RideService({required this.serviceImage, required this.name});

  factory RideService.fromJson(Map<String, dynamic> json) {
    return RideService(
      serviceImage: json['service_image'] ?? '',
      name: json['name'] ?? '',
    );
  }
}
