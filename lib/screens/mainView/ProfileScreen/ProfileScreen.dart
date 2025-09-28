import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../models/UserProfileModel.dart';
import '../../../providers/translate_provider.dart';
import '../../../service/colors.dart';
import '../../auth/controller/auth_provider.dart';
import 'EditProfileScreen.dart';

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
      debugPrint("Error loading profile: $e");
    } finally {
      loginProvider.setLoading(false);
    }
  }

  Future<void> _pickProfilePhoto() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Update Profile Photo',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPhotoOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildPhotoOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF008955).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF008955).withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF008955), size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: const Color(0xFF008955),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
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
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF008955), Color(0xFFF8F9FA)],
              stops: [0.0, 0.4],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
                SizedBox(height: 16),
                Text(
                  'Loading your profile...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 64),
                SizedBox(height: 16),
                Text(
                  "No user data available",
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
                        child: _buildProfileAvatar(),
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

  Widget _buildProfileAvatar() {
    String? imageUrl;
    if ((_profileImage ?? '').isNotEmpty) {
      if (_profileImage!.startsWith('http')) {
        imageUrl = _profileImage; // full URL already
      } else {
        imageUrl = 'https://qadampayk.com/assets/profile_image/${_profileImage!}';
      }
    }

    return Container(
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
            "Profile Management",
            "Edit your personal information",
            onTap: _saveProfile,
          ),
          _buildDivider(),
          _buildModernTile(
            Icons.shopping_bag_outlined,
            "My Orders",
            "View your order history",
          ),
          _buildDivider(),
          _buildModernTile(
            Icons.favorite_border,
            "Wishlist",
            "Your saved favorites",
          ),
          _buildDivider(),
          _buildModernTile(
            Icons.settings_outlined,
            "Settings",
            "App preferences and privacy",
          ),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF666666),
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
                  context.watch<TranslateProvider>().t('language'),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Choose your preferred language",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF666666),
                  ),
                ),
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
            onSelected: (lang) => context.read<TranslateProvider>().setLocale(lang),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'en',
                child: Row(
                  children: [
                    const Icon(Icons.language, color: Color(0xFF008955), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'English',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'ru',
                child: Row(
                  children: [
                    const Icon(Icons.language, color: Color(0xFF008955), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Русский',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'tg',
                child: Row(
                  children: [
                    const Icon(Icons.language, color: Color(0xFF008955), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Тоҷикӣ',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
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
                "Logout",
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
              content: Text(
                "Are you sure you want to logout?",
                style: GoogleFonts.inter(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    "Cancel",
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
                    "Logout",
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
                      "Logout",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Sign out of your account",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF666666),
                      ),
                    ),
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