import 'dart:convert';
import 'dart:io';
import 'package:bla_bla_car/api_service/app_constocter.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../service/local_cache.dart';
import '../mainView/create/Add_vehical.dart';
import '../mainView/create/VehicleListScreen.dart';
import '../mainView/search/controller/search_provoder.dart';

// ─── Tokens ───────────────────────────────────────────────────────────────────
const _green = Color(0xFF008955);
const _greenLight = Color(0xFFEAF5EF);
const _bg = Color(0xFFF5F8F6);
const _surface = Colors.white;
const _textPrimary = Color(0xFF141F1A);
const _textMuted = Color(0xFF8A9E95);
const _border = Color(0xFFDEEAE4);

TextStyle _font({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = _textPrimary,
  double height = 1.4,
}) =>
    GoogleFonts.dmSans(fontSize: size, fontWeight: weight, color: color, height: height);

// ─── Screen ───────────────────────────────────────────────────────────────────


// SAME IMPORTS (UNCHANGED)

class CourierVerificationDocScreen extends StatefulWidget {
  const CourierVerificationDocScreen({super.key});

  @override
  State<CourierVerificationDocScreen> createState() => _State();
}

class _State extends State<CourierVerificationDocScreen>
    with SingleTickerProviderStateMixin {

  final _picker = ImagePicker();

  int _step = 0;

  String? _deliveryType; // "walk" or "vehicle"
  dynamic _selectedVehicle; // store selected vehicle object

  File? _front, _back, _selfie;
  bool _submitting = false;

  CameraController? _cam;
  bool _camReady = false;
  bool _capturing = false;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat(reverse: true);

  late final Animation<double> _pulseAnim = Tween(begin: 1.0, end: 1.1)
      .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

  @override
  void dispose() {
    _cam?.dispose();
    _pulse.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_step) {
      case 0:
        return _deliveryType != null;
      case 1:
        return _front != null && _back != null;
      case 2:
        return _selfie != null;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [

        _Header(step: _step,onBack:()=>Navigator.pop(context)),

        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: KeyedSubtree(
              key: ValueKey(_step),
              child: _body(),
            ),
          ),
        ),

        _BottomBar(
          step: _step,
          canProceed: _canProceed,
          submitting: _submitting,
          onTap: _next,
        ),

      ]),
    );
  }

  Widget _body() {
    switch (_step) {
      case 0:
        return _DeliveryTypeStep(
          selected: _deliveryType,
          selectedVehicle: _selectedVehicle,
          onSelect: _handleDeliveryType,
        );

      case 1:
        return _UploadStep(
          front: _front,
          back: _back,
          onPick: _pick,
        );

      case 2:
        return _SelfieStep(
          selfie: _selfie,
          cam: _cam,
          camReady: _camReady,
          pulseAnim: _pulseAnim,
          onCapture: _capture,
          onRetake: () {
            setState(() => _selfie = null);
            _initCam();
          },
        );

      default:
        return const SizedBox();
    }
  }
  Future<void> _next() async {
    if (_step == 0) {
      setState(() => _step = 1);
    }
    else if (_step == 1) {
      setState(() => _step = 2);
      await _initCam();
    }
    else {
      await _submit();
    }
  }


  Future<void> _handleDeliveryType(String value) async {
    if (value == "walk") {
      setState(() {
        _deliveryType = "walk";
        _selectedVehicle = null;
      });
    }

    if (value == "vehicle") {
      final provider = SearchProvider();
      await provider.fetchVehicles();

      if (provider.vehicles.isEmpty) {
        _showActionDialog(
          message: "You don't have any vehicle. Please add a vehicle first.",
          buttonText: "Add Vehicle",
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VehicleScreen()),
            );
          },
        );
        return;
      }

      // Auto select if only 1
      if (provider.vehicles.length == 1) {
        final vehicle = provider.vehicles.first;

        final success = await _selectVehicle(int.parse(vehicle.id.toString()));
        if (!success) return;

        setState(() {
          _deliveryType = "vehicle";
          _selectedVehicle = vehicle;
        });
      } else {
        final selectedVehicle = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VehicleListScreen()),
        );

        if (selectedVehicle == null) return;

        final success = await _selectVehicle(
          int.parse(selectedVehicle.id.toString()),
        );

        if (!success) return;

        setState(() {
          _deliveryType = "vehicle";
          _selectedVehicle = selectedVehicle;
        });
      }
    }
  }

  Future<bool> _selectVehicle(int vehicleId) async {
    try {
      final token = await LocalCache.getToken();

      final response = await http.post(
        Uri.parse("https://qadampayk.com/api/select-vehicle"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"vehicle_id": vehicleId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["status"] == true) {
        return true;
      } else {
        _showErrorDialog(data["message"] ?? "Failed to select vehicle");
        return false;
      }
    } catch (e) {
      _showErrorDialog("Network error while selecting vehicle");
      return false;
    }
  }


  void _showActionDialog({
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Action Required"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(onPressed: onPressed, child: Text(buttonText)),
        ],
      ),
    );
  }


  Future<void> _pick(bool isFront) async {

    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SourceSheet(),
    );

    if(src==null)return;

    final f=await _picker.pickImage(source:src,imageQuality:88);

    if(f==null)return;

    setState(()=>isFront?_front=File(f.path):_back=File(f.path));

  }


  Future<void> _initCam() async {

    final cams=await availableCameras();

    final front=cams.firstWhere(
            (c)=>c.lensDirection==CameraLensDirection.front,
        orElse:()=>cams.first
    );

    _cam=CameraController(front,ResolutionPreset.high,enableAudio:false);

    await _cam!.initialize();

    if(mounted)setState(()=>_camReady=true);

  }


  Future<void> _capture() async {

    if(_capturing||!_camReady)return;

    _capturing=true;

    try{

      final f=await _cam!.takePicture();

      await _cam!.dispose();

      if(mounted){
        setState(() {
          _selfie=File(f.path);
          _camReady=false;
        });
      }

    }finally{
      _capturing=false;
    }

  }


  Future<File> _compressImage(File file) async {

    final dir=await getTemporaryDirectory();

    final targetPath=p.join(
        dir.path,
        "cmp_${DateTime.now().millisecondsSinceEpoch}.jpg"
    );

    final result=await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality:70,
        minWidth:1080,
        minHeight:1080
    );

    if(result==null)return file;

    return File(result.path);

  }



  // Future<void> _submit() async {
  //
  //   setState(()=>_submitting=true);
  //
  //   try{
  //
  //     final token=await LocalCache.getToken();
  //
  //     final compressedFront=await _compressImage(_front!);
  //     final compressedBack=await _compressImage(_back!);
  //     final compressedSelfie=await _compressImage(_selfie!);
  //
  //     final request=http.MultipartRequest(
  //         'POST',
  //         Uri.parse('${App_Constructor().BaseURL}/api/courier/documents/submit')
  //     );
  //
  //     request.headers['Authorization']='Bearer $token';
  //
  //
  //     request.files.add(
  //         await http.MultipartFile.fromPath(
  //             'license_images[]',
  //             compressedFront.path
  //         )
  //     );
  //
  //
  //     request.files.add(
  //         await http.MultipartFile.fromPath(
  //             'license_images[]',
  //             compressedBack.path
  //         )
  //     );
  //
  //
  //     request.files.add(
  //         await http.MultipartFile.fromPath(
  //             'selfie',
  //             compressedSelfie.path
  //         )
  //     );
  //
  //
  //     final streamedResponse=await request.send();
  //
  //     final response=await http.Response.fromStream(streamedResponse);
  //
  //     final data=jsonDecode(response.body);
  //
  //
  //     if(response.statusCode==200&&data['status']==true){
  //
  //       showDialog(
  //           context:context,
  //           barrierDismissible:false,
  //           builder:(_)=>_SuccessDialog(
  //             onDone:(){
  //               Navigator.pop(context);
  //               Navigator.pop(context);
  //             },
  //           )
  //       );
  //
  //     }else{
  //
  //       _showErrorDialog(data['message']??"Something went wrong");
  //
  //     }
  //
  //   }catch(e){
  //
  //     _showErrorDialog("Submission failed");
  //
  //   }finally{
  //
  //     if(mounted)setState(()=>_submitting=false);
  //
  //   }
  //
  // }
  Future<void> _submit() async {
    setState(() => _submitting = true);

    try {
      final token = await LocalCache.getToken();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${App_Constructor().BaseURL}/api/courier/documents/submit'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      /// VERY IMPORTANT
      request.fields['delivery_mode'] = _deliveryType!;

      final compressedSelfie = await _compressImage(_selfie!);

      /// SELFIE (Common for both)
      request.files.add(
        await http.MultipartFile.fromPath(
          'selfie',
          compressedSelfie.path,
        ),
      );

      // ==========================
      // 🟢 WALK MODE
      // ==========================
      if (_deliveryType == "walk") {

        final front = await _compressImage(_front!);
        final back = await _compressImage(_back!);

        request.files.add(
          await http.MultipartFile.fromPath(
            'walking_gov_id[]',
            front.path,
          ),
        );

        request.files.add(
          await http.MultipartFile.fromPath(
            'walking_gov_id[]',
            back.path,
          ),
        );
      }

      // ==========================
      // 🚗 VEHICLE MODE
      // ==========================
      if (_deliveryType == "vehicle") {

        final passportFront = await _compressImage(_front!);
        final passportBack = await _compressImage(_back!);

        /// Send passport images
        request.files.add(
          await http.MultipartFile.fromPath(
            'passport_images[]',
            passportFront.path,
          ),
        );

        request.files.add(
          await http.MultipartFile.fromPath(
            'passport_images[]',
            passportBack.path,
          ),
        );

        /// Example: You can reuse same images or use different ones
        request.files.add(
          await http.MultipartFile.fromPath(
            'license_images[]',
            passportFront.path,
          ),
        );

        request.files.add(
          await http.MultipartFile.fromPath(
            'license_images[]',
            passportBack.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _SuccessDialog(
            onDone: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        );
      } else {
        _showErrorDialog(data['message'] ?? "Something went wrong");
      }
    } catch (e) {
      _showErrorDialog("Submission failed");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showErrorDialog(String message){

    showDialog(
        context:context,
        builder:(_)=>AlertDialog(
          title:const Text("Error"),
          content:Text(message),
          actions:[
            TextButton(
                onPressed:()=>Navigator.pop(context),
                child:const Text("OK")
            )
          ],
        )
    );

  }

}

// ─── Header (UPDATED → 2 STEPS) ───────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.step, required this.onBack});

  final int step;
  final VoidCallback onBack;

  static const _icons = [
    Icons.directions_walk,
    Icons.upload_rounded,
    Icons.face_rounded
  ];

  static const _labels = [
    'Delivery',
    'Upload',
    'Selfie'
  ];

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      color: _green,
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 20),
      child: Column(
        children: [

          /// Top Row
          Row(
            children: [

              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Text(
                'Identity Verification',
                style: _font(
                  size: 15,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),

              const Spacer(),

              /// Step Counter
              Text(
                '${step + 1} / 3',
                style: _font(
                  size: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// Progress Steps
          Row(
            children: List.generate(5, (i) {

              if (i.isOdd) {
                final s = i ~/ 2;

                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: step > s
                          ? Colors.white
                          : Colors.white.withOpacity(0.22),
                    ),
                  ),
                );
              }

              final s = i ~/ 2;
              final done = step > s;
              final active = step == s;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (done || active)
                      ? Colors.white
                      : Colors.white.withOpacity(0.16),
                ),
                child: Icon(
                  done ? Icons.check_rounded : _icons[s],
                  size: 15,
                  color: (done || active)
                      ? _green
                      : Colors.white.withOpacity(0.5),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          /// Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (s) {

              final active = step >= s;

              return SizedBox(
                width: 70,
                child: Text(
                  _labels[s],
                  textAlign: s == 0
                      ? TextAlign.left
                      : TextAlign.right,
                  style: _font(
                    size: 11,
                    weight: step == s
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: active
                        ? Colors.white
                        : Colors.white.withOpacity(0.45),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }


}
class _DeliveryTypeStep extends StatelessWidget {
  const _DeliveryTypeStep({
    required this.selected,
    required this.onSelect,
    required this.selectedVehicle,
  });

  final String? selected;
  final dynamic selectedVehicle;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text('Select Delivery Type',
              style: _font(size: 17, weight: FontWeight.w700)),

          const SizedBox(height: 18),

          _typeCard(
            label: "Walk",
            icon: Icons.directions_walk,
            value: "walk",
          ),

          const SizedBox(height: 12),

          _typeCard(
            label: "Vehicle",
            icon: Icons.directions_car,
            value: "vehicle",
          ),

          if (selectedVehicle != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _greenLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: _green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Selected Vehicle: ${selectedVehicle.brand ?? ""} ${selectedVehicle.model ?? ""}",                      style: _font(weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _typeCard({
    required String label,
    required IconData icon,
    required String value,
  }) {
    final isSelected = selected == value;

    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _greenLight : _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _green : _border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? _green : _textMuted),
            const SizedBox(width: 12),
            Text(label,
                style: _font(
                    weight: FontWeight.w600)),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check, color: _green),
          ],
        ),
      ),
    );
  }
}
// ─── Step 1: Doc ──────────────────────────────────────────────────────────────

class _DocStep extends StatelessWidget {
  const _DocStep({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Select Document', style: _font(size: 17, weight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text('Choose your verification document', style: _font(size: 13, color: _textMuted)),
        const SizedBox(height: 18),
        _DocTile(value: 'passport', label: 'Passport', icon: Icons.book_outlined, selected: selected == 'passport', onTap: () => onSelect('passport')),
        const SizedBox(height: 10),
        _DocTile(value: 'license', label: 'Driving License', icon: Icons.directions_car_outlined, selected: selected == 'license', onTap: () => onSelect('license')),
      ]),
    );
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile({required this.value, required this.label, required this.icon, required this.selected, required this.onTap});
  final String value, label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: selected ? _greenLight : _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? _green : _border, width: selected ? 1.8 : 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: selected ? _green : _bg, borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, size: 18, color: selected ? Colors.white : _textMuted),
        ),
        const SizedBox(width: 13),
        Text(label, style: _font(size: 14, weight: FontWeight.w600)),
        const Spacer(),
        AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? _green : Colors.transparent,
            border: Border.all(color: selected ? _green : _border, width: 1.5),
          ),
          child: selected ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
        ),
      ]),
    ),
  );
}

