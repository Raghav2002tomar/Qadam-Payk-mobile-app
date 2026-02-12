import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../api_service/app_constocter.dart';
import '../../../api_service/logger.dart';
import '../../../models/UserProfileModel.dart';
import '../../../providers/translate_provider.dart';
import '../../../service/colors.dart';
import '../../../service/local_cache.dart';
import '../../auth/controller/auth_provider.dart';
import '../../courier/create_courier_screen.dart';
import '../../notification/screens/NotificationScreen.dart';
import 'EditProfileScreen.dart';
import 'PrivacyPolicyScreen.dart';
import 'QueryScreen.dart';
import 'TermsConditionsScreen.dart';
import 'ViewResponceScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  UserProfile? _user;
  bool _isLoading = true;
  String? _profileImage;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _updateLanguage(String lang) async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = "unknown";
    // final deviceId = await LocalCache.getDeviceId(); // Or wherever you store it
    final deviceType = Platform.isAndroid ? "android" : "ios";
    final token = await LocalCache.getToken();


    try {
      final response = await http.post(
        Uri.parse("https://qadampayk.com/api/update-language"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: {
          "language": lang,
          "device_id": deviceId,
          "device_type": deviceType,
        },
      );

      if (response.statusCode == 200) {
        context.read<TranslateProvider>().setLocale(lang); // ✅ Update app language
        // Fluttertoast.showToast(msg: "Language updated successfully");
      } else {
        // Fluttertoast.showToast(msg: "Failed to update language");
      }
    } catch (e) {
      // Fluttertoast.showToast(msg: "Error updating language");
    }
  }


  Future<void> _loadProfile() async {
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    loginProvider.setLoading(true);

    try {
      final success = await loginProvider.fetchProfile();
      if (success && loginProvider.profile != null) {
        setState(() {
          _user = loginProvider.profile!;
          _profileImage = _user!.image;
          _isLoading = false;
        });

        // Start animations
        _fadeController.forward();
        _slideController.forward();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      appLog("Error loading profile: $e");
    } finally {
      loginProvider.setLoading(false);
    }
  }




  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final XFile? photo = await _picker.pickImage(source: source);
    if (photo != null) {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/${photo.name}';
      await File(photo.path).copy(path);
      setState(() {
        _profileImage = path;
        _user = _user?.copyWith(image: path);
      });
    }
  }

  void _saveProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileManagementScreen())
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: RefreshIndicator(
          onRefresh: _loadProfile, // your async refresh function
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(), // required for pull-to-refresh
            slivers: [
              // Custom SliverAppBar with gradient
              SliverAppBar(
                automaticallyImplyLeading: false,
                expandedHeight: 220,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF008955),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    "",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF008955), Color(0xFF00A562)],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildProfileAvatar(_user?.idVerified.toString()),
                          ),
                          const SizedBox(height: 16),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Text(
                              _user?.name ?? 'User',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.phone, size: 16, color: Colors.white70),
                                const SizedBox(width: 6),
                                Text(
                                  _user?.phoneNumber ?? "No Phone",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildAccountOptionsCard(),
                          const SizedBox(height: 20),
                          _buildLogoutCard(),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_user == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF008955), Color(0xFFF8F9FA)],
              stops: [0.0, 0.4],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 64),
                SizedBox(height: 16),
                Text(
                  context.watch<TranslateProvider>().t('txt_no_user_data'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Custom SliverAppBar with gradient
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF008955),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF008955), Color(0xFF00A562)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // const SizedBox(height: 60),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildProfileAvatar( _user?.idVerified.toString()),
                      ),
                      const SizedBox(height: 16),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          _user?.name ?? 'User',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.phone, size: 16, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              _user?.phoneNumber ?? "No Phone",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildAccountOptionsCard(),
                      const SizedBox(height: 20),
                      _buildLogoutCard(),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(String? verify  ) {

    String? imageUrl;
    if ((_profileImage ?? '').isNotEmpty) {
      if (_profileImage!.startsWith('http')) {
        imageUrl = _profileImage; // full URL already
      } else {
        imageUrl = 'https://qadampayk.com/assets/profile_image/${_profileImage!}';
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 55,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 51,
              backgroundImage: (imageUrl ?? '').isNotEmpty
                  ? NetworkImage(imageUrl!)
                  : null,
              child: (imageUrl ?? '').isEmpty
                  ? const Icon(
                Icons.person,
                size: 55,
                color: Color(0xFF008955),
              )
                  : null,
            ),
          ),
        ),

        // ✅ Verify badge
        // if (verify == "true")
        //   Positioned(
        //     bottom: 0,
        //     right: 5,
        //     child: Container(
        //       width: 28,
        //       height: 28,
        //       decoration: BoxDecoration(
        //         shape: BoxShape.circle,
        //         color: Colors.white, // white border
        //       ),
        //       padding: const EdgeInsets.all(4),
        //       child: ClipOval(
        //         child: Image.asset(
        //           "assets/images/verify_user.png",
        //           fit: BoxFit.cover,
        //         ),
        //       ),
        //     ),
        //   ),
      ],
    );
  }

  Widget _buildAccountOptionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildModernTile(
            Icons.person_outline,
            context.watch<TranslateProvider>().t('txt_profile_management'),
            context.watch<TranslateProvider>().t('txt_edit_your_personal_info'),
            onTap: _saveProfile,
          ),
          _buildDivider(),
          _buildModernTile(
            Icons.view_agenda_outlined,
            context.watch<TranslateProvider>().t('txt_view_responce'),
            context.watch<TranslateProvider>().t('txt_edit_your_personal_info'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Viewresponcescreen()),
              );
            },
          ),
          _buildDivider(),
          _buildModernTile(
            Icons.newspaper_outlined,
            context.watch<TranslateProvider>().t('txt_news_announcements'),
            context.watch<TranslateProvider>().t('txt_edit_your_personal_info'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationScreen()),
              );
            },
          ),
          _buildDivider(),
          _buildModernTile(
            Icons.privacy_tip_outlined,
            context.watch<TranslateProvider>().t('Create Courier'),
            context.watch<TranslateProvider>().t('txt_view_term_and_conditions'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateCourierScreen()),
              );
            },
          ),
          _buildDivider(),
          _buildModernTile(
            Icons.privacy_tip_outlined,
            context.watch<TranslateProvider>().t('txt_term_and_conditions'),
            context.watch<TranslateProvider>().t('txt_view_term_and_conditions'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TermsConditionsScreen()),
              );
            },
          ),
          _buildDivider(),
          _buildModernTile(
            Icons.privacy_tip_outlined,
            context.watch<TranslateProvider>().t('txt_privacy_policy'),
            context.watch<TranslateProvider>().t('txt_view_privacy_policy'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
              );
            },
          ),
          _buildDivider(),
          _buildModernTile(
            Icons.question_answer_outlined,
            context.watch<TranslateProvider>().t('txt_view_query'),
            context.watch<TranslateProvider>().t('txt_send_query'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QueryScreen()),
              );
            },
          ),

          // _buildDivider(),
          // _buildModernTile(
          //   Icons.settings_outlined,
          //   context.watch<TranslateProvider>().t('txt_settings'),
          //   context.watch<TranslateProvider>().t('txt_app_preference_privacy'),
          // ),
          _buildDivider(),
          _buildLanguageTile(),
        ],
      ),
    );
  }

  Widget _buildModernTile(
      IconData icon,
      String title,
      String subtitle, {
        VoidCallback? onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF008955).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF008955),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),

                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF666666),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF008955).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.language,
              color: Color(0xFF008955),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.watch<TranslateProvider>().t('txt_language'),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                // const SizedBox(height: 2),
                // Text(
                //   context.watch<TranslateProvider>().t('txt_choose_your_language'),
                //   style: GoogleFonts.inter(
                //     fontSize: 13,
                //     color: const Color(0xFF666666),
                //   ),
                // ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF008955).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF008955),
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
            onSelected: (lang) => _updateLanguage(lang),  // ✅ Updated here
            itemBuilder: (context) => [
              if (App_Constructor().istestmode)
                PopupMenuItem(
                  value: 'en',
                  child: Row(
                    children: [
                      const Icon(Icons.language, color: Color(0xFF008955), size: 18),
                      const SizedBox(width: 8),
                      Text('English', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'ru',
                child: Row(
                  children: [
                    const Icon(Icons.language, color: Color(0xFF008955), size: 18),
                    const SizedBox(width: 8),
                    Text('Русский', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'tj',
                child: Row(
                  children: [
                    const Icon(Icons.language, color: Color(0xFF008955), size: 18),
                    const SizedBox(width: 8),
                    Text('Тоҷикӣ', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildLogoutCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                context.watch<TranslateProvider>().t('txt_logout'),
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
              content: Text(
                context.watch<TranslateProvider>().t('txt_logout_confirmation'),
                style: GoogleFonts.inter(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    context.watch<TranslateProvider>().t('txt_cancel'),
                    style: GoogleFonts.inter(color: const Color(0xFF666666)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    context.watch<TranslateProvider>().t('txt_logout'),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );

          if (result == true) {
            final loginProvider = Provider.of<LoginProvider>(context, listen: false);
            await loginProvider.logout(context);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.logout, color: Colors.red, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.watch<TranslateProvider>().t('txt_logout'),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    // const SizedBox(height: 2),
                    // Text(
                    //   context.watch<TranslateProvider>().t('txt_sign_out_account'),
                    //   style: GoogleFonts.inter(
                    //     fontSize: 13,
                    //     color: const Color(0xFF666666),
                    //   ),
                    // ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.red, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 1,
      color: const Color(0xFFF0F0F0),
    );
  }
}