import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../service/colors.dart';
import '../search/controller/search_provoder.dart';
import 'cantroller/passenger_request_provider.dart';

class PassengerRequestScreen extends StatefulWidget {
  const PassengerRequestScreen({super.key});

  @override
  State<PassengerRequestScreen> createState() => _PassengerRequestScreenState();
}

class _PassengerRequestScreenState extends State<PassengerRequestScreen> {
  // Ride controllers
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();

  // Parcel controllers
  final TextEditingController pickupCityController = TextEditingController();
  final TextEditingController pickupNameController = TextEditingController();
  final TextEditingController pickupamountController = TextEditingController();
  final TextEditingController pickupPhoneController = TextEditingController();
  final TextEditingController dropCityController = TextEditingController();
  final TextEditingController dropNameController = TextEditingController();
  final TextEditingController dropPhoneController = TextEditingController();
  final TextEditingController dimensionController = TextEditingController();

  // State
  bool isParcel = false;
  DateTime selectedDate = DateTime.now();
  TimeOfDay? selectedTime;
  int passengerCount = 1;
  double parcelWeight = 0;
  String weightUnit = "gm";
  File? _parcelImage;
  List<String> _cities = [];
  bool _isLoadingCities = true;
  final Map<String, bool> _extras = {
    'womenOnly': false,
    'doorToDoor': false,
    'ac': false,
    'charger': false,
    'wifi': false,
    'music': false,
  };
  final List<String> parcelTypes = [
    'Document',
    'Small Parcel',
    'Medium Parcel',
    'Large Parcel',
    'Fragile',
    'Freight'
  ];
  int selectedParcelTypeIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadCities();
    Future.microtask(() {
      Provider.of<SearchProvider>(context, listen: false).fetchServices();
    });
  }

  Future<void> _loadCities() async {
    try {
      final provider = SearchProvider();
      await provider.fetchCities();
      setState(() {
        _cities = provider.cities.map((e) => e.cityName).toList();
        _isLoadingCities = false;
      });
    } catch (_) {
      setState(() => _isLoadingCities = false);
      _showMsg("Failed to load cities");
    }
  }

  @override
  void dispose() {
    fromController.dispose();
    toController.dispose();
    pickupCityController.dispose();
    pickupNameController.dispose();
    pickupPhoneController.dispose();
    dropCityController.dispose();
    dropNameController.dispose();
    dropPhoneController.dispose();
    dimensionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Request',
          style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface),
        ),
        centerTitle: true,
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: cs.onSurface, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildTabSwitcher(cs),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: isParcel
                      ? _buildParcelForm(cs)
                      : _buildRideForm(cs),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSwitcher(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          _tabButton("Ride", false, cs),
          _tabButton("Parcel", true, cs),
        ],
      ),
    );
  }

  Widget _extrasCard(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(12),
      child: _extrasGrid(cs),
    );
  }


  Widget _extrasGrid(ColorScheme cs) {
    return Consumer<SearchProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final services = provider.services;
        if (services.isEmpty) {
          return const Text("No services available");
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3.0,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            final selected = service.isSelected;

            return GestureDetector(
              onTap: () {
                setState(() {
                  service.isSelected = !service.isSelected;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? cs.primaryContainer.withOpacity(0.4)
                      : cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? cs.primary : cs.outline.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Row(children: [
                  service.serviceImage != null
                      ? SvgPicture.network(
                    "https://qadampayk.com/assets/services_images/${service.serviceImage}",
                    width: 30,
                    height: 30,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.miscellaneous_services, size: 16),
                  )
                      : const Icon(Icons.miscellaneous_services, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(service.serviceName ?? "Unknown",
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (selected)
                    Icon(Icons.check_circle, color: cs.primary, size: 14),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _tabButton(String label, bool value, ColorScheme cs) {
    final bool selected = isParcel == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isParcel = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
                color: selected ? cs.onPrimary : cs.primary,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // ---------------- RIDE FORM ----------------
  Widget _buildRideForm(ColorScheme cs) {
    return Column(
      key: const ValueKey("ride"),
      children: [
        _LocationField(
            controller: fromController,
            label: "Leaving from",
            icon: "assets/images/red_icon.png",
            options: _cities,
            cs: cs),
        const SizedBox(height: 16),
        _LocationField(
            controller: toController,
            label: "Going to",
            icon: "assets/images/blue_icon.png",
            options: _cities,
            cs: cs),
        const SizedBox(height: 16),
        _datePicker(cs),
        const SizedBox(height: 16),
        _textField(
          "Your Budget",
          pickupamountController,
          Icons.price_change_rounded,
          cs,
          keyboardType: TextInputType.number, // ✅ numeric keyboard
        ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Passengers", style: TextStyle(fontWeight: FontWeight.w500)),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.remove_circle_outline, color: cs.primary),
                  onPressed:
                  passengerCount > 1 ? () => setState(() => passengerCount--) : null,
                ),
                Text('$passengerCount',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: cs.primary),
                  onPressed: () => setState(() => passengerCount++),
                ),
              ],
            ),
          ],
        ),

        _extrasCard(cs),

        const SizedBox(height: 20),
        Consumer<PassengerRequestProvider>(
          builder: (context, provider, _) {
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: provider.isLoading ? null : _submitRideRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: provider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Request Ride"),
              ),
            );
          },
        ),

      ],
    );
  }

  // ---------------- PARCEL FORM ----------------
  Widget _buildParcelForm(ColorScheme cs) {
    return Column(
      key: const ValueKey("parcel"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Pickup Information",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: cs.primary)),
                const SizedBox(height: 8),
                _LocationField(
                    controller: pickupCityController,
                    label: "Pickup City",
                    icon: "assets/images/red_icon.png",
                    options: _cities,
                    cs: cs),
                const SizedBox(height: 8),
                _textField("Pickup Contact Name", pickupNameController, Icons.person, cs),
                const SizedBox(height: 8),
                _textField("Pickup Phone", pickupPhoneController, Icons.phone, cs),
              ],
            ),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Drop Information",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: cs.primary)),
                const SizedBox(height: 8),
                _LocationField(
                    controller: dropCityController,
                    label: "Drop City",
                    icon: "assets/images/blue_icon.png",
                    options: _cities,
                    cs: cs),
                const SizedBox(height: 8),
                _textField("Drop Contact Name", dropNameController, Icons.person_outline, cs),
                const SizedBox(height: 8),
                _textField("Drop Phone", dropPhoneController, Icons.phone_outlined, cs),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4.0, bottom: 6.0),
          child: Text("Parcel Details",
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        _textField(
          "Your Budget",
          pickupamountController,
          Icons.price_change_rounded,
          cs,
          keyboardType: TextInputType.number, // ✅ numeric keyboard
        ),
        const SizedBox(height: 8),

        _textField("Parcel Description", dimensionController, Icons.description, cs),
        const SizedBox(height: 12),
        _parcelImagePicker(cs),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _datePicker(cs)),
            const SizedBox(width: 12),
            Expanded(child: _timePicker(cs)),
          ],
        ),
        const SizedBox(height: 16),
        _primaryButton("Request Parcel", cs, _submitParcelRequest),
      ],
    );
  }

  // ---------------- IMAGE PICKER ----------------
  Widget _parcelImagePicker(ColorScheme cs) {
    return InkWell(
      onTap: () async {
        showModalBottomSheet(
          context: context,
          builder: (_) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () async {
                    final pickedFile =
                    await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (pickedFile != null)
                      setState(() => _parcelImage = File(pickedFile.path));
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () async {
                    final pickedFile =
                    await ImagePicker().pickImage(source: ImageSource.camera);
                    if (pickedFile != null)
                      setState(() => _parcelImage = File(pickedFile.path));
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.primary),
        ),
        alignment: Alignment.center,
        child: _parcelImage != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            _parcelImage!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined,
                size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text("Upload Parcel Image",
                style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  // ---------------- TEXT FIELD ----------------
  // Widget _textField(
  //     String label, TextEditingController controller, IconData icon, ColorScheme cs) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 6),
  //     child: TextField(
  //       controller: controller,
  //       keyboardType:
  //       icon == Icons.phone || icon == Icons.phone_outlined
  //           ? TextInputType.phone
  //           : TextInputType.text,
  //       decoration: InputDecoration(
  //         labelText: label,
  //         prefixIcon: Icon(icon, color: cs.primary),
  //         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  //         filled: true,
  //         fillColor: Colors.white,
  //       ),
  //     ),
  //   );
  // }

  Widget _textField(
      String label,
      TextEditingController controller,
      IconData icon,
      ColorScheme cs, {
        TextInputType? keyboardType, // optional override
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType ??
            (icon == Icons.phone || icon == Icons.phone_outlined
                ? TextInputType.phone
                : TextInputType.text),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: cs.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }


  // ---------------- DATE & TIME PICKER ----------------
  Widget _datePicker(ColorScheme cs) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
            context: context,
            initialDate: selectedDate,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)));
        if (picked != null) setState(() => selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
            border: Border.all(color: cs.primary),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.calendar_today),
            Text(DateFormat('EEE, MMM d').format(selectedDate)),
          ],
        ),
      ),
    );
  }

  Widget _timePicker(ColorScheme cs) {
    return InkWell(
      onTap: () async {
        final picked =
        await showTimePicker(context: context, initialTime: selectedTime ?? TimeOfDay.now());
        if (picked != null) setState(() => selectedTime = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
            border: Border.all(color: cs.primary),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.access_time),
            Text(selectedTime != null
                ? selectedTime!.format(context)
                : 'Select Time'),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton(String label, ColorScheme cs, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 14)),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ---------------- SUBMIT FUNCTIONS ----------------
  void _submitParcelRequest() async {
    if (pickupCityController.text.trim().isEmpty || dropCityController.text.trim().isEmpty) {
      _showMsg("Please select pickup and drop cities");
      return;
    }

    final provider = Provider.of<PassengerRequestProvider>(context, listen: false);

    await provider.createParcelRequest(
      rideDate: DateFormat('dd-MM-yyyy').format(selectedDate),
      rideTime: '${selectedTime!.hour.toString().padLeft(2,'0')}:${selectedTime!.minute.toString().padLeft(2,'0')}' ?? "",
      pickupLocation: pickupCityController.text.trim(),
      destination: dropCityController.text.trim(),
      pickupContactName: pickupNameController.text.trim(),
      pickupContactNo: pickupPhoneController.text.trim(),
      dropContactName: dropNameController.text.trim(),
      dropContactNo: dropPhoneController.text.trim(),
      parcelDetails: dimensionController.text.trim(),
      parcelprice: pickupamountController.text.trim(),
      parcelImage: _parcelImage,
    );

    if (provider.errorMessage != null) {
      _showMsg("❌ ${provider.errorMessage}");
    } else {
      _showMsg("✅ Parcel request submitted successfully!");
      print("Response: ${provider.responseData}");
      Navigator.pop(context);
    }
  }


  void _submitRideRequest() async {
    if (fromController.text.trim().isEmpty || toController.text.trim().isEmpty) {
      _showMsg("Please select both locations");
      return;
    }

    final provider = Provider.of<PassengerRequestProvider>(context, listen: false);
    final providersearch = Provider.of<SearchProvider>(context, listen: false);

    final selectedServices = providersearch.services
        .where((s) => s.isSelected)
        .map((s) => s.serviceName ?? "")
        .toList();

    if (selectedServices.isEmpty) {
      _showMsg("Please select at least one extra service");
      return;
    }

    await provider.createPassengerRequest(
      fromCity: fromController.text.trim(),
      toCity: toController.text.trim(),
      seats: passengerCount,
      price: pickupamountController.text.trim(),
      rideDate: DateFormat('dd-MM-yyyy').format(selectedDate),
      services: selectedServices, // ✅ send List<String> directly
    );


    if (provider.errorMessage != null) {
      _showMsg("❌ ${provider.errorMessage}");
    } else {
      _showMsg("✅ Ride request submitted successfully!");
      print("Response: ${provider.responseData}");
      Navigator.pop(context);
    }
  }

  void _showMsg(String msg, {bool long = false}) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), duration: Duration(seconds: long ? 4 : 2)));
  }
}

