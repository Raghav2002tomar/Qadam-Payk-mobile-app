import 'dart:convert';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../providers/translate_provider.dart';
import '../../../service/colors.dart';
import '../../../service/local_cache.dart';
import '../create/OrderDetailScreen.dart';
import 'RideDetailScreen.dart';
import 'model/passenger_request_model.dart';

class RideStatusScreen extends StatefulWidget {
  const RideStatusScreen({super.key});

  @override
  State<RideStatusScreen> createState() => _RideStatusScreenState();
}

class _RideStatusScreenState extends State<RideStatusScreen>
    with TickerProviderStateMixin {
  late TabController _parentTabController;
  late TabController _requestChildTabController;
  late TabController _bookingChildTabController;

  List<PassengerRequest> _requests = [];
  List<PassengerRequest> _bookings = [];
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
        Uri.parse('https://qadampayk.com/api/get-current-passenger-requests'),
        headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            _requests = (data['data'] as List)
                .map((e) => PassengerRequest.fromJson(e))
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
        Uri.parse('https://qadampayk.com/api/get-drivers-booking'),
        headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            _bookings = (data['data'] as List)
                .map((e) => PassengerRequest.fromJson(e))
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title:  Text("${translate.t('txt_rides_and_bookings')}"),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.transparent, // Background behind tabs
                borderRadius: BorderRadius.circular(30),
              ),
              child: TabBar(
                controller: _parentTabController,
                indicator: BoxDecoration(
                  color: AppTheme.seedPrimary, // Selected tab background
                  borderRadius: BorderRadius.circular(30), // Pill-shaped
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                labelPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 1), // Extra gap
                tabs:  [
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
            _buildChildTabView(_requestChildTabController, _requests, _isLoadingRequests , translate),
            _buildChildTabView(_bookingChildTabController, _bookings, _isLoadingBookings, translate),
          ],
        ),
      ),
    );
  }


  Widget _buildChildTabView(TabController tabController, List<PassengerRequest> list, bool isLoading, TranslateProvider translate) {
    return Column(
      children: [
       TabBar(
          controller: tabController,
          indicator: BoxDecoration(
            color: AppTheme.seedPrimary, // Background color for selected tab
            borderRadius: BorderRadius.circular(20), // Pill shape
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          labelColor: Colors.white, // Selected tab text color
          unselectedLabelColor: Colors.grey.shade500, // Unselected tab text color
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          tabs:  [
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
              _buildRideListByStatus(list, "completed",translate),
              _buildRideListByStatus(list, "cancelled",translate),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRideListByStatus(List<PassengerRequest> list, String status, TranslateProvider translate) {
    final filtered = list.where((r) {
      switch (status) {
        case "pending":
          return r.status == "pending" || r.status == "active" || r.status == "confirmed";
        case "completed":
          return r.status == "completed";
        case "cancelled":
          return r.status == "cancelled";
        default:
          return false;
      }
    }).toList();

    if (filtered.isEmpty) {
      // Translate status
      String translatedStatus;
      switch (status) {
        case "pending":
          translatedStatus = translate.t('txt_pending');
          break;
        case "completed":
          translatedStatus = translate.t('txt_completed');
          break;
        case "cancelled":
          translatedStatus = translate.t('txt_cancelled');
          break;
        default:
          translatedStatus = status;
      }

      return Center(
        child: Text(translate.t('txt_no_ride_details', )),
      );
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

// ------------------- Passenger Ride Card -------------------

class PassengerRideCard extends StatelessWidget {
  final PassengerRequest ride;
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
              builder: (_) => RideDetailScreen(rideId: ride.id),
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
                // Header with status
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
                _buildRouteVisualization(ride),
                const SizedBox(height: 16),
                const _RideDivider(),
                const SizedBox(height: 16),
                _buildTripDetailsGrid(ride,  translate),
                if (ride.services.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const _RideDivider(),
                  const SizedBox(height: 12),
                  _buildServicesSection(ride.services,translate ),
                ],
                if (ride.type == 1 && (ride.parcelDetails?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 16),
                  const _RideDivider(),
                  const SizedBox(height: 12),
                  _buildParcelSection(ride, translate),
                ],
                if (_hasContactInfo(ride)) ...[
                  const SizedBox(height: 16),
                  const _RideDivider(),
                  const SizedBox(height: 12),
                  _buildContactSection(ride,translate),
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

  Widget _buildRouteVisualization(PassengerRequest ride) {
    return Container(
      height: 80,
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                "assets/images/red_icon.svg",
                height: 15,
              ),
              const SizedBox(height: 4),
              const DottedLine(
                dashLength: 3,
                dashGapLength: 3,
                lineThickness: 2,
                dashColor: Colors.grey,
                direction: Axis.vertical,
                lineLength: 35,
              ),
              const SizedBox(height: 4),
              SvgPicture.asset(
                "assets/images/blue_icon.svg",
                height: 15,
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride.pickupLocation,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Text(
                  ride.destination,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetailsGrid(PassengerRequest ride, TranslateProvider translate) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(Icons.event, "${translate.t('txt_date')}", ride.rideDate ?? "N/A"),
            ),
            if (ride.rideTime != null)
              Expanded(
                child: _buildDetailItem(Icons.access_time, "${translate.t('txt_ride_status_time')}", ride.rideTime!),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(Icons.event_seat, "${translate.t('txt_ride_status_seats')}", "${ride.numberOfSeats}"),
            ),
            if (ride.budget != null && ride.budget!.isNotEmpty)
              Expanded(
                child: _buildDetailItem(null,"${translate.t('txt_ride_status_budget')} c", ride.budget!,
                    valueColor: AppTheme.seedPrimary),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailItem(
      IconData? icon,
      String label,
      String value, {
        Color? valueColor,
      }) {
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

  Widget _buildServicesSection(List<dynamic> services, TranslateProvider translate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.miscellaneous_services, color: AppTheme.seedPrimary, size: 18),
            const SizedBox(width: 8),
             Text(
              "${translate.t('txt_ride_status_services')}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: services.map((service) {
            String? serviceImage;
            if (service is Map && service['serviceImage'] != null) {
              serviceImage = service['serviceImage'];
            } else if (service.serviceImage != null) {
              serviceImage = service.serviceImage;
            }
            return serviceImage != null && serviceImage.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: SvgPicture.network(
                "https://qadampayk.com/assets/services_images/$serviceImage",
                width: 25,
                height: 25,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.miscellaneous_services, size: 20, color: Colors.grey);
                },
              ),
            )
                : const Icon(Icons.miscellaneous_services, size: 20, color: Colors.grey);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildParcelSection(PassengerRequest ride, TranslateProvider translate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_shipping, color: AppTheme.seedPrimary, size: 18),
            const SizedBox(width: 8),
             Text(
              "${translate.t('txt_parcel_information')}",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            ride.parcelDetails ?? '',
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection(PassengerRequest ride, TranslateProvider translate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.contacts, color: AppTheme.seedPrimary, size: 18),
            const SizedBox(width: 8),
             Text(
              "${translate.t('txt_contact_information')}",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ride.pickupContactName != null)
                _buildContactRow(Icons.person, "${translate.t('txt_pickup_contact')}", ride.pickupContactName!),
              if (ride.dropContactName != null) ...[
                if (ride.pickupContactName != null) const SizedBox(height: 8),
                _buildContactRow(Icons.person, "${translate.t('txt_drop_contact')}", ride.dropContactName!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.grey),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  bool _hasContactInfo(PassengerRequest ride) {
    return ride.pickupContactName != null ||
        ride.pickupContactNo != null ||
        ride.dropContactName != null ||
        ride.dropContactNo != null;
  }
}

// ----------------- Reusable Divider -----------------
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
        final dashCount = (constraints.maxWidth / (dashWidth + dashSpacing)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
                (_) => Container(width: dashWidth, height: height, color: color.withOpacity(0.4)),
          ),
        );
      },
    );
  }
}
