import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:dotted_line/dotted_line.dart';
import 'package:provider/provider.dart';
import '../../../api_service/logger.dart';
import '../../../providers/translate_provider.dart';
import '../../../service/local_cache.dart';
import '../../../service/colors.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool loading = true;
  Map<String, List<dynamic>> ridesByStatus = {
    "active": [],
    "cancelled": [],
    "completed": [],
  };

  // Track which ride is being reviewed
  String? _reviewingRideId;
  final Map<String, double> _ratings = {};
  final Map<String, TextEditingController> _reviewControllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchRides("active");
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reviewControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _fetchRides(String statusType) async {
    setState(() => loading = true);
    final authToken = await LocalCache.getToken();
    final baseUrl = "https://qadampayk.com/api/get-confirmation-status?status_type=$statusType";

    try {
      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      final res = await http.get(Uri.parse(baseUrl), headers: headers);
      appLog("📦 [$statusType] Response: ${res.body}");

      if (res.statusCode == 200) {
        final jsonData = jsonDecode(res.body);
        final List<dynamic> dataList = (jsonData['data'] is List)
            ? List<dynamic>.from(jsonData['data'])
            : [];

        if (mounted) {
          setState(() {
            ridesByStatus[statusType] = dataList;
            loading = false;
          });
        }
      } else {
        setState(() => loading = false);
        appLog("⚠️ Failed to fetch $statusType rides: ${res.statusCode}");
      }
    } catch (e, s) {
      appLog("⚠️ Error fetching $statusType rides: $e\n$s");
      setState(() => loading = false);
    }
  }

  Future<void> _submitReview({
    required String rideId,
    required String reviewedId,
    required double rating,
    required String review,
  }) async {
    final authToken = await LocalCache.getToken();
    final uri = Uri.parse("https://qadampayk.com/api/rate");

    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'ride_id': rideId,
          'reviewed_id': reviewedId,
          'rating': rating.toInt().toString(),
          'review': review,
        }),
      );

      if (mounted) Navigator.of(context).pop();

      appLog("📤 Review Response Status: ${response.statusCode}");
      appLog("📥 Review Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? '✅ Review submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          setState(() {
            _reviewingRideId = null;
            _ratings.remove(rideId);
            _reviewControllers[rideId]?.dispose();
            _reviewControllers.remove(rideId);
          });

          _fetchRides("completed");
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to submit review'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      appLog("❌ Review Exception: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRideCard(Map<String, dynamic> ride, String statusType) {
    final pickup = ride['pickup_location'] ?? '-';
    final destination = ride['destination'] ?? '-';
    final rideDate = ride['ride_date'] ?? '-';
    final rideTime = ride['ride_time'] ?? '-';
    final price = ride['price'] ?? '-';
    final status = ride['status'] ?? '-';
    final seats = ride['seats_booked']?.toString() ?? '-';
    final passengerName = ride['passenger_name'] ?? '-';
    final passengerPhone = ride['passenger_phone'] ?? '-';
    final passengerImage = ride['passenger_image'] != null
        ? "https://qadampayk.com/assets/profile_image/${ride['passenger_image']}"
        : null;
    final hasReviewed = ride['has_reviewed'] == true || ride['is_reviewed'] == true;

    final rideId = ride['ride_id']?.toString() ?? ride['ride_id']?.toString() ?? '';
    final isReviewing = _reviewingRideId == rideId;

    if (!_ratings.containsKey(rideId)) {
      _ratings[rideId] = 5.0;
    }
    if (!_reviewControllers.containsKey(rideId)) {
      _reviewControllers[rideId] = TextEditingController();
    }

    Color statusColor = status == 'confirmed'
        ? Colors.green
        : status == 'cancelled'
        ? Colors.red
        : Colors.orange;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Passenger Info Section (matching driver info style)
              _buildPassengerInfo(
                passengerName,
                passengerPhone,
                passengerImage,
                price,
                seats,
                rideDate,
                rideTime,
                status,
                statusColor,
              ),

              const SizedBox(height: 12),

              // Route Section (matching ride locations style)
              _buildRouteSection(pickup, destination),

              // Review Section
              if (statusType == "completed" && !hasReviewed && !isReviewing)
                _buildReviewButton(rideId),

              if (statusType == "completed" && !hasReviewed && isReviewing)
                _buildReviewForm(rideId, ride),

              if (statusType == "completed" && hasReviewed)
                _buildReviewedBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassengerInfo(
      String passengerName,
      String passengerPhone,
      String? passengerImage,
      String price,
      String seats,
      String rideDate,
      String rideTime,
      String status,
      Color statusColor,
      ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: passengerImage != null
                    ? NetworkImage(passengerImage)
                    : null,
                child: passengerImage == null
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passengerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          passengerPhone,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "$price c",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.seedPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(
                      int.tryParse(seats) ?? 1,
                          (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: Icon(
                          Icons.person,
                          color: Colors.grey.shade400,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _RideDivider(),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    rideDate,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    rideTime != 'null' && rideTime != '-' ? rideTime : 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSection(String pickup, String destination) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                "assets/images/red_icon.svg",
                height: 16,
              ),
              const SizedBox(height: 4),
              const DottedLine(
                dashLength: 3,
                dashGapLength: 3,
                lineThickness: 2,
                dashColor: Colors.grey,
                direction: Axis.vertical,
                lineLength: 25,
              ),
              const SizedBox(height: 4),
              SvgPicture.asset(
                "assets/images/blue_icon.svg",
                height: 15,
              ),            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pickup,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                const _RideDivider(),
                const SizedBox(height: 8),
                Text(
                  destination,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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

  Widget _buildReviewButton(String rideId) {
    return Column(
      children: [
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
            ),
            onPressed: () {
              setState(() {
                _reviewingRideId = rideId;
              });
            },
            icon: const Icon(Icons.star_rate, size: 20),
            label:  Text(
              '${context.watch<TranslateProvider>().t('txt_rate_this_trip')}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewForm(String rideId, Map<String, dynamic> ride) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rate Your Experience',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _ratings[rideId] = (index + 1).toDouble();
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        index < _ratings[rideId]!
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber.shade600,
                        size: 36,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reviewControllers[rideId],
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.amber.shade600,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        setState(() {
                          _reviewingRideId = null;
                          _reviewControllers[rideId]?.clear();
                          _ratings[rideId] = 5.0;
                        });
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      onPressed: () {
                        _submitReview(
                          rideId: rideId,
                          reviewedId: ride['passenger_id']?.toString() ??
                              ride['user_id']?.toString() ??
                              '',
                          rating: _ratings[rideId]!,
                          review: _reviewControllers[rideId]!.text.trim(),
                        );
                      },
                      child: const Text(
                        'Submit Review',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewedBadge() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Review Submitted',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String statusType) {
    final rides = ridesByStatus[statusType] ?? [];
    if (loading && rides.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (rides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "${context.watch<TranslateProvider>().t('txt_no_ride_details')}",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchRides(statusType),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        itemCount: rides.length + 1, // ✅ Add 1 for extra space at the end
        itemBuilder: (context, index) {
          if (index == rides.length) {
            return const SizedBox(height: 100); // ✅ Extra scroll space after last item
          }
          final ride = rides[index];
          return _buildRideCard(Map<String, dynamic>.from(ride), statusType);
        },
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unselectedColor = cs.surfaceContainerHighest.withOpacity(0.40);
    const double tabHeight = 48;
    const double pillRadius = 16;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title:  Text(
          "${context.watch<TranslateProvider>().t('txt_trips')}",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
            child: Container(
              height: tabHeight,
              decoration: BoxDecoration(
                color: unselectedColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.seedPrimary,
                  borderRadius: BorderRadius.circular(pillRadius - 2),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontSize: 14),
                tabs:  [
                  Tab(text: "${context.watch<TranslateProvider>().t('txt_active')}"),
                  Tab(text: "${context.watch<TranslateProvider>().t('txt_cancelled')}"),
                  Tab(text: "${context.watch<TranslateProvider>().t('txt_completed')}"),
                ],
                onTap: (index) {
                  final statusType = index == 0
                      ? "active"
                      : index == 1
                      ? "cancelled"
                      : "completed";
                  _fetchRides(statusType);
                },
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTab("active"),
          _buildTab("cancelled"),
          _buildTab("completed"),
        ],
      ),
    );
  }
}

// Reusable divider component
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
                (_) => Container(width: dashWidth, height: height, color: color),
          ),
        );
      },
    );
  }
}