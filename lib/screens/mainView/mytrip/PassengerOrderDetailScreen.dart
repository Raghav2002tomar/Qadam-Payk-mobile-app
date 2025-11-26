// lib/screens/passenger_order_detail_screen.dart
import 'dart:convert';

import 'package:bla_bla_car/providers/translate_provider.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../api_service/api_serviece.dart';
import '../../../api_service/app_constocter.dart';
import '../../../service/local_cache.dart';
import '../../auth/SignInScreen.dart';
import '../ProfileScreen/ViewResponceScreen.dart';
import '../create/DriverProfileScreen.dart';
import '../provide/ChatProvider.dart';
import '../search/model/ride_model.dart';

class PassengerOrderDetailScreen extends StatelessWidget {
  final RideRequestModel request;

  const PassengerOrderDetailScreen({super.key, required this.request});




  Future<void> sendInterestRequest(String requestId, BuildContext context) async {
    final Api_Service apiService = Api_Service();
    final App_Constructor appConstructor = App_Constructor();
    final url = Uri.parse('${appConstructor.BaseURL}${appConstructor.driverintrestrequest}');

    // 🔑 Get token dynamically if possible
    final token = await LocalCache.getToken();

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: {
          "request_id": requestId,
        },
      );

      debugPrint("API Status Code: ${response.statusCode}");
      debugPrint("API Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data['status'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.read<TranslateProvider>().t('txt_interest_request_sent_success'))),
          );
          // Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const Viewresponcescreen(initialTabIndex: 1), // Opens 2nd tab directly
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("⚠️ ${data['message']}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${context.read<TranslateProvider>().t('txt_error')} ${response.statusCode}")),
        );
      }
    } catch (e) {
      debugPrint("❌ API Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<TranslateProvider>().t('txt_failed_to_send'))),
      );
    }
  }



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
          request.rideDate != null
              ? DateFormat(
                  'EEEE, dd MMMM',
                ).format(DateFormat('dd-MM-yyyy').parse(request.rideDate!))
              : 'Ride Date',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Passenger Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 65,
                          height: 65,
                          child: Stack(
                            clipBehavior: Clip.none, // allows badge to overflow
                            children: [
                              // Main profile image
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(
                                  request.image != null
                                      ? "https://qadampayk.com/assets/profile_image/${request.image}"
                                      : "https://images.rawpixel.com/image_png_800/cHJpdmF0ZS9sci9pbWFnZXMvd2Vic2l0ZS8yMDI0LTAxL3Jhd3BpeGVsb2ZmaWNlMTFfcGhvdG9fb2ZfYWZyaWNhbl9hbWVyaWNhbl9tYW5faW5fYnVzaW5lc3Nfc3VpdF9iYmEzZjA3MS1iN2JkLTQ3MjctODA4MC1hYjJmOTIxOGY1OTMucG5n.png",
                                ),
                              ),

                              // Verify badge
                              if (request.idVerified.toString() == "1")
                                Positioned(
                                  bottom: -4,
                                  right: -4,
                                  child: Container(
                                    padding: EdgeInsets.all(2), // white border
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white, // background for contrast
                                    ),
                                    child: Image.asset(
                                      "assets/images/verify_user.png",
                                      height: 22,
                                      width: 22,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.name ?? 'Passenger',
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${context.watch<TranslateProvider>().t('txt_seats')} ${request.numberOfSeats ?? 1}",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF666666),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: request.status == 'pending'
                                      ? Colors.orange.shade100
                                      : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  request.status?.toUpperCase() ?? 'PENDING',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: request.status == 'pending'
                                        ? Colors.orange.shade800
                                        : Colors.green.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Pickup → Destination
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
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
                                request.pickupLocation ?? context.watch<TranslateProvider>().t('txt_pickup_location'),
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
                                request.destination ?? context.watch<TranslateProvider>().t('txt_destination'),
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

                  // Price / Seat Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${request.numberOfSeats ?? 1} ${context.watch<TranslateProvider>().t('txt_passengers')}(s)',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: const Color(0xFF666666),
                          ),
                        ),
                        // Text(
                        //   '₹${request.p ?? 500}',
                        //   style: GoogleFonts.inter(
                        //     fontSize: 20,
                        //     fontWeight: FontWeight.w700,
                        //     color: const Color(0xFF1A1A1A),
                        //   ),
                        // ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Driver Info Card
                  InkWell(
                    onTap: () {
                      print("fghjklkjnb");
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
                                  "https://qadampayk.com/assets/profile_image/${request.fullImageUrl}" ??
                                      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
                                ),
                              ),
                            if(request.idVerified =="1")  Positioned(
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
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.displayName ?? "Driver",
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
                                      '13/5 - ${context.watch<TranslateProvider>().t('txt_ratings')}',
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
                          InkWell(
                            onTap: () {
                              print("fdsdf");
                            },
                            child: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Add this inside your Column in SingleChildScrollView (before Contact Button)
                  if ((request.parcelDetails != null &&
                          request.parcelDetails!.isNotEmpty) ||
                      (request.parcelImages != null &&
                          request.parcelImages!.isNotEmpty)) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.watch<TranslateProvider>().t('txt_parcel_details'),
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Parcel description
                          if (request.parcelDetails != null &&
                              request.parcelDetails!.isNotEmpty)
                            Text(
                              request.parcelDetails!,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: const Color(0xFF666666),
                              ),
                            ),

                          const SizedBox(height: 12),

                          // Pickup / Drop Contact Info for parcel
                          if (request.pickupContactName != null ||
                              request.dropContactName != null) ...[
                            if (request.pickupContactName != null)
                              Text(
                                "${context.watch<TranslateProvider>().t('txt_pickup_contact')}: ${request.pickupContactName} ",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            if (request.dropContactName != null)
                              Text(
                                "${context.watch<TranslateProvider>().t('txt_drop_contact')}: ${request.dropContactName} ",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            const SizedBox(height: 12),
                          ],

                          // Parcel Images
                          if (request.parcelImages != null &&
                              request.parcelImages!.isNotEmpty) ...[
                             Text(
                              context.watch<TranslateProvider>().t('txt_parcel_iamges'),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 80,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: request.parcelImages!
                                    .split(',')
                                    .length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final imageUrl = request.parcelImages!
                                      .split(',')[index]
                                      .trim();
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      imageUrl,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        // Fallback image in case of error
                                        return Image.network(
                                          'https://www.shutterstock.com/image-photo/above-table-top-view-female-260nw-1831476562.jpg', // <-- add your placeholder image here
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  // Features
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: Column(
                      children: [
                        _buildFeatureItem(
                          Icons.verified_user,
                          context.watch<TranslateProvider>().t('txt_verified_profile'),
                        ),
                        _buildFeatureItem(
                          Icons.event_busy,
                          context.watch<TranslateProvider>().t('txt_rarely_cancel_rides'),
                        ),
                        _buildFeatureItem(
                          Icons.flash_on,
                          context.watch<TranslateProvider>().t('txt_instant_confirmation'),
                        ),
                        // _buildFeatureItem(Icons.directions_car, request.brand ?? 'Car Info'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Contact Button
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
                        otherUserId: request.userId!, // <-- crash happens if driverId is null
                        userName: request.displayName ?? 'Driver',
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
                      '${context.watch<TranslateProvider>().t('txt_parcel_contact')} ${request.displayName ?? ''}',
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

          // Book / Accept Button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  sendInterestRequest(request.id.toString(), context); // pass the actual requestId dynamically

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
                  context.watch<TranslateProvider>().t('txt_book_or_accept'),
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
