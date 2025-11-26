
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../providers/translate_provider.dart';
import '../../../service/local_cache.dart';
import '../../auth/SignInScreen.dart';
import '../HomeShell.dart';
import '../provide/ChatProvider.dart';

class Viewresponcescreen extends StatefulWidget {
  final int initialTabIndex;

  const Viewresponcescreen({super.key, this.initialTabIndex = 0}); // 0 = first tab

  @override
  State<Viewresponcescreen> createState() => _ViewresponcescreenState();
}

class _ViewresponcescreenState extends State<Viewresponcescreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool loading = true;
  List<dynamic> receivedRides = [];
  List<dynamic> passengerRequests = [];
  List<dynamic> sentResponses = [];

  // @override
  // void initState() {
  //   super.initState();
  //   _tabController = TabController(length: 2, vsync: this);
  //   // Set default tab here
  //   Future.delayed(Duration(milliseconds: 50), () {
  //     _tabController.index = widget.initialTabIndex;
  //   });
  //   _fetchResponses();
  // }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Set default tab
    Future.delayed(const Duration(milliseconds: 50), () {
      _tabController.index = widget.initialTabIndex;
    });

    // ✅ Listen for tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging == false) {
        _fetchResponses(); // Call API every time tab changes
        setState(() {}); // Refresh UI
      }
    });

    _fetchResponses(); // Initial fetch
  }


  // Get total count for received tab
  int get receivedCount {
    int rideBookings = receivedRides.fold(0, (sum, ride) {
      return sum + ((ride['bookings'] as List?)?.length ?? 0);
    });
    int driverRequests = passengerRequests.fold(0, (sum, req) {
      return sum + ((req['bookings'] as List?)?.length ?? 0);
    });
    return rideBookings + driverRequests;
  }


  Future<void> _fetchResponses() async {
    setState(() => loading = true);
    final authToken = await LocalCache.getToken();
    const baseUrl = "https://qadampayk.com/api";

    try {
      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      final receivedRes = await http.get(
        Uri.parse("$baseUrl/get-recived-response"),
        headers: headers,
      );
      final sentRes = await http.get(
        Uri.parse("$baseUrl/get-send-response"),
        headers: headers,
      );

      print("📦 Received Response Body: ${receivedRes.body}");
      print("📦 Sent Response Body: ${sentRes.body}");

      // Check authentication first
      final receivedJson = jsonDecode(receivedRes.body);
      if (receivedJson['status'] == false &&
          receivedJson['message'] == "User not authenticated") {
        // Clear local token if needed
        await LocalCache.logout();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PhoneNumberScreen()),
        );
        // Navigate to login screen

        return;
      }

      if (receivedRes.statusCode == 200 && sentRes.statusCode == 200) {
        final sentJson = jsonDecode(sentRes.body);

        List<dynamic> ridesWithBookings = [];
        List<dynamic> passengerReqs = [];

        if (receivedJson['data'] is Map) {
          ridesWithBookings = (receivedJson['data']['rides_with_bookings'] is List)
              ? List<dynamic>.from(receivedJson['data']['rides_with_bookings'])
              : [];
          passengerReqs = (receivedJson['data']['passenger_requests'] is List)
              ? List<dynamic>.from(receivedJson['data']['passenger_requests'])
              : [];
        } else if (receivedJson['data'] is List) {
          ridesWithBookings = List<dynamic>.from(receivedJson['data']);
        }

        List<dynamic> sentList = [];
        if (sentJson['data'] is List) {
          sentList = List<dynamic>.from(sentJson['data']);
        } else if (sentJson['data'] is Map) {
          sentList = [sentJson['data']];
        }

        sentList = sentList.map((e) {
          if (e is Map<String, dynamic>) return e;
          return Map<String, dynamic>.from(e as Map);
        }).toList();

        if (mounted) {
          setState(() {
            receivedRides = ridesWithBookings;
            passengerRequests = passengerReqs;
            sentResponses = sentList;
            loading = false;
          });
        }
      } else {
        setState(() => loading = false);
        print(
            "⚠️ Failed to fetch responses. Status codes - Received: ${receivedRes.statusCode}, Sent: ${sentRes.statusCode}");
      }
    } catch (e, s) {
      print("⚠️ Error fetching responses: $e\n$s");
      setState(() => loading = false);
    }
  }


  // Future<void> _fetchResponses() async {
  //   setState(() => loading = true);
  //   final authToken = await LocalCache.getToken();
  //   const baseUrl = "https://qadampayk.com/api";
  //
  //   try {
  //     final headers = {
  //       'Accept': 'application/json',
  //       'Authorization': 'Bearer $authToken',
  //     };
  //
  //     final receivedRes =
  //     await http.get(Uri.parse("$baseUrl/get-recived-response"), headers: headers);
  //     final sentRes =
  //     await http.get(Uri.parse("$baseUrl/get-send-response"), headers: headers);
  //
  //     print("📦 Received Response Body: ${receivedRes.body}");
  //     print("📦 Sent Response Body: ${sentRes.body}");
  //
  //     if (receivedRes.statusCode == 200 && sentRes.statusCode == 200) {
  //       final receivedJson = jsonDecode(receivedRes.body);
  //       final sentJson = jsonDecode(sentRes.body);
  //
  //       List<dynamic> ridesWithBookings = [];
  //       List<dynamic> passengerReqs = [];
  //
  //       if (receivedJson['data'] is Map) {
  //         ridesWithBookings = (receivedJson['data']['rides_with_bookings'] is List)
  //             ? List<dynamic>.from(receivedJson['data']['rides_with_bookings'])
  //             : [];
  //         passengerReqs = (receivedJson['data']['passenger_requests'] is List)
  //             ? List<dynamic>.from(receivedJson['data']['passenger_requests'])
  //             : [];
  //       } else if (receivedJson['data'] is List) {
  //         ridesWithBookings = List<dynamic>.from(receivedJson['data']);
  //       }
  //
  //       List<dynamic> sentList = [];
  //       if (sentJson['data'] is List) {
  //         sentList = List<dynamic>.from(sentJson['data']);
  //       } else if (sentJson['data'] is Map) {
  //         sentList = [sentJson['data']];
  //       }
  //
  //       sentList = sentList.map((e) {
  //         if (e is Map<String, dynamic>) return e;
  //         return Map<String, dynamic>.from(e as Map);
  //       }).toList();
  //
  //       if (mounted) {
  //         setState(() {
  //           receivedRides = ridesWithBookings;
  //           passengerRequests = passengerReqs;
  //           sentResponses = sentList;
  //           loading = false;
  //         });
  //       }
  //     }else if (receivedRes.statusCode == 401){
  //       print("ghjkl");
  //     }
  //     else {
  //       setState(() => loading = false);
  //       print(
  //           "⚠️ Failed to fetch responses. Status codes - Received: ${receivedRes.statusCode}, Sent: ${sentRes.statusCode}");
  //     }
  //   } catch (e, s) {
  //     print("⚠️ Error fetching responses: $e\n$s");
  //     setState(() => loading = false);
  //   }
  // }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    final authToken = await LocalCache.getToken();
    const baseUrl = "https://qadampayk.com/api/confirm-booking";
    try {
      final res = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: {'booking_id': bookingId, 'status': status},
      );

      if (res.statusCode == 200) {
        _fetchResponses();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Booking ${status == 'confirmed' ? 'confirmed' : 'cancelled'} successfully"),
            backgroundColor: status == 'confirmed' ? Colors.green : Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update status: ${res.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _updateDriverStatus(String bookingId, String requestID, String status) async {
    final authToken = await LocalCache.getToken();
    const baseUrl = "https://qadampayk.com/api/request/respond-driver";
    try {
      final res = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: {'driver_id': bookingId, "request_id": requestID, "status": status},
      );

      if (res.statusCode == 200) {
        _fetchResponses();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Driver ${status == 'confirmed' ? 'accepted' : 'rejected'} successfully"),
            backgroundColor: status == 'confirmed' ? Colors.green : Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update status: ${res.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _openChat(Map<String, dynamic> booking) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    print("💬 Open chat with ${booking['passenger_id']}");
    final driverId = booking['passenger_id'];
    final driverName = "${booking['passenger_name']}";
    if (driverId == null) return;

    await chatProvider.startChat(
      context: context,
      otherUserId: driverId,
      userName: driverName.toString(),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, {bool isRideBooking = true}) {
    final status = booking['status'] ?? 'pending';
    final theme = Theme.of(context);

    Color statusColor = status == 'confirmed'
        ? Colors.green
        : status == 'cancelled'
        ? Colors.red
        : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person, color: theme.colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['passenger_name'] ?? booking['name'] ?? 'Unnamed',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: theme.colorScheme.secondary),
                          const SizedBox(width: 4),
                          Text(
                            booking['passenger_phone'] ?? booking['phone_number'] ?? 'N/A',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),

                  // if(status == 'confirmed'&& booking['active_status'] == 1)
                  child: Text(
                    booking['active_status'] == "1"
                        ? "Active"
                        : booking['active_status'] == "2"
                        ? "Completed"  // <-- Set what you want for status "2"
                        : status.toUpperCase(),

                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (booking['seats_booked'] != null || booking['price'] != null) ...[
              const SizedBox(height: 12),
              Divider(color: theme.colorScheme.outline.withOpacity(0.2)),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (booking['seats_booked'] != null) ...[
                    Icon(Icons.airline_seat_recline_normal, size: 18, color: theme.colorScheme.secondary),
                    const SizedBox(width: 6),
                    Text(
                      "${booking['seats_booked']} ${context.watch<TranslateProvider>().t('txt_seats')}",
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 20),
                  ],
                  if (booking['price'] != null) ...[
                    // Icon(Icons.currency_rupee, size: 18, color: theme.colorScheme.secondary),

                    Text(
                      "${booking['price']}",
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text("c"),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 16),
            _buildActionButtons(booking, status, isRideBooking, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> booking, String status, bool isRideBooking, ThemeData theme) {

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (status == 'pending') ...[
          if (isRideBooking) ...[
            _buildActionButton(
              label: "Confirm",
              icon: Icons.check_circle_outline,
              color: Colors.green,
              onPressed: () => _updateBookingStatus(booking['booking_id'].toString(), 'confirmed'),
            ),
            _buildActionButton(
              label: "Cancel",
              icon: Icons.cancel_outlined,
              color: Colors.red,
              onPressed: () => _updateBookingStatus(booking['booking_id'].toString(), 'cancelled'),
            ),
          ] else ...[
            _buildActionButton(
              label: "Accept",
              icon: Icons.check_circle_outline,
              color: Colors.green,
              onPressed: () => _updateBookingStatus(booking['interest_id'].toString(), 'confirmed'),
            ),
            _buildActionButton(
              label: "Reject",
              icon: Icons.cancel_outlined,
              color: Colors.red,
              onPressed: () => _updateBookingStatus(booking['interest_id'].toString(), 'cancelled'),
            ),
          ],
          _buildActionButton(
            label: "${context.watch<TranslateProvider>().t('txt_chats')}",
            icon: Icons.chat_bubble_outline,
            color: theme.colorScheme.primary,
            onPressed: () => _openChat(booking),
          ),
        ] else if (status == 'confirmed') ...[
        if(status == 'confirmed'&& booking['active_status'] == "0")  _buildActionButton(
            label: status == 'confirmed'&& booking['active_status'] == "0" ? "Start Ride": "Already started",
            icon: Icons.play_arrow,
            color: Colors.blue,
            onPressed:status == 'confirmed'&& booking['active_status'] != "0" ?(){}: () { _startRide(booking['booking_id'].toString());},
          ),
          if(status == 'confirmed'&& booking['active_status'] == "1")  _buildActionButton(
            label: "End Ride",
            icon: Icons.stop_circle_outlined,
            color: Colors.orange,
            onPressed: () => _endRide(booking['booking_id'].toString()),
          ),
          _buildActionButton(
            label: "${context.watch<TranslateProvider>().t('txt_chats')}",
            icon: Icons.chat_bubble_outline,
            color: theme.colorScheme.primary,
            onPressed: () => _openChat(booking),
          ),
        ] else ...[
          _buildActionButton(
            label: "${context.watch<TranslateProvider>().t('txt_chats')}",
            icon: Icons.chat_bubble_outline,
            color: theme.colorScheme.primary,
            onPressed: () => _openChat(booking),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
    );
  }

  Future<void> _startRide(String bookingId) async {
    final authToken = await LocalCache.getToken();
    const url = "https://qadampayk.com/api/upadte-booking-active-status";

    try {
      final res = await http.post(Uri.parse(url),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: {'booking_id': bookingId});

      if (res.statusCode == 200) _fetchResponses();
    } catch (e) {
      print("Error starting ride: $e");
    }
  }

  Future<void> _endRide(String bookingId) async {
    final authToken = await LocalCache.getToken();
    const url = "https://qadampayk.com/api/upadte-booking-complete-status";

    try {
      final res = await http.post(Uri.parse(url),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: {'booking_id': bookingId});

      if (res.statusCode == 200) _fetchResponses();
    } catch (e) {
      print("Error ending ride: $e");
    }
  }

  Widget _buildReceivedTab() {
    final theme = Theme.of(context);

    if (receivedRides.isEmpty && passengerRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              "${context.watch<TranslateProvider>().t('txt_no_ride_details')}",
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...receivedRides.map((ride) {
          final bookings = ride['bookings'] ?? [];
          return _buildRideCard(ride, bookings, theme);
        }).toList(),
        ...passengerRequests.map((req) {
          final bookings = req['bookings'] ?? [];
          return _buildPassengerRequestCard(req, bookings, theme);
        }).toList(),
      ],
    );
  }

  Widget _buildRideCard(dynamic ride, List bookings, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.directions_car, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${context.watch<TranslateProvider>().t('txt_rides')}",
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${ride['pickup_location']} → ${ride['destination']}",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${bookings.length}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(  leading: Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                        text: "${ride['ride_date']}",  theme:theme),
                    _buildInfoChip(  leading: Icon(
                      Icons.access_time,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),  text:  "${ride['ride_time']}", theme:theme),
                    _buildInfoChip(
                        leading: Icon(
                          Icons.local_shipping,
                          size: 16,
                          color: theme.colorScheme.secondary,
                        ),
                        text: ride['accept_parcel'] ? '${context.watch<TranslateProvider>().t('txt_parcel_contact')}: Yes' : '${context.watch<TranslateProvider>().t('txt_parcel_contact')}: No',theme: theme),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.directions_car_outlined, size: 16, color: theme.colorScheme.secondary),
                    const SizedBox(width: 6),
                    Text(
                      "${ride['vehicle_name']} (${ride['vehicle_number']})",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${context.watch<TranslateProvider>().t('txt_passengers')}",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                ...bookings.map((b) => _buildBookingCard(Map<String, dynamic>.from(b))).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerRequestCard(dynamic req, List bookings, ThemeData theme) {
    final hasDrivers = bookings.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_search, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${context.watch<TranslateProvider>().t('txt_my_requests')}",
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${req['pickup_location']} → ${req['destination']}",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${bookings.length}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                        leading: Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: theme.colorScheme.secondary,
                        ),
                        text: "${req['ride_date']}",theme: theme),
                    _buildInfoChip(
                        leading: Icon(
                          Icons.access_time,
                          size: 16,
                          color: theme.colorScheme.secondary,
                        ),
                        text:"${req['ride_time'] ?? '-'}",theme: theme),
                    _buildInfoChip(
                        leading: Icon(
                          Icons.event_seat,
                          size: 16,
                          color: theme.colorScheme.secondary,
                        ),
                        text: "${req['number_of_seats']} ${context.watch<TranslateProvider>().t('txt_seats')}",theme: theme),
                    _buildInfoChip(
                        leading: Text(""),
                        text: "${req['budget']} c",theme: theme),
                  ],
                ),
                if (req['parcel_details'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 16, color: theme.colorScheme.secondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "${context.watch<TranslateProvider>().t('txt_parcel')}: ${req['parcel_details']}",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${context.watch<TranslateProvider>().t('txt_interested_drivers')}",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 12),
                if (hasDrivers)
                  ...bookings.map((driver) => _buildDriverCard(driver, theme)).toList()
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "${context.watch<TranslateProvider>().t('txt_no_drivers_found')}",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(dynamic driver, ThemeData theme) {
    final imageUrl = driver['image'] != null
        ? "https://qadampayk.com/assets/profile_image/${driver['image']}"
        : null;
    final status = driver['status'] ?? 'pending';

    Color statusColor = status == 'confirm'
        ? Colors.green
        : status == 'cancel'
        ? Colors.red
        : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                  child: imageUrl == null
                      ? Icon(Icons.person, size: 30, color: theme.colorScheme.primary)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver['name'] ?? 'Unknown Driver',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Icon(Icons.phone, size: 14, color: theme.colorScheme.secondary),
                          // const SizedBox(width: 4),
                          // Text(
                          //   driver['phone_number'] ?? '-',
                          //   style: theme.textTheme.bodySmall?.copyWith(
                          //     color: theme.colorScheme.onSurfaceVariant,
                          //   ),
                          // ),
                          const SizedBox(width: 12),
                          Icon(
                            driver['gender'] == 'male' ? Icons.male : Icons.female,
                            size: 14,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            driver['gender'] ?? 'N/A',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8,),
            // _buildActionButton(
            //   label: "Chat",
            //   icon: Icons.chat_bubble_outline,
            //   color: theme.colorScheme.primary,
            //   onPressed: ()async {
            //     print("ghjkl");
            //     final chatProvider = Provider.of<ChatProvider>(context, listen: false);
            //     final driverId = driver['driver_id'];
            //     final driverName = "${driver['driver_name']}";
            //     if (driverId == null) return;
            //     print("ghjkl");
            //
            //     await chatProvider.startChat(
            //       context: context,
            //       otherUserId: driverId,
            //       userName: driverName.toString(),
            //     );
            //   },
            // ),

            if (status == 'pending') ...[
              const SizedBox(height: 12),
              Divider(color: theme.colorScheme.outline.withOpacity(0.2)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildActionButton(
                    label: "Accept",
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    onPressed: () => _updateDriverStatus(
                      driver['driver_id'].toString(),
                      driver['request_id'].toString(),
                      'confirmed',
                    ),
                  ),
                  _buildActionButton(
                    label: "Reject",
                    icon: Icons.cancel_outlined,
                    color: Colors.red,
                    onPressed: () => _updateDriverStatus(
                      driver['driver_id'].toString(),
                      driver['request_id'].toString(),
                      'declined',
                    ),
                  ),

                ],

              ),
            ],
          if(status == 'pending' && status == 'pending' )  _buildActionButton(
              label: "${context.watch<TranslateProvider>().t('txt_chats')}",
              icon: Icons.chat_bubble_outline,
              color: theme.colorScheme.primary,
              onPressed: () => _openChat(driver),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required Widget leading, // <-- Can be Icon() or Text()
    String? text,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        leading, // <-- Icon or Text here
        if (text != null) ...[
          const SizedBox(width: 6),
          Text(
            text!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ]
      ],
    );
  }


  Widget _buildSentTab() {
    final theme = Theme.of(context);
    print("---------======== ${sentResponses.length}");

    if (sentResponses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_outlined, size: 80, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              "${context.watch<TranslateProvider>().t('txt_no_ride_details')}",
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sentResponses.length,
      itemBuilder: (context, index) {
        final req = sentResponses[index];

        final pickup = req['pickup_location'] ?? '-';
        final destination = req['destination'] ?? '-';
        final seats = req['number_of_seats']?.toString() ?? '-';
        final budget = req['budget'] ?? '-';
        final rideDate = req['ride_date'] ?? '-';
        final rideTime = req['ride_time'] ?? '-';
        final status = req['status'] ?? '-';
        final servicesList = (req['services'] is List) ? req['services'].cast<String>() : [];

        Color statusColor = status == 'confirmed'
            ? Colors.green
            : status == 'cancelled'
            ? Colors.red
            : Colors.orange;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${context.watch<TranslateProvider>().t('txt_send_responce')}",
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$pickup → $destination",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        _buildInfoChip(
                            leading: Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: theme.colorScheme.secondary,
                            ),
                            text:rideDate, theme:theme),
                        _buildInfoChip(
                            leading: Icon(
                              Icons.access_time,
                              size: 16,
                              color: theme.colorScheme.secondary,
                            ),
                            text:rideTime,theme: theme),
                        _buildInfoChip(
                            leading: Icon(
                              Icons.event_seat,
                              size: 16,
                              color: theme.colorScheme.secondary,
                            ),
                            text: "$seats ${context.watch<TranslateProvider>().t('txt_seats')}",theme: theme),
                        _buildInfoChip(
                            leading: Text(""),
                            text:"$budget c ",theme: theme),
                      ],
                    ),
                    if (servicesList.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Divider(color: theme.colorScheme.outline.withOpacity(0.2)),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.miscellaneous_services, size: 16, color: theme.colorScheme.secondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: servicesList.map((service) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    service,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
          // if(req['type'] == "request_interest")  Text(req['passenger_name']),
              if(status == 'confirmed'&& req['type'] == "request_interest"&& req['active_status'] == "0")  _buildActionButton(
                label: status == 'confirmed'&& req['active_status'] == "0" ? "Start Ride": "Already started",
                icon: Icons.play_arrow,
                color: Colors.blue,
                onPressed:() { _startRide(req['booking_id'].toString());},
              ),
              SizedBox(height: 8,),
              if(status == 'confirmed'&& req['type'] == "request_interest"&& req['active_status'] == "1")  _buildActionButton(
                label: "End Ride",
                icon: Icons.stop_circle_outlined,
                color: Colors.orange,
                onPressed: () => _endRide(req['booking_id'].toString()),
              ),
              SizedBox(height: 8,),
              _buildActionButton(
                label: "${context.watch<TranslateProvider>().t('txt_chats')}",
                icon: Icons.chat_bubble_outline,
                color: theme.colorScheme.primary,
                 onPressed: () => _openChat(req),
                // onPressed: () {},
              ),
              SizedBox(height: 8,),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        // Navigate to HomeShell with Profile tab instead of going back
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeShell(initialIndex: 4)), // 4 = Profile
        );
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: _buildAppBar(theme),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _fetchResponses,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildReceivedTab(),
              _buildSentTab(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    final double tabHeight = 44;
    final double pillRadius = 22;

    return AppBar(
      leading: InkWell(onTap: (){
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeShell(initialIndex: 4)), // 4 = Profile
        );
      },
          child: Icon(Icons.arrow_back_sharp)),
      title: Text(
        context.watch<TranslateProvider>().t('txt_view_responce') ,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onBackground,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: theme.colorScheme.background,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(tabHeight + 24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            height: tabHeight,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(pillRadius),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(pillRadius - 2),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              overlayColor: MaterialStateProperty.all(Colors.transparent),
              labelColor: Colors.white,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Text("${context.watch<TranslateProvider>().t('txt_received_responce') }",style: TextStyle(fontSize: 12)),
                      if (receivedCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _tabController.index == 0
                                ? Colors.white.withOpacity(0.3)
                                : theme.colorScheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "$receivedCount",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _tabController.index == 0
                                  ? Colors.white
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("${context.watch<TranslateProvider>().t('txt_send_responce') }",style: TextStyle(fontSize: 12),),
                      if (sentResponses.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _tabController.index == 1
                                ? Colors.white.withOpacity(0.3)
                                : theme.colorScheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${sentResponses.length}",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _tabController.index == 1
                                  ? Colors.white
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              onTap: (index) => setState(() => _tabController.index = index),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}