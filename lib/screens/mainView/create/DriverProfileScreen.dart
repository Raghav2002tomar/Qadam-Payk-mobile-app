// lib/screens/driver_profile_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../providers/translate_provider.dart';
import '../../../service/local_cache.dart';
import '../chat/ChatConversationScreen.dart';
import '../provide/ChatProvider.dart';
import '../search/controller/RideListController.dart';

class DriverProfileScreen extends StatelessWidget {
  final int driverId;

  const DriverProfileScreen({Key? key, required this.driverId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final translate = context.watch<TranslateProvider>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => RideListProvide()..fetchDriverDetail(driverId)),
      ],
      child: Consumer<RideListProvide>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final data = provider.driverData ?? {};
          final chatProvider = Provider.of<ChatProvider>(context, listen: false);

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
                translate.t('txt_parcel_drivers'),
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
                  _buildVehicleCard(context, data, translate),
                  const SizedBox(height: 20),
                  _buildVerificationCard(data, translate),
                  const SizedBox(height: 20),
                  _buildAboutCard(context, data, translate, chatProvider),
                  const SizedBox(height: 20),
                  _buildStatsCard(data, translate),
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
  Widget _buildProfileCard(BuildContext context, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Driver ';
    final rating = data['driver_rating'] ?? '4.5';
    final dobString = data['dob'];
    final vehicle = "${data['brand']}, ${data['model']} " ?? '';
    final image = data['image'] != null
        ? "https://qadampayk.com/assets/profile_image/${data['image']}"
        : 'https://img.freepik.com/premium-vector/vector-flat-illustration-grayscale-avatar-user-profile-person-icon-gender-neutral-silhouette-profile-picture-suitable-social-media-profiles-icons-screensavers-as-templatex9xa_719432-2210.jpg?semt=ais_hybrid&w=740&q=80';

    // Calculate age
    String ageText = '22 ${context.watch<TranslateProvider>().t('txt_y/o')}';
    if (dobString != null && dobString.isNotEmpty) {
      try {
        final dob = DateTime.parse(dobString);
        final today = DateTime.now();
        int age = today.year - dob.year;
        if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) age--;
        ageText = '$age ${context.watch<TranslateProvider>().t('txt_y/o')}';
      } catch (_) {}
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
                  tag: image,
                  child: CircleAvatar(radius: 40, backgroundImage: NetworkImage(image)),
                ),
              ),
           if(data['id_verified'] == 1)   Positioned(
                bottom:0,
                right: -5,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white, // background for contrast
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  padding: const EdgeInsets.all(1),
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
                Text(name, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(ageAndModel, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF666666))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 18, color: Color(0xFFFFC107)),
                    const SizedBox(width: 6),
                    Text("$rating/5 · 19 ${context.watch<TranslateProvider>().t('txt_ratings')}",
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
  Widget _buildVehicleCard(BuildContext context, Map<String, dynamic> data, TranslateProvider translate) {
    final vehicleImage = data['vehicle_image'] != null
        ? "https://qadampayk.com/assets/vehicle_image/${data['vehicle_image']}"
        : "https://images.pexels.com/photos/170811/pexels-photo-170811.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500";
    final brand = data['brand'] ?? '';
    final model = data['model'] ?? '';
    final color = "White";
    final numberPlate = data['number_plate'] ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(translate.t('txt_vehicle')),
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
                      errorBuilder: (context, error, stackTrace) => Image.network(
                        "https://images.pexels.com/photos/170811/pexels-photo-170811.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500",
                        width: 80,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
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
                    Text("${data['vehicle_type'] ?? ''}",
                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF666666))),
                    const SizedBox(height: 4),
                    Text("${context.watch<TranslateProvider>().t('txt_reg_no')} $numberPlate",
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
  Widget _buildVerificationCard(Map<String, dynamic> data, TranslateProvider translate) {
    final idVerified = data['id_verified'] == 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(translate.t('txt_verification')),
        _buildCard(
          child: Column(
            children: [
          if(data['id_verified'] == 1)      _buildVerificationItem(Icons.verified_user, "${translate.t('txt_verified_id')}", idVerified),
              if(data['id_verified'] == 1)   const Divider(),
              _buildVerificationItem(Icons.phone_outlined, "${translate.t('txt_confirm_phone_number')}", true),
            ],
          ),
        ),
      ],
    );
  }

  // 🔹 About Card
  Widget _buildAboutCard(BuildContext context, Map<String, dynamic> data, TranslateProvider translate, ChatProvider chatProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("${translate.t('txt_about')} ${data['name'] ?? ''}"),
        InkWell(
          onTap: () async {
            final driverId = data['driver_id'];
            if (driverId == null) return;

            await chatProvider.startChat(
              context: context,
              otherUserId: driverId,
              userName: data['name'] ?? 'Driver',
            );
          },
          child: _buildCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 20, color: Color(0xFF666666)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data['about'] ?? translate.t('txt_chat'),
                    style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF666666)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  // 🔹 Stats Card
  Widget _buildStatsCard(Map<String, dynamic> data, TranslateProvider translate) {
    final rides = data['ride_count'] ?? 58;
    final memberSince = data['member_since'] ?? "March 2025";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("${translate.t('txt_statistics')}"),
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$rides ${translate.t('txt_publish')}",
                  style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1A1A1A))),
              const SizedBox(height: 8),
              Text("${translate.t('txt_member_since')} $memberSince",
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
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(
            tag: imageUrl,
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
