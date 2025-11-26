


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../providers/translate_provider.dart';
import '../../../service/colors.dart';
import '../../../service/local_cache.dart';
import '../create/DriverProfileScreen.dart';

class InterestedPassengersScreen extends StatefulWidget {
  final int rideId;

  const InterestedPassengersScreen({super.key, required this.rideId});

  @override
  State<InterestedPassengersScreen> createState() =>
      _InterestedPassengersScreenState();
}

class _InterestedPassengersScreenState
    extends State<InterestedPassengersScreen> {
  bool _loading = true;
  List<PassengerBooking> _bookings = [];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    final token = await LocalCache.getToken();
    try {
      final url = Uri.parse(
          "https://qadampayk.com/api/get-drivers-booking?ride_id=${widget.rideId}");
      final response = await http.get(url, headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json"
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            _bookings = (data['data'] as List)
                .map((e) => PassengerBooking.fromJson(e))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching bookings: $e");
    }
    setState(() => _loading = false);
  }

  Future<void> _updateBookingStatus(int bookingId, String status) async {
    final token = await LocalCache.getToken();
    try {
      final url = Uri.parse("https://qadampayk.com/api/confirm-booking");
      final response = await http.post(url, headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json"
      }, body: {
        "booking_id": bookingId.toString(),
        "status": status,
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          // ✅ Show success toast
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Booking $status ✅")),
          );

          // ✅ Go back after short delay (so toast is visible)
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) Navigator.pop(context, true);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Action failed")),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Update booking error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(context.watch<TranslateProvider>().t('txt_intrested_passenger')),
        backgroundColor: AppTheme.seedPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
          ?  Center(child: Text(context.watch<TranslateProvider>().t('txt_no_ride_details')))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final b = _bookings[index];
          return _buildPassengerCard(b);
        },
      ),
    );
  }

  // ---------------- UI Card ----------------
  Widget _buildPassengerCard(PassengerBooking b) {
    return InkWell(onTap: (){
      // Navigator.push(context, MaterialPageRoute(builder: (context)=>DriverProfileScreen(b.u)));
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --------- Header with user & status ---------
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage:
                      (b.userImage != null && b.userImage!.isNotEmpty)
                          ? NetworkImage(
                          "https://qadampayk.com/storage/${b.userImage}")
                          : const AssetImage(
                          "assets/images/user_placeholder.png")
                      as ImageProvider,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${b.userName} (${b.seatsBooked} seats)",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          Text("Phone: ${b.userPhone}",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    _buildStatusBadge(b.status),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(),

                // --------- Ride details ---------
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                          Icons.location_on, "Pickup", b.pickupLocation),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                          Icons.flag, "Destination", b.destination),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(Icons.event, "Date", b.rideDate),
                    ),
                    Expanded(
                      child: _buildDetailItem(Icons.access_time, "Time", b.rideTime),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                          Icons.event_seat, "Seats", "${b.seatsBooked}"),
                    ),
                    Expanded(
                      child: _buildDetailItem(Icons.attach_money, "Price", b.price,
                          valueColor: AppTheme.seedPrimary),
                    ),
                  ],
                ),

                // --------- Services Chips ---------
                if (b.services.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    children: b.services.map((s) {
                      return Chip(
                        label: Text(s.serviceName),
                        avatar: (s.serviceImage != null &&
                            s.serviceImage!.isNotEmpty)
                            ? Image.network(
                          "https://qadampayk.com/assets/services_images/${s.serviceImage!}",
                          height: 20,
                          width: 20,
                        )
                            : null,
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 12),

                // --------- Action buttons ---------
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(80, 36)),
                      onPressed: () =>
                          _updateBookingStatus(b.bookingId, "confirmed"),
                      child:  Text(context.watch<TranslateProvider>().t('txt_confirm')),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(80, 36)),
                      onPressed: () =>
                          _updateBookingStatus(b.bookingId, "cancelled"),
                      child:  Text(context.watch<TranslateProvider>().t('txt_cancel')),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Helpers ----------------
  Widget _buildDetailItem(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          "$label: ",
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String textValue;
    switch (status) {
      case "confirmed":
        bg = Colors.green.shade100;
        text = Colors.green.shade800;
        textValue = "Confirmed";
        break;
      case "cancelled":
        bg = Colors.red.shade100;
        text = Colors.red.shade800;
        textValue = "Cancelled";
        break;
      default:
        bg = Colors.orange.shade100;
        text = Colors.orange.shade800;
        textValue = "Pending";
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        textValue,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }
}

// ---------------- MODEL ----------------
class PassengerBooking {
  final int bookingId;
  final int rideId;
  final String userName;
  final String userPhone;
  final String? userImage;
  final int seatsBooked;
  final String price;
  final String status;
  final String pickupLocation;
  final String destination;
  final String rideDate;
  final String rideTime;
  final List<PassengerService> services;

  PassengerBooking({
    required this.bookingId,
    required this.rideId,
    required this.userName,
    required this.userPhone,
    this.userImage,
    required this.seatsBooked,
    required this.price,
    required this.status,
    required this.pickupLocation,
    required this.destination,
    required this.rideDate,
    required this.rideTime,
    required this.services,
  });

  factory PassengerBooking.fromJson(Map<String, dynamic> json) {
    return PassengerBooking(
      bookingId: json['booking_id'],
      rideId: json['ride_id'],
      userName: json['user_name'] ?? '',
      userPhone: json['user_phone'] ?? '',
      userImage: json['user_image'],
      seatsBooked: json['seats_booked'] ?? 0,
      price: json['price'] ?? '',
      status: json['status'] ?? '',
      pickupLocation: json['pickup_location'] ?? '',
      destination: json['destination'] ?? '',
      rideDate: json['ride_date'] ?? '',
      rideTime: json['ride_time'] ?? '',
      services: (json['services'] as List? ?? [])
          .map((e) => PassengerService.fromJson(e))
          .toList(),
    );
  }
}

class PassengerService {
  final String serviceName;
  final String? serviceImage;

  PassengerService({required this.serviceName, this.serviceImage});

  factory PassengerService.fromJson(Map<String, dynamic> json) {
    return PassengerService(
      serviceName: json['service_name'] ?? '',
      serviceImage: json['service_image'],
    );
  }
}