/// ---------------- CUSTOM LOCATION FIELD ----------------
class _LocationField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String icon;
  final List<String> options;
  final ColorScheme cs;

  const _LocationField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.options,
    required this.cs,
  });

  @override
  State<_LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<_LocationField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _filteredOptions = [];

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = widget.controller.text.toLowerCase();
    setState(() {
      _filteredOptions = text.isEmpty
          ? widget.options
          : widget.options.where((city) => city.toLowerCase().contains(text)).toList();
    });

    if (_overlayEntry == null && _filteredOptions.isNotEmpty) {
      _showOverlay();
    } else if (_overlayEntry != null && _filteredOptions.isEmpty) {
      _removeOverlay();
    }
    _overlayEntry?.markNeedsBuild();
  }

  void _showOverlay() {
    _overlayEntry = _createOverlay();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // 🔹 Transparent layer that catches taps outside
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _removeOverlay(); // remove when tapped outside
                },
                child: Container(color: Colors.transparent),
              ),
            ),

            // 🔹 Your dropdown positioned below TextField
            Positioned(
              left: offset.dx,
              top: offset.dy + size.height + 5,
              width: size.width,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _filteredOptions.length,
                    itemBuilder: (context, index) {
                      final city = _filteredOptions[index];
                      return ListTile(
                        leading: const Icon(Icons.location_city, color: AppTheme.seedPrimary),
                        title: Text(city),
                        onTap: () {
                          widget.controller.text = city;
                          _removeOverlay();
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(6),
            child: Image.asset(widget.icon, height: 20),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: widget.cs.surface,
        ),
        onTap: () {
          if (_overlayEntry == null && _filteredOptions.isNotEmpty) _showOverlay();
        },
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }
}
