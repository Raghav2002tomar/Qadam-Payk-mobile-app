import 'dart:convert';
import 'dart:io';
import 'package:bla_bla_car/providers/translate_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../service/colors.dart';
import '../ProfileScreen/ViewResponceScreen.dart';
import '../search/controller/search_provoder.dart';
import 'cantroller/passenger_request_provider.dart';

class PassengerRequestScreen extends StatefulWidget {
  final Map<String, dynamic>? ride; // 👈 optional

  const PassengerRequestScreen({super.key, this.ride});

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
  // File? _parcelImage;
  File? _newParcelImage; // ONLY when user picks image
  String? _existingParcelImage; // URL from API (edit mode)
  bool _hasBookings = false;
  bool get _isEditMode => widget.ride != null;

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
    'Freight',
  ];
  int selectedParcelTypeIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadCities();
    Future.microtask(() {
      Provider.of<SearchProvider>(context, listen: false).fetchServices();
    });

    if (widget.ride != null) {
      _prefillForEdit(widget.ride!);
    }
  }

  void _prefillForEdit(Map<String, dynamic> data) {

    _hasBookings = (data['bookings'] != null &&
        data['bookings'] is List &&
        data['bookings'].length != 0);

    print("HAS BOOKINGS: $_hasBookings");    // 🔹 Detect request type
    final bool isParcelRequest = data['parcel_details'] != null;

    setState(() {
      isParcel = isParcelRequest;

      // 🔸 COMMON FIELDS
      pickupamountController.text = data['budget']?.toString() ?? '';

      if (data['ride_date'] != null) {
        selectedDate = DateFormat('dd-MM-yyyy').parse(data['ride_date']);
      }

      if (data['ride_time'] != null) {
        final parts = data['ride_time'].split(':');
        selectedTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }

      // ============================
      // 🚗 RIDE REQUEST
      // ============================
      if (!isParcelRequest) {
        fromController.text = data['pickup_location'] ?? '';
        toController.text = data['destination'] ?? '';
        passengerCount = data['number_of_seats'] ?? 1;
      }
      // ============================
      // 📦 PARCEL REQUEST
      // ============================
      else {
        pickupCityController.text = data['pickup_location'] ?? '';
        dropCityController.text = data['destination'] ?? '';

        pickupNameController.text = data['pickup_contact_name'] ?? '';
        pickupPhoneController.text = data['pickup_contact_no'] ?? '';
        dropNameController.text = data['drop_contact_name'] ?? '';
        dropPhoneController.text = data['drop_contact_no'] ?? '';

        dimensionController.text = data['parcel_details'] ?? '';

        // 🖼 Parcel Image
        if (data['parcel_images'] != null) {
          final images = List<String>.from(jsonDecode(data['parcel_images']));

          if (images.isNotEmpty) {
            _existingParcelImage =
                "https://qadampayk.com/assets/parcel_image/${images.first}";
          }
        }
      }
    });

    // 🔹 Auto-select services (Ride)
    if (data['services'] != null && data['services'].isNotEmpty) {
      final searchProvider = Provider.of<SearchProvider>(
        context,
        listen: false,
      );

      for (final s in searchProvider.services) {
        s.isSelected = data['services'].contains(s.id.toString());
      }
    }
  }

  Future<void> _loadCities() async {
    try {
      final provider = SearchProvider();
      await provider.fetchCities(context);
      setState(() {
        _cities = provider.cities.map((e) => e.cityName).toList();
        _isLoadingCities = false;
      });
    } catch (_) {
      setState(() => _isLoadingCities = false);
      _showMsg(
        context.watch<TranslateProvider>().t('txt_failed_to_load_cities'),
      );
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
          widget.ride != null
              ? context.watch<TranslateProvider>().t('txt_edit_request')
              : context.watch<TranslateProvider>().t('txt_create_request'),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: isParcel ? _buildParcelForm(cs) : _buildRideForm(cs),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _tabButton(
            context.watch<TranslateProvider>().t('txt_ride'),
            false,
            cs,
          ),
          _tabButton(
            context.watch<TranslateProvider>().t('txt_parcel'),
            true,
            cs,
          ),
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
          return Text(
            context.watch<TranslateProvider>().t('txt_no_service_available'),
          );
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
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
                child: Row(
                  children: [
                    service.serviceImage != null
                        ? SvgPicture.network(
                            "https://qadampayk.com/assets/services_images/${service.serviceImage}",
                            width: 30,
                            height: 30,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.miscellaneous_services,
                              size: 16,
                            ),
                          )
                        : const Icon(Icons.miscellaneous_services, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        service.serviceName ?? "Unknown",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle, color: cs.primary, size: 14),
                  ],
                ),
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
        onTap: () {
          // 🚫 Prevent switching in edit mode
          if (_isEditMode) {
            _showMsg(context.read<TranslateProvider>()
                .t('txt_cant_change_request_type'));
            return;
          }

          setState(() => isParcel = value);
        },
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
              fontWeight: FontWeight.bold,
            ),
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
        InkWell(
          onTap: () {
            if (_hasBookings) {
              _showMsg(context.read<TranslateProvider>().t('txt_cant_edit_after_booking'));
            }
          },
          child: AbsorbPointer(
            absorbing: _hasBookings,
            child: _LocationField(
              controller: fromController,
              label: context.watch<TranslateProvider>().t('txt_leaving_from'),
              icon: "assets/images/red_icon.svg",
              options: _cities,
              cs: cs,
              enabled: !_hasBookings,
            ),
          ),
        ),

        const SizedBox(height: 16),
        InkWell(
          onTap: () {
            if (_hasBookings) {
              _showMsg("You can't edit after accept booking");
            }
          },
          child: AbsorbPointer(
            absorbing: _hasBookings,
            child: _LocationField(
              controller: toController,
              label: context.watch<TranslateProvider>().t('txt_going_to'),
              icon: "assets/images/blue_icon.svg",
              options: _cities,
              cs: cs,
              enabled: !_hasBookings,
            ),
          ),
        ),

        const SizedBox(height: 16),
        _datePicker(cs),
        const SizedBox(height: 16),
        _textField(
          context.watch<TranslateProvider>().t('txt_budget'),
          pickupamountController,
          Icons.price_change_rounded,
          cs,
          keyboardType: TextInputType.number, // ✅ numeric keyboard
        ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.watch<TranslateProvider>().t('txt_passengers'),
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.remove_circle_outline, color: cs.primary),
                  onPressed: passengerCount > 1
                      ? () => setState(() => passengerCount--)
                      : null,
                ),
                Text(
                  '$passengerCount',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
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
                    : Text(
                        widget.ride != null
                            ? context.watch<TranslateProvider>().t(
                                'txt_update_request',
                              )
                            : context.watch<TranslateProvider>().t(
                                'txt_request_ride',
                              ),
                      ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.watch<TranslateProvider>().t('txt_pickup_info'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    if (_hasBookings) {
                      _showMsg("You can't edit pickup after accept booking");
                    }
                  },
                  child: AbsorbPointer(
                    absorbing: _hasBookings,
                    child: _LocationField(
                      controller: pickupCityController,
                      label: context.watch<TranslateProvider>().t('txt_pickup_city'),
                      icon: "assets/images/red_icon.svg",
                      options: _cities,
                      cs: cs,
                      enabled: !_hasBookings,
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                _textField(
                  context.watch<TranslateProvider>().t(
                    'txt_pickup_contact_name',
                  ),
                  pickupNameController,
                  Icons.person,
                  cs,
                ),
                const SizedBox(height: 8),
                _textField(
                  context.watch<TranslateProvider>().t('txt_pickup_phone'),
                  pickupPhoneController,
                  Icons.phone,
                  cs,
                ),
              ],
            ),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.watch<TranslateProvider>().t('txt_drop_info'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    if (_hasBookings) {
                      _showMsg("You can't edit drop after accept booking");
                    }
                  },
                  child: AbsorbPointer(
                    absorbing: _hasBookings,
                    child: _LocationField(
                      controller: dropCityController,
                      label: context.watch<TranslateProvider>().t('txt_drop_city'),
                      icon: "assets/images/blue_icon.svg",
                      options: _cities,
                      cs: cs,
                      enabled: !_hasBookings,
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                _textField(
                  context.watch<TranslateProvider>().t('txt_drop_contact_name'),
                  dropNameController,
                  Icons.person_outline,
                  cs,
                ),
                const SizedBox(height: 8),
                _textField(
                  context.watch<TranslateProvider>().t('txt_drop_phone'),
                  dropPhoneController,
                  Icons.phone_outlined,
                  cs,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 4.0, bottom: 6.0),
          child: Text(
            context.watch<TranslateProvider>().t('txt_parcel_details'),
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        _textField(
          context.watch<TranslateProvider>().t('txt_your_budget'),
          pickupamountController,
          Icons.price_change_rounded,
          cs,
          keyboardType: TextInputType.number, // ✅ numeric keyboard
        ),
        const SizedBox(height: 8),

        _textField(
          context.watch<TranslateProvider>().t('txt_parcel_desc'),
          dimensionController,
          Icons.description,
          cs,
        ),
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

        // widget.ride != null
        //     ? context.watch<TranslateProvider>().t('txt_update_request')
        //     : context.watch<TranslateProvider>().t('txt_request_ride'),
        const SizedBox(height: 16),
        _primaryButton(
          widget.ride != null
              ? context.watch<TranslateProvider>().t('txt_update_request')
              : context.watch<TranslateProvider>().t('txt_request_ride'),
          cs,
          _submitParcelRequest,
        ),
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
                  title: Text(
                    context.watch<TranslateProvider>().t('txt_gallery'),
                  ),
                  onTap: () async {
                    final pickedFile = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                    );

                    if (pickedFile != null) {
                      File original = File(pickedFile.path);

                      final compressed =
                          await FlutterImageCompress.compressAndGetFile(
                            original.path,
                            "${original.parent.path}/parcel_${DateTime.now().millisecondsSinceEpoch}.jpg",
                            quality: 60,
                            minWidth: 1000,
                            minHeight: 1000,
                          );

                      setState(() {
                        _newParcelImage = File(
                          compressed?.path ?? original.path,
                        );
                      });
                    }

                    Navigator.pop(context);
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: Text(
                    context.watch<TranslateProvider>().t('txt_camera'),
                  ),
                  onTap: () async {
                    final pickedFile = await ImagePicker().pickImage(
                      source: ImageSource.camera,
                    );

                    if (pickedFile != null) {
                      File original = File(pickedFile.path);

                      final compressed =
                          await FlutterImageCompress.compressAndGetFile(
                            original.path,
                            "${original.parent.path}/parcel_${DateTime.now().millisecondsSinceEpoch}.jpg",
                            quality: 60,
                            minWidth: 1000,
                            minHeight: 1000,
                          );

                      setState(() {
                        _newParcelImage = File(
                          compressed?.path ?? original.path,
                        );
                      });
                    }

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
        child: _newParcelImage != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            _newParcelImage!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover, // 🔥 fills full widget
          ),
        )
            : _existingParcelImage != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            _existingParcelImage!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover, // 🔥 fills full widget
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 40,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              context
                  .watch<TranslateProvider>()
                  .t('txt_upload_parcel_image'),
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),

      ),
    );
  }

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
        keyboardType:
            keyboardType ??
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
        if (_hasBookings) {
          _showMsg(
            "You can't edit after accept booking",
          );
          return;
        }

        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );

        if (picked != null) {
          setState(() => selectedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: _hasBookings ? Colors.grey : cs.primary,
          ),
          borderRadius: BorderRadius.circular(10),
          color: _hasBookings
              ? Colors.grey.shade200
              : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              Icons.calendar_today,
              color: _hasBookings ? Colors.grey : cs.primary,
            ),
            Text(
              DateFormat('EEE, MMM d').format(selectedDate),
              style: TextStyle(
                color: _hasBookings ? Colors.grey : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timePicker(ColorScheme cs) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: selectedTime ?? TimeOfDay.now(),
        );
        if (picked != null) setState(() => selectedTime = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: cs.primary),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.access_time),
            Text(
              selectedTime != null
                  ? selectedTime!.format(context)
                  : context.watch<TranslateProvider>().t('txt_select_time'),
            ),
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
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ---------------- SUBMIT FUNCTIONS ----------------
  void _submitParcelRequest() async {
    final provider = context.read<PassengerRequestProvider>();
    final isEdit = widget.ride != null;

    try {
      if (isEdit) {
        // 🔁 EDIT PARCEL REQUEST
        await provider.updatePassengerRequest(
          requestId: widget.ride!['request_id'].toString(),
          fromCity: pickupCityController.text.trim(),
          toCity: dropCityController.text.trim(),
          seats: passengerCount,
          price: pickupamountController.text.trim(),
          rideDate: DateFormat('dd-MM-yyyy').format(selectedDate),
          rideTime: selectedTime != null
              ? "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}"
              : null,
          pickupContactName: pickupNameController.text.trim(),
          pickupContactNo: pickupPhoneController.text.trim(),
          dropContactName: dropNameController.text.trim(),
          dropContactNo: dropPhoneController.text.trim(),
          parcelDetails: dimensionController.text.trim(),
          parcelImages: _newParcelImage != null ? [_newParcelImage!] : null,
        );
      } else {
        // 🆕 CREATE PARCEL REQUEST
        await provider.createParcelRequest(
          rideDate: DateFormat('dd-MM-yyyy').format(selectedDate),
          rideTime:
          "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}",
          pickupLocation: pickupCityController.text.trim(),
          destination: dropCityController.text.trim(),
          pickupContactName: pickupNameController.text.trim(),
          pickupContactNo: pickupPhoneController.text.trim(),
          dropContactName: dropNameController.text.trim(),
          dropContactNo: dropPhoneController.text.trim(),
          parcelDetails: dimensionController.text.trim(),
          parcelprice: pickupamountController.text.trim(),
          parcelImage: _newParcelImage,
        );
      }

      // ❌ Error handling
      if (provider.errorMessage != null) {
        _showMsg(provider.errorMessage!);
        return;
      }

      // ✅ Success message
      _showMsg(
        isEdit
            ? context.read<TranslateProvider>().t('txt_parcel_updated_success')
            : context.read<TranslateProvider>().t('txt_parcel_created_success'),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Viewresponcescreen()),
      );
    } catch (e) {
      _showMsg(e.toString());
    }
  }

  void _submitRideRequest() async {
    final provider = context.read<PassengerRequestProvider>();

    final isEdit = widget.ride != null;
    final requestId = widget.ride?['request_id']?.toString();

    if (fromController.text.isEmpty || toController.text.isEmpty) {
      _showMsg(
        context.read<TranslateProvider>().t('txt_please_select_both_loc'),
      );
      return;
    }

    if (isEdit) {
      await provider.updatePassengerRequest(
        requestId: requestId!,
        fromCity: fromController.text.trim(),
        toCity: toController.text.trim(),
        seats: passengerCount,
        price: pickupamountController.text.trim(),
        rideDate: DateFormat('dd-MM-yyyy').format(selectedDate),
        rideTime: selectedTime != null
            ? "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}"
            : null,
      );
    } else {
      await provider.createPassengerRequest(
        fromCity: fromController.text.trim(),
        toCity: toController.text.trim(),
        seats: passengerCount,
        price: pickupamountController.text.trim(),
        rideDate: DateFormat('dd-MM-yyyy').format(selectedDate),
      );
    }

    if (provider.errorMessage != null) {
      _showMsg("❌ ${provider.errorMessage}");
    } else {
      _showMsg(
        isEdit
            ? context.read<TranslateProvider>().t('txt_request_updated_success')
            : context.read<TranslateProvider>().t(
                'txt_ride_requested_submit_success',
              ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Viewresponcescreen()),
      );
    }
  }

  void _showMsg(String msg, {bool long = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: Duration(seconds: long ? 4 : 2),
      ),
    );
  }
}

/// ---------------- CUSTOM LOCATION FIELD ----------------
class _LocationField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String icon;
  final List<String> options;
  final ColorScheme cs;
  final bool enabled;



  const _LocationField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.options,
    required this.cs,
    this.enabled = true,

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
          : widget.options
                .where((city) => city.toLowerCase().contains(text))
                .toList();
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
                        leading: const Icon(
                          Icons.location_city,
                          color: AppTheme.seedPrimary,
                        ),
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
        enabled: widget.enabled, // 🔥 important
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(6),
            child: SvgPicture.asset(widget.icon, height: 20),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: widget.cs.surface,
        ),
        onTap: () {
          if (_overlayEntry == null && _filteredOptions.isNotEmpty)
            _showOverlay();
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
