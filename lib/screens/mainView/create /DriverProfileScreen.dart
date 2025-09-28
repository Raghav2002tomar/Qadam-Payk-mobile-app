// lib/screens/driver_profile_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import '../../../../api_service/api_serviece.dart';
import '../../../../api_service/app_constocter.dart';
import '../search/controller/RideListController.dart';

class DriverProfileScreen extends StatelessWidget {
  final int driverId;

  const DriverProfileScreen({Key? key, required this.driverId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RideListProvide()..fetchDriverDetail(driverId),
      child: Consumer<RideListProvide>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final data = provider.driverData ?? {};

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF008955)),
                onPressed: () => Navigator.pop(context),
              ),
              systemOverlayStyle: SystemUiOverlayStyle.dark,
              title: Text(
                data['name'] ?? "Driver Profile",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileCard(context, data),
                  const SizedBox(height: 20),
                  _buildVehicleCard(context, data),
                  const SizedBox(height: 20),
                  _buildVerificationCard(data),
                  const SizedBox(height: 20),
                  _buildAboutCard(data),
                  const SizedBox(height: 20),
                  _buildStatsCard(data),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 🔹 Profile Card
  Widget _buildProfileCard(context, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Amit';
    final rating = data['driver_rating'] ?? '4.5';
    final dobString = data['dob']; // Expecting format like "yyyy-MM-dd"
    final vehicle = data['vehicle_type'] ?? 'Ambassador';
    final image = "https://qadampayk.com/assets/profile_image/${data['image']}" ??
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop&crop=face';

    // Calculate age
    String ageText = '';
    if (dobString != null && dobString.isNotEmpty) {
      try {
        final dob = DateTime.parse(dobString);
        final today = DateTime.now();
        int age = today.year - dob.year;
        if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
          age--; // Not had birthday yet this year
        }
        ageText = '$age y/o';
      } catch (e) {
        ageText = '22 y/o'; // fallback
      }
    } else {
      ageText = '22 y/o'; // default
    }

    final ageAndModel = '$ageText · $vehicle';

    return _buildCard(
      child: Row(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImage(imageUrl: image),
                    ),
                  );
                },
                child: Hero(
                  tag: image, // same tag as in FullScreenImage
                  child: CircleAvatar(radius: 40, backgroundImage: NetworkImage(image)),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF008955),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(ageAndModel, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF666666))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 18, color: Color(0xFFFFC107)),
                    const SizedBox(width: 6),
                    Text("$rating/5 · 19 ratings",
                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF666666))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Vehicle Card
  Widget _buildVehicleCard(context, Map<String, dynamic> data) {
    final vehicleImage = "https://qadampayk.com/assets/vehicle_image/${data['vehicle_image']}" ??
        "https://images.pexels.com/photos/170811/pexels-photo-170811.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500";
    final brand = data['brand'] ?? 'Maruti Suzuki';
    final model = data['model'] ?? 'Swift';
    final color = "White";
    final numberPlate = data['number_plate'] ?? "DL 05 AB 1234";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Vehicle"),
        _buildCard(
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImage(imageUrl: vehicleImage),
                    ),
                  );
                },
                child: Hero(
                  tag: vehicleImage,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      vehicleImage,
                      width: 80,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.network(
                          "https://images.pexels.com/photos/170811/pexels-photo-170811.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500%22",
                          width: 80,
                          height: 60,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$brand $model",
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                    const SizedBox(height: 4),
                    Text("$color · ${data['vehicle_type'] ?? '2019 Model'}",
                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF666666))),
                    const SizedBox(height: 4),
                    Text("Reg. No: $numberPlate",
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF008955))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🔹 Verification Card
  Widget _buildVerificationCard(Map<String, dynamic> data) {
    final idVerified = data['id_verified'] == 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Verification"),
        _buildCard(
          child: Column(
            children: [
              _buildVerificationItem(Icons.verified_user, "Verified ID", idVerified),
              // const Divider(),
              // _buildVerificationItem(Icons.email_outlined, "Confirmed Email", true),
              const Divider(),
              _buildVerificationItem(Icons.phone_outlined, "Confirmed Phone Number", true),
            ],
          ),
        ),
      ],
    );
  }

  // 🔹 About Card
  Widget _buildAboutCard(Map<String, dynamic> data) {
    final about = data['about'] ?? "I'm chatty when I feel comfortable.";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("About ${data['name'] ?? 'Amit'}"),
        _buildCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.chat_bubble_outline, size: 20, color: Color(0xFF666666)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(about, style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF666666))),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🔹 Stats Card
  Widget _buildStatsCard(Map<String, dynamic> data) {
    final rides = data['ride_count'] ?? 58;
    final memberSince = data['member_since'] ?? "March 2020";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Statistics"),
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$rides published and completed rides",
                  style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1A1A1A))),
              const SizedBox(height: 8),
              Text("Member since $memberSince",
                  style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF008955), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  // 🔹 Section Title
  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)));
  }

  // 🔹 Card Wrapper
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  // 🔹 Verification item row
  Widget _buildVerificationItem(IconData icon, String text, bool isVerified) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isVerified ? const Color(0xFF008955) : const Color(0xFFE0E0E0),
            shape: BoxShape.circle,
          ),
          child: Icon(isVerified ? Icons.check : icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1A1A1A), fontWeight: FontWeight.w500))),
      ],
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context), // tap to close
        child: Center(
          child: Hero(
            tag: imageUrl, // for smooth transition
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