// ─── Step 2: Upload ───────────────────────────────────────────────────────────

class _UploadStep extends StatelessWidget {
  const _UploadStep({required this.front, required this.back, required this.onPick});
  final File? front, back;
  final Future<void> Function(bool) onPick;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Upload Document', style: _font(size: 17, weight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text('Clear photo of both sides', style: _font(size: 13, color: _textMuted)),
      const SizedBox(height: 18),
      _UploadCard(label: 'Front Side', file: front, onTap: () => onPick(true)),
      const SizedBox(height: 10),
      _UploadCard(label: 'Back Side', file: back, onTap: () => onPick(false)),
    ]),
  );
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({required this.label, required this.file, required this.onTap});
  final String label;
  final File? file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final has = file != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 200,
        width: 350,
        decoration: BoxDecoration(
          color: has ? null : _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: has ? _green : _border, width: has ? 1.8 : 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        clipBehavior: Clip.antiAlias,
        child: has ? _filled() : _empty(),
      ),
    );
  }

  Widget _filled() => Stack(fit: StackFit.expand, children: [
    Image.file(file!, fit: BoxFit.cover),
    Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withOpacity(0.38), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ),
    Positioned(top: 10, left: 12,
      child: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 13),
        const SizedBox(width: 5),
        Text(label, style: _font(size: 12, weight: FontWeight.w600, color: Colors.white)),
      ]),
    ),
    Positioned(top: 8, right: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.42), borderRadius: BorderRadius.circular(18)),
        child: Text('Change', style: _font(size: 11, weight: FontWeight.w600, color: Colors.white)),
      ),
    ),
  ]);

  Widget _empty() => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: _greenLight, borderRadius: BorderRadius.circular(11)),
      child: const Icon(Icons.add_photo_alternate_outlined, color: _green, size: 20),
    ),
    const SizedBox(height: 9),
    Text(label, style: _font(size: 13, weight: FontWeight.w600)),
    const SizedBox(height: 2),
    Text('Tap to upload', style: _font(size: 12, color: _textMuted)),
  ]);
}

