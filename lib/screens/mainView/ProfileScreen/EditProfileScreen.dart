import 'dart:convert';
import 'dart:io';
import 'package:bla_bla_car/providers/translate_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../api_service/logger.dart';
import '../../../models/UserProfileModel.dart';
import '../../../service/local_cache.dart';
import '../../auth/SignInScreen.dart';
import '../../auth/controller/auth_provider.dart';
import '../create/Add_vehical.dart';

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  _ProfileManagementScreenState createState() =>
      _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  UserProfile? _user;
  bool _isLoading = true;
  String? _profileImage;
  bool _isEditing = false;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String? _selectedGender;

  // Government ID files
  File? _govIdFront;
  File? _govIdBack;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  void _initializeAnimations() {
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

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    _dobController.dispose();
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
          _nameController.text = _user!.name ?? "";
          _dobController.text = _user!.dob ?? "";
          _selectedGender = _normalizeGender(_user!.gender);
          _isLoading = false;
        });

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

  String _normalizeGender(String? gender) {
    if (gender == null) return "Male";
    switch (gender.trim().toLowerCase()) {
      case "male":
        return "Male";
      case "female":
        return "Female";
      default:
        return "Other";
    }
  }



  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);

    final XFile? photo = await _picker.pickImage(source: source);
    if (photo == null) return;

    final directory = await getApplicationDocumentsDirectory();

    // Compressed file path
    final String targetPath =
        "${directory.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg";

    // COMPRESS IMAGE
    final XFile? compressedXFile =
    await FlutterImageCompress.compressAndGetFile(
      photo.path,
      targetPath,
      quality: 60,
      minWidth: 1000,
      minHeight: 1000,
    );

    // Convert XFile to File
    final File compressedFile =
    compressedXFile != null ? File(compressedXFile.path) : File(photo.path);

    setState(() {
      _profileImage = compressedFile.path;
      _user = _user?.copyWith(image: compressedFile.path);
    });
  }

  Future<void> _pickGovIdImage({required bool isFront}) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isFront) {
          _govIdFront = File(picked.path);
        } else {
          _govIdBack = File(picked.path);
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    // appLog(DateFormat('dd-MM-yyyy').format(DateTime.parse(_dobController.text)));
    final token = await LocalCache.getToken();
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://qadampayk.com/api/update-profile"),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add text fields
      request.fields['name'] = _nameController.text;
      request.fields['dob'] = _dobController.text;
      request.fields['gender'] = (_selectedGender ?? "").toLowerCase();

      // Add profile image if selected
      if (_profileImage != null && File(_profileImage!).existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath('profile_image', _profileImage!),
        );
      }
      // ✅ DEBUG LOGGING (Print everything sent)
      appLog("🔹 Sending Profile Update Request:");
      appLog("Name: ${request.fields['name']}");
      appLog("DOB: ${request.fields['dob']}");
      appLog("Gender: ${request.fields['gender']}");
      appLog("Headers: ${request.headers}");
      appLog("Token: $token");
      appLog(
        "Files Attached: ${request.files.isNotEmpty ? request.files.map((f) => f.filename).join(", ") : "No File"}",
      );

      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<TranslateProvider>().t(
                'txt_profile_updated_successfully',
              ),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() => _isEditing = false);
        _loadProfile(); // Reload profile data
      } else {
        appLog("Error updating profile: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<TranslateProvider>().t('txt_error_failed_to_upload'),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      appLog("Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<TranslateProvider>().t('txt_error_updating'),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int _calculateAge(String dobString) {
    try {
      // ✅ Parse dd-MM-yyyy format properly
      final dob = DateFormat('dd-MM-yyyy').parse(dobString);
      final today = DateTime.now();
      int age = today.year - dob.year;

      if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  void _showImagePickerBottomSheet() {
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
              context.watch<TranslateProvider>().t('txt_update_profile_photo'),
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
                  label: context.watch<TranslateProvider>().t('txt_camera'),
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildPhotoOption(
                  icon: Icons.photo_library,
                  label: context.watch<TranslateProvider>().t('txt_gallery'),
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
                SizedBox(height: 16),
                Text(
                  context.watch<TranslateProvider>().t('txt_loading_profile'),
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
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF008955),
            flexibleSpace: FlexibleSpaceBar(
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
                      const SizedBox(height: 40),
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
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isEditing ? Icons.close : Icons.edit,
                  color: Colors.white,
                ),
                onPressed: () => setState(() => _isEditing = !_isEditing),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildPersonalInfoCard(),
                      const SizedBox(height: 20),
                      _buildStatsCard(),
                      const SizedBox(height: 20),
                      _buildQuickActionsCard(),
                      const SizedBox(height: 20),
                      if (_isEditing) _buildSaveButton(),
                      if (_isEditing) const SizedBox(height: 20),
                      _buildLogoutCard(),
                      SizedBox(height: 20),
                      _buildDeleteAccountCard(),
                      const SizedBox(height: 40),
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
    return Stack(
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
            radius: 50,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 46,
              backgroundImage: _getProfileImageProvider(),
              child: _getProfileImageProvider() == null
                  ? const Icon(Icons.person, size: 50, color: Color(0xFF008955))
                  : null,
            ),
          ),
        ),
      if(_isEditing)  Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _showImagePickerBottomSheet,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 18,
                color: Color(0xFF008955),
              ),
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider? _getProfileImageProvider() {
    if (_profileImage == null || _profileImage!.isEmpty) {
      return null;
    }

    if (_profileImage!.startsWith('http')) {
      // Already a full URL
      return NetworkImage(_profileImage!);
    } else if (_profileImage!.startsWith('/')) {
      // Local file path (newly selected image)
      final file = File(_profileImage!);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } else {
      // API image path - prepend base URL
      final fullImageUrl =
          'https://qadampayk.com/assets/profile_image/$_profileImage';
      return NetworkImage(fullImageUrl);
    }
    return null;
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF008955).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF008955),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                context.watch<TranslateProvider>().t(
                  'txt_personal_information',
                ),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isEditing) ...[
            _buildModernTextField(
              context.watch<TranslateProvider>().t('txt_full_name'),
              _nameController,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                DateTime initialDate = DateTime.now().subtract(
                  const Duration(days: 365 * 20),
                );

                // ✅ Parse dd-MM-yyyy format properly
                if (_dobController.text.isNotEmpty) {
                  try {
                    initialDate = DateFormat(
                      'dd-MM-yyyy',
                    ).parse(_dobController.text);
                  } catch (_) {}
                }

                final picked = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );

                if (picked != null) {
                  // ✅ Always set dd-MM-yyyy everywhere
                  _dobController.text = DateFormat('dd-MM-yyyy').format(picked);
                }
              },
              child: AbsorbPointer(
                child: _buildModernTextField(
                  context.watch<TranslateProvider>().t('txt_date_of_birth'),
                  _dobController,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildModernGenderDropdown(),
            const SizedBox(height: 16),
          ] else ...[
            _buildInfoRow(
              Icons.person,
              context.watch<TranslateProvider>().t('txt_name'),
              _user?.name ?? "*******",
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.cake,
              context.watch<TranslateProvider>().t('txt_age'),
              _user?.dob != null
                  ? _calculateAge(_user!.dob!).toString()
                  : "*******",
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.people,
              context.watch<TranslateProvider>().t('txt_gender'),
              _user?.gender ?? "*******",
            ),
          ],
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.phone,
            context.watch<TranslateProvider>().t('txt_phone_number'),
            _user?.phoneNumber ?? "*******",
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF008955)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF666666),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField(String label, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            color: const Color(0xFF666666),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildModernGenderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: InputDecoration(
          labelText: context.watch<TranslateProvider>().t('txt_gender'),
          labelStyle: GoogleFonts.inter(
            color: const Color(0xFF666666),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
        ),
        items: [
          DropdownMenuItem(
            value: "Male",
            child: Text(context.watch<TranslateProvider>().t('txt_male')),
          ),
          DropdownMenuItem(
            value: "Female",
            child: Text(context.watch<TranslateProvider>().t('txt_female')),
          ),
          DropdownMenuItem(
            value: "Other",
            child: Text(context.watch<TranslateProvider>().t('txt_other')),
          ),
        ],
        onChanged: (val) => setState(() => _selectedGender = val),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF008955).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFF008955),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                context.watch<TranslateProvider>().t('txt_your_stats'),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context.watch<TranslateProvider>().t('txt_tips'),
                  "0",
                  Icons.stars,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context.watch<TranslateProvider>().t('txt_rides'),
                  "0",
                  Icons.directions_car,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context.watch<TranslateProvider>().t('txt_points'),
                  "0",
                  Icons.loyalty,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF008955), size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF008955).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flash_on_outlined,
                  color: Color(0xFF008955),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                context.watch<TranslateProvider>().t('txt_quick_actions'),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            icon: Icons.directions_car,
            title: context.watch<TranslateProvider>().t('txt_add_vehicle'),
            subtitle: context.watch<TranslateProvider>().t(
              'txt_register_your_vehicle',
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VehicleScreen()),
              );
            },
          ),
          // const SizedBox(height: 12),
          // _buildActionTile(
          //   icon: Icons.payment,
          //   title: context.watch<TranslateProvider>().t('txt_payment_methods'),
          //   subtitle: context.watch<TranslateProvider>().t('txt_manage_your_payment'),
          //   onTap: () {
          //     // Navigate to payment screen
          //   },
          // ),
          const SizedBox(height: 12),
          // _buildActionTile(
          //   icon: Icons.settings,
          //   title: context.watch<TranslateProvider>().t('txt_settings'),
          //   subtitle: context.watch<TranslateProvider>().t(
          //     'txt_app_preference_privacy',
          //   ),
          //   onTap: () {
          //     // Navigate to settings screen
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF008955).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF008955), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  // const SizedBox(height: 2),
                  // Text(
                  //   subtitle,
                  //   style: GoogleFonts.inter(
                  //     fontSize: 13,
                  //     color: const Color(0xFF666666),
                  //   ),
                  // ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF666666), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF008955), Color(0xFF00A562)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF008955).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _saveProfile,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  context.watch<TranslateProvider>().t('txt_save_changes'),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
            final loginProvider = Provider.of<LoginProvider>(
              context,
              listen: false,
            );
            await loginProvider.logout(context);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.logout, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.watch<TranslateProvider>().t('txt_logout'),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.red, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                context.watch<TranslateProvider>().t('txt_delete_account'),
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
              content: Text(
                context.watch<TranslateProvider>().t('txt_delete_account_confirmation'),
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
                    context.watch<TranslateProvider>().t('txt_delete'),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );

          if (confirm != true) return;

          // Call the delete account API
          final authToken = await LocalCache.getToken();
          const baseUrl = "https://qadampayk.com/api/delete-account";

          try {
            final res = await http.post(
              Uri.parse(baseUrl),
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $authToken',
              },
            );

            final jsonRes = jsonDecode(res.body);
            if (res.statusCode == 200 && jsonRes['status'] == true) {
              // Account deleted successfully, clear token and navigate to login
              await LocalCache.logout();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(jsonRes['message'] ?? 'Account deleted.')),
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PhoneNumberScreen()),
                );              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(jsonRes['message'] ?? 'Failed to delete account.')),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.watch<TranslateProvider>().t('txt_delete_account'),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.red, size: 20),
            ],
          ),
        ),
      ),
    );
  }

}
