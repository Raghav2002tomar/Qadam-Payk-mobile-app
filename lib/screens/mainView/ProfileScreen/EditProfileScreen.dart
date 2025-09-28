import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../models/UserProfileModel.dart';
import '../../../service/local_cache.dart';
import '../../auth/controller/auth_provider.dart';
import '../create /Add_vehical.dart';

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  _ProfileManagementScreenState createState() => _ProfileManagementScreenState();
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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
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
      debugPrint("Error loading profile: $e");
    } finally {
      loginProvider.setLoading(false);
    }
  }

  String _normalizeGender(String? gender) {
    if (gender == null) return "Male";
    switch (gender.trim().toLowerCase()) {
      case "male": return "Male";
      case "female": return "Female";
      default: return "Other";
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
        request.files.add(await http.MultipartFile.fromPath(
          'profile_image',
          _profileImage!,
        ));
      }

      // // Add government ID images if selected
      // if (_govIdFront != null && _govIdFront!.existsSync()) {
      //   request.files.add(await http.MultipartFile.fromPath(
      //     'government_id[]',
      //     _govIdFront!.path,
      //   ));
      // }
      //
      // if (_govIdBack != null && _govIdBack!.existsSync()) {
      //   request.files.add(await http.MultipartFile.fromPath(
      //     'government_id[]',
      //     _govIdBack!.path,
      //   ));
      // }

      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() => _isEditing = false);
        _loadProfile(); // Reload profile data
      } else {
        debugPrint("Error updating profile: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to update profile"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error updating profile"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int _calculateAge(String dobString) {
    try {
      final dob = DateTime.parse(dobString);
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
        Positioned(
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
      final fullImageUrl = 'https://qadampayk.com/assets/profile_image/$_profileImage';
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
                'Personal Information',
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
            _buildModernTextField("Full Name", _nameController),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 20));
                if (_dobController.text.isNotEmpty) {
                  initialDate = DateTime.tryParse(_dobController.text) ?? initialDate;
                }
                final picked = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  _dobController.text = picked.toIso8601String().split('T').first;
                }
              },
              child: AbsorbPointer(
                child: _buildModernTextField("Date of Birth", _dobController),
              ),
            ),
            const SizedBox(height: 16),
            _buildModernGenderDropdown(),
            const SizedBox(height: 16),
            _buildGovernmentIdSection(),
          ] else ...[
            _buildInfoRow(Icons.person, "Name", _user?.name ?? "Not provided"),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.cake,
              "Age",
              _user?.dob != null ? _calculateAge(_user!.dob!).toString() : "Not provided",
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.people, "Gender", _user?.gender ?? "Not specified"),
          ],
          const SizedBox(height: 16),
          _buildInfoRow(Icons.phone, "Phone", _user?.phoneNumber ?? "Not provided"),
        ],
      ),
    );
  }

  Widget _buildGovernmentIdSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Government ID",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _pickGovIdImage(isFront: true),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: _govIdFront != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_govIdFront!, fit: BoxFit.cover),
                  )
                      : const Center(child: Text("Upload Front Side")),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _pickGovIdImage(isFront: false),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: _govIdBack != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_govIdBack!, fit: BoxFit.cover),
                  )
                      : const Center(child: Text("Upload Back Side")),
                ),
              ),
            ),
          ],
        ),
      ],
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
          labelText: "Gender",
          labelStyle: GoogleFonts.inter(
            color: const Color(0xFF666666),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
        ),
        items: const [
          DropdownMenuItem(value: "Male", child: Text("Male")),
          DropdownMenuItem(value: "Female", child: Text("Female")),
          DropdownMenuItem(value: "Other", child: Text("Other")),
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
                'Your Stats',
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
              Expanded(child: _buildStatItem("Tips", "0", Icons.stars)),
              Expanded(child: _buildStatItem("Rides", "0", Icons.directions_car)),
              Expanded(child: _buildStatItem("Points", "0", Icons.loyalty)),
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
                'Quick Actions',
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
            title: "Add Vehicle",
            subtitle: "Register your vehicle for rides",
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => VehicleScreen()));
            },
          ),
          const SizedBox(height: 12),
          _buildActionTile(
            icon: Icons.payment,
            title: "Payment Methods",
            subtitle: "Manage your payment options",
            onTap: () {
              // Navigate to payment screen
            },
          ),
          const SizedBox(height: 12),
          _buildActionTile(
            icon: Icons.settings,
            title: "Settings",
            subtitle: "App preferences and privacy",
            onTap: () {
              // Navigate to settings screen
            },
          ),
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
                  "Save Changes",
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
                  "Logout",
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