// ─── Source Sheet ─────────────────────────────────────────────────────────────

class _SourceSheet extends StatelessWidget {
  const _SourceSheet();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
    decoration: const BoxDecoration(color: _surface, borderRadius: BorderRadius.all(Radius.circular(22))),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 32, height: 3, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 16),
      Text('Add Photo', style: _font(size: 15, weight: FontWeight.w700)),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _SrcBtn(icon: Icons.camera_alt_rounded, label: 'Camera', src: ImageSource.camera)),
        const SizedBox(width: 10),
        Expanded(child: _SrcBtn(icon: Icons.photo_library_rounded, label: 'Gallery', src: ImageSource.gallery)),
      ]),
    ]),
  );
}

class _SrcBtn extends StatelessWidget {
  const _SrcBtn({required this.icon, required this.label, required this.src});
  final IconData icon;
  final String label;
  final ImageSource src;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.pop(context, src),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: _greenLight, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Icon(icon, color: _green, size: 24),
        const SizedBox(height: 7),
        Text(label, style: _font(size: 13, weight: FontWeight.w600, color: _green)),
      ]),
    ),
  );
}

// ─── Step 3: Selfie ───────────────────────────────────────────────────────────

class _SelfieStep extends StatelessWidget {
  const _SelfieStep({required this.selfie, required this.cam, required this.camReady, required this.pulseAnim, required this.onCapture, required this.onRetake});
  final File? selfie;
  final CameraController? cam;
  final bool camReady;
  final Animation<double> pulseAnim;
  final VoidCallback onCapture, onRetake;

