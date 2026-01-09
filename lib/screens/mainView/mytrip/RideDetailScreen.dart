import 'dart:convert';
import 'package:bla_bla_car/providers/translate_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:dotted_line/dotted_line.dart';
import 'package:provider/provider.dart';
import '../../../api_service/logger.dart';
import '../../../service/colors.dart';
import '../../../service/local_cache.dart';
import '../create/DriverProfileScreen.dart';

class RideDetailScreen extends StatefulWidget {
  final int rideId; // 👈 pass from previous screen

  const RideDetailScreen({super.key, required this.rideId});

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  bool _isLoading = false;
  List<dynamic> _drivers = [];
  Map<String, dynamic>? _rideInfo;

  @override
  void initState() {
    super.initState();
    fetchInterestedDrivers();
  }

  Future<void> fetchInterestedDrivers() async {
    setState(() => _isLoading = true);
    final token = await LocalCache.getToken();

    try {
      final response = await http.get(
        Uri.parse("https://qadampayk.com/api/get-interested-drivers-list/${widget.rideId}"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      appLog("Ride Detail API Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        appLog("🔍 Full API Response: ${response.body}"); // Debug full response

        if (data["status"] == true) {
          setState(() {
            _drivers = data["data"];
            _rideInfo = data["ride"] ?? {}; // 👈 use dedicated ride info if API has one
          });

          // 🔍 Debug each driver data
          for (int i = 0; i < _drivers.length; i++) {
            appLog("🚗 Driver $i: ${_drivers[i]}");
            appLog("📱 Driver $i ID fields: driver_id=${_drivers[i]['driver_id']}, user_id=${_drivers[i]['user_id']}, name=${_drivers[i]['name']}");
          }
        }
      }
    } catch (e) {
      appLog("❌ Ride Detail API Error: $e");
    }

    setState(() => _isLoading = false);
  }

  Future<void> respondToDriver({
    required BuildContext context, // ✅ pass context
    required String requestId,
    required String driverId,
    String status = "confirmed",
  }) async {
    final token = await LocalCache.getToken(); // Get your saved token
    final uri = Uri.parse("https://qadampayk.com/api/request/respond-driver");

    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add text fields
      request.fields['request_id'] = requestId;
      request.fields['driver_id'] = driverId;
      request.fields['status'] = status;

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      appLog("📤 Response Status: ${response.statusCode}");
      appLog("📥 Response Body: ${response.body}");

      final data = json.decode(response.body);

      // ✅ Show toast for all API messages
      String message = data['message'] ?? "No message from API";

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['status'] == true) {
          Fluttertoast.showToast(
            msg: message,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          // Go back to previous screen
          Navigator.of(context).pop();
        } else {
          Fluttertoast.showToast(
            msg: message,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: "HTTP Error ${response.statusCode}: $message",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Exception: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }


  // 🔧 Helper method to get the correct driver ID
  int getDriverId(Map<String, dynamic> driver) {
    // Based on your API response, driver_id is the correct unique identifier
    if (driver['driver_id'] != null) {
      return int.tryParse(driver['driver_id'].toString()) ?? 0;
    } else {
      appLog("⚠️ Warning: No driver_id found in driver data: $driver");
      return 0; // fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(context.watch<TranslateProvider>().t('txt_ride_details')),
        backgroundColor: AppTheme.seedPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rideInfo == null
          ? _buildEmptyState()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // _buildRideSummaryCard(),
            const SizedBox(height: 20),
            Text(
              context.watch<TranslateProvider>().t('txt_interested_drivers'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            _drivers.isEmpty
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Text(
                  context.watch<TranslateProvider>().t('txt_no_drivers_found'),
                  style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  context.watch<TranslateProvider>().t('txt_refresh_list'),
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    // Refresh or retry logic
                    Navigator.pop(context);
                  },
                  child: Text(context.watch<TranslateProvider>().t('txt_retry')),
                ),
                // Add any other content here
              ],
            )
                : Column(
              children: _drivers.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> driver = entry.value;
                return _buildDriverCard(driver, index);
              }).toList(),
            ),


          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            context.watch<TranslateProvider>().t('txt_no_ride_details'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.watch<TranslateProvider>().t('txt_please_try_again'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideSummaryCard() {
    return Card(
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
            // Header with route
            Row(
              children: [
                const Icon(Icons.route, color: AppTheme.seedPrimary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${_rideInfo!['pickup_location']} → ${_rideInfo!['destination']}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Route visualization
            _buildRouteVisualization(),

            const SizedBox(height: 16),
            const _RideDivider(),
            const SizedBox(height: 16),

            // Trip details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Icons.event,
                    context.watch<TranslateProvider>().t('txt_date'),
                    _rideInfo!['ride_date'] ?? 'N/A',
                  ),
                ),
                if (_rideInfo!['ride_time'] != null)
                  Expanded(
                    child: _buildDetailItem(
                      Icons.access_time,
                      context.watch<TranslateProvider>().t('txt_ride_status_time'),
                      _rideInfo!['ride_time'],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Icons.event_seat,
                    context.watch<TranslateProvider>().t('txt_ride_status_seats'),
                    "${_rideInfo!['number_of_seats'] ?? 'N/A'}",
                  ),
                ),
                if (_rideInfo!['price'] != null)
                  Expanded(
                    child: _buildDetailItem(
                      Icons.attach_money,
                      context.watch<TranslateProvider>().t('txt_price'),
                      "c ${_rideInfo!['price']}",
                      valueColor: AppTheme.seedPrimary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteVisualization() {
    return Container(
      height: 80,
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                "assets/images/blue_icon.svg",
                height: 16,
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
                "assets/images/red_icon.svg",
                height: 16,
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
                  _rideInfo!['pickup_location'] ?? context.watch<TranslateProvider>().t('txt_pickup_location'),
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
                  _rideInfo!['destination'] ?? context.watch<TranslateProvider>().t('txt_destination'),
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

  Widget _buildDetailItem(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
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

  Widget _buildDriverCard(Map<String, dynamic> driver, int index) {
    final imageUrl = driver['image'] != null
        ? "https://qadampayk.com/assets/profile_image/${driver['image']}"
        : "https://img.freepik.com/premium-vector/vector-flat-illustration-grayscale-avatar-user-profile-person-icon-gender-neutral-silhouette-profile-picture-suitable-social-media-profiles-icons-screensavers-as-templatex9xa_719432-2210.jpg?semt=ais_hybrid&w=740&q=80";

    final driverId = getDriverId(driver);

    // 🔍 Debug log for each driver card
    appLog("🚗 Building card for driver $index:");
    appLog("   - Name: ${driver['name']}");
    appLog("   - Driver ID: $driverId");
    appLog("   - Raw driver data: $driver");

    return InkWell(
      onTap: () {
        appLog("🔥 Clicked driver $index with ID: $driverId");
        appLog("🔥 Full driver data: $driver");

        // Navigate to driver profile with driver ID
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DriverProfileScreen(
              driverId: driverId, // 👈 Now returns int directly
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
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
              children: [
                // Driver Info Section with debug info
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(imageUrl),
                          radius: 25,
                        ),
                        // 🔍 Debug badge showing driver index
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "$index",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver['name'] ?? 'Unknown Driver',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // 🔍 Show driver ID for debugging
                          Text(
                            "${context.watch<TranslateProvider>().t('txt_ride_id')} $driverId",
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                driver['rating']?.toString() ?? "4.8",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (driver['phone_number'] != null)
                                Row(
                                  children: [
                                    const Icon(Icons.phone, color: Colors.grey, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      driver['phone_number'],
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        driver['status']?.toUpperCase() ?? 'AVAILABLE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),

                // Vehicle Info (if available)
                if (driver['brand'] != null || driver['model'] != null || driver['number_plate'] != null) ...[
                  const SizedBox(height: 12),
                  const _RideDivider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.directions_car, color: AppTheme.seedPrimary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (driver['brand'] != null || driver['model'] != null)
                              Text(
                                "${driver['brand'] ?? ''} ${driver['model'] ?? ''}".trim(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            if (driver['number_plate'] != null)
                              Text(
                                "${context.watch<TranslateProvider>().t('txt_plate')} ${driver['number_plate']}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Accept Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.seedPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final token = await LocalCache.getToken(); // ✅ get token from your cache

                      await respondToDriver(
                        context: context,
                        requestId: driver['request_id'].toString(),  // ✅ get from API response
                        driverId: driverId.toString(),      // ✅ use our helper method
                      );
                    },
                    child: Text(
                      context.watch<TranslateProvider>().t('txt_accept_request'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Reusable divider component matching your theme
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