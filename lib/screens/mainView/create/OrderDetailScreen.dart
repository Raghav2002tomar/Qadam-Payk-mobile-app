// lib/screens/order_detail_screen.dart
import 'dart:convert';

import 'package:bla_bla_car/providers/translate_provider.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../service/local_cache.dart';
import '../../auth/SignInScreen.dart';
import '../HomeShell.dart';
import '../ProfileScreen/ViewResponceScreen.dart';
import '../chat/ChatConversationScreen.dart';
import '../provide/ChatProvider.dart';
import '../search/model/ride_model.dart';
import 'DriverProfileScreen.dart';

class OrderDetailScreen extends StatelessWidget {
  final RideDataModel ride;
  final int passengers;
  final List<String>? services;
  final String bookingType; // 0 = Ride, 1 = Parcel


  const OrderDetailScreen({
    super.key,
    required this.ride,
    required this.passengers,
    this.services,
    required this.bookingType, // default to Ride if not provided

  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF008955)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          ride.rideDate != null
              ? DateFormat(
                  'EEEE, dd MMMM',
                ).format(DateFormat('dd-MM-yyyy').parse(ride.rideDate!))
              : 'Wednesday, 17 September',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip Details Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            SvgPicture.asset(
                              "assets/images/red_icon.svg",
                              height: 16,
                            ),
                            const SizedBox(height: 6),
                            const DottedLine(
                              dashLength: 3,
                              dashGapLength: 3,
                              lineThickness: 2,
                              dashColor: Colors.grey,
                              direction: Axis.vertical,
                              lineLength: 40,
                            ),
                            const SizedBox(height: 6),
                            SvgPicture.asset(
                              "assets/images/blue_icon.svg",
                              height: 16,
                            ),
                          ],
                        ),
                        const SizedBox(width: 35),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ride.pickupLocation ?? "",
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 16),
                              dottedDivider(),
                              const SizedBox(height: 16),
                              Text(
                                ride.destination ?? "",
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Price Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${1} ${context.watch<TranslateProvider>().t('txt_passengers')}${ride.price == 1 ? "" : "s"}',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: const Color(0xFF666666),
                          ),
                        ),
                        Text(
                          '${ride.price ?? 500.00} c',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Driver Info Card
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DriverProfileScreen(
                            driverId: ride.driverId as int,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration(),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(
                                  "https://qadampayk.com/assets/profile_image/${ride.driverImage}" ??
                                      'https://img.freepik.com/premium-vector/vector-flat-illustration-grayscale-avatar-user-profile-person-icon-gender-neutral-silhouette-profile-picture-suitable-social-media-profiles-icons-screensavers-as-templatex9xa_719432-2210.jpg?semt=ais_hybrid&w=740&q=80',
                                ),
                              ),
                           if(ride.driverStatus.toString() =="verified")   Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: Colors.white, // 👈 white background border
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      "assets/images/verify_user.png",
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              )                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ride.driverName ?? "Driver ",
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 16,
                                      color: Color(0xFFFFC107),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${ride.driverRating ?? 4.5}/5 -  ${context.watch<TranslateProvider>().t('txt_ratings')}',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: const Color(0xFF666666),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Color(0xFF666666),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Features
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: Column(
                      children: [
                        // _buildFeatureItem(
                        //   Icons.verified_user,
                        //   ride.driverStatus ?? context.watch<TranslateProvider>().t('txt_verified_profile'),
                        // ),
                        _buildFeatureItem(
                          Icons.event_busy,
                          context.watch<TranslateProvider>().t('txt_rarely_cancel_rides'),
                        ),
                        _buildFeatureItem(
                          Icons.flash_on,
                          context.watch<TranslateProvider>().t('txt_instant_confirmation'),
                        ),
                        _buildFeatureItem(
                          Icons.directions_car,
                          ride.brand ?? 'MARUTI SWIFT - white',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Contact Driver Button
// Replace your existing OutlinedButton.icon
                  OutlinedButton.icon(
                    onPressed: () async {
                      final token = await LocalCache.getToken();
                      if (token == null || token.isEmpty) {
                        Fluttertoast.showToast(
                          msg: context.read<TranslateProvider>().t('txt_login_first'),
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PhoneNumberScreen()),
                        );
                        return;
                      }

                      // Use ChatProvider to start chat
                      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                      await chatProvider.startChat(
                        context: context,
                        otherUserId: ride.driverId!,
                        userName: ride.driverName ?? 'Driver',
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF008955)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF008955)),
                    label: Text(
                      '${context.watch<TranslateProvider>().t('txt_parcel_contact')} ${ride.driverName ?? ''}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF008955),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Book Button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final token = await LocalCache.getToken();

                  if (token == null || token.isEmpty) {
                     Fluttertoast.showToast(msg: context.read<TranslateProvider>().t('txt_login_first'));
                    return;
                  }

                  final Map<String, dynamic> requestBody = {
                    "ride_id": ride.rideId,
                    "seats_booked": passengers, // ✅ send selected seats
                    "type": bookingType, // ✅ dynamic type
                    "services": services ?? [],
                    "comment": ""
                  };

                  try {
                    final response = await http.post(
                      Uri.parse("https://qadampayk.com/api/book-ride"),
                      headers: {
                        "Authorization": "Bearer $token",
                        "Content-Type": "application/json",
                      },
                      body: jsonEncode(requestBody),
                    );

                    if (response.statusCode == 200) {
                      final data = jsonDecode(response.body);
                      if (data['status'] == true) {
                        Fluttertoast.showToast(
                          msg: data['message'] ?? "${context.read<TranslateProvider>().t('txt_ride_booked_successfully')}",
                          backgroundColor: Colors.green,
                          textColor: Colors.white,
                        );

                        // ✅ Wait a bit so user sees toast, then navigate to home
                        Future.delayed(const Duration(milliseconds: 1200), () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Viewresponcescreen(initialTabIndex: 1), // Opens 2nd tab directly
                            ),
                          );

                        });
                      } else {
                        Fluttertoast.showToast(
                          msg: data['message'] ?? "Booking failed",
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                        );
                      }
                    } else {
                      Fluttertoast.showToast(
                        msg: "Failed: ${response.reasonPhrase}",
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      );
                    }
                  } catch (e) {
                    Fluttertoast.showToast(
                      msg: "Error: $e",
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                    );
                  }
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008955),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.flash_on, color: Colors.white),
                label: Text(
                  context.watch<TranslateProvider>().t('txt_book'),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF008955)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget dottedDivider({
    double height = 1,
    double dashWidth = 4,
    double dashSpacing = 4,
    Color color = Colors.grey,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth;
        final dashCount = (boxWidth / (dashWidth + dashSpacing)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return Container(width: dashWidth, height: height, color: color);
          }),
        );
      },
    );
  }
}