  @override
  Widget build(BuildContext context) {
    if (selfie != null) return _preview();
    if (!camReady) return const Center(child: CircularProgressIndicator(color: _green, strokeWidth: 2));
    return _live();
  }

  Widget _live() => Stack(fit: StackFit.expand, children: [
    CameraPreview(cam!),
    CustomPaint(painter: _OvalPainter()),
    Positioned(
      top: 18, left: 44, right: 44,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.48), borderRadius: BorderRadius.circular(28)),
        child: Text('Align face within oval', textAlign: TextAlign.center, style: _font(size: 12, color: Colors.white)),
      ),
    ),
    Positioned(
      bottom: 32, left: 0, right: 0,
      child: Center(
        child: ScaleTransition(
          scale: pulseAnim,
          child: GestureDetector(
            onTap: onCapture,
            child: Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3.5)),
              child: Container(margin: const EdgeInsets.all(5), decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
            ),
          ),
        ),
      ),
    ),
  ]);

  Widget _preview() => Stack(fit: StackFit.expand, children: [
    Image.file(selfie!, fit: BoxFit.cover),
    Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.5, 1.0],
        ),
      ),
    ),
    Positioned(
      top: 20, left: 0, right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(22)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Text('Selfie Captured', style: _font(size: 12, weight: FontWeight.w600, color: Colors.white)),
          ]),
        ),
      ),
    ),
    Positioned(
      bottom: 32, left: 24, right: 24,
      child: OutlinedButton.icon(
        onPressed: onRetake,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white, width: 1.5),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
        icon: const Icon(Icons.replay_rounded, size: 15),
        label: Text('Retake', style: _font(size: 14, weight: FontWeight.w600, color: Colors.white)),
      ),
    ),
  ]);
}

// ─── Bottom Bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.step, required this.canProceed, required this.submitting, required this.onTap});
  final int step;
  final bool canProceed, submitting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 14),
      decoration: BoxDecoration(
        color: _surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, -3))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: canProceed && !submitting ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _green,
            disabledBackgroundColor: _border,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: submitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              step == 2 ? 'Submit Documents' : 'Continue',
              style: _font(size: 14, weight: FontWeight.w700, color: canProceed ? Colors.white : _textMuted),
            ),
            if (canProceed) ...[const SizedBox(width: 5), const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white)],
          ]),
        ),
      ),
    );
  }
}

// ─── Success Dialog ───────────────────────────────────────────────────────────

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: Padding(
      padding: const EdgeInsets.all(26),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 62,
          height: 62,
          decoration: const BoxDecoration(color: _greenLight, shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_rounded, color: _green, size: 38),
        ),
        const SizedBox(height: 14),
        Text('Submitted!', style: _font(size: 17, weight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          'Documents are under review.\nWe\'ll notify you once verified.',
          textAlign: TextAlign.center,
          style: _font(size: 13, color: _textMuted, height: 1.55),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              elevation: 0,
            ),
            child: Text('Done', style: _font(size: 14, weight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ]),
    ),
  );
}

// ─── Oval Painter ─────────────────────────────────────────────────────────────

class _OvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final oval = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 30),
      width: 210,
      height: 268,
    );
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.black.withOpacity(0.55));
    canvas.drawOval(oval, Paint()..blendMode = BlendMode.clear);
    canvas.restore();
    canvas.drawOval(oval.inflate(1.5), Paint()
      ..color = Colors.white.withOpacity(0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}