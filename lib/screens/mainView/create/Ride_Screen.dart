import 'dart:io';
import 'package:bla_bla_car/providers/translate_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../api_service/logger.dart';
import '../../../service/colors.dart';
import '../HomeShell.dart';
import '../ProfileScreen/ViewResponceScreen.dart';
import '../search/controller/search_provoder.dart';
import 'VehicleListScreen.dart';
import 'VehicleStorage.dart';

class RideScreen extends StatefulWidget {
  final Map<String, dynamic>? ride; // 👈 optional

  const RideScreen({super.key, this.ride});

  @override
  State<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _departureController = TextEditingController();
  final _destinationController = TextEditingController();
  bool get isEditMode => widget.ride != null;
  final _priceController = TextEditingController();
  List<String> _selectedServiceIds = [];
  bool _isPermanent = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int? _seats = 1;

  double _price = 0.0;
  Vehicle? _selectedVehicle;
  List<String> _cities = [];
  bool _isLoadingCities = true;
  bool _isLoadingVehicles = true; // Add separate loading state for vehicles
  List<Vehicle> _vehicles = []; // Store vehicles from API
  bool _hasBookings = false; // set this based on API / ride data
  bool _acceptPackages = false;


  @override
  void initState() {
    super.initState();
    _loadInitialData();
    Future.microtask(() async {
      final provider = Provider.of<SearchProvider>(context, listen: false);
      await provider.fetchServices();

      if (isEditMode) {
        _preselectServices(provider);
      }
    });
    if (isEditMode) {
      _prefillRideData(widget.ride!);
    }
  }

  void _preselectServices(SearchProvider provider) {
    for (var service in provider.services) {
      service.isSelected =
          _selectedServiceIds.contains(service.id.toString());
    }
  }

  void _prefillRideData(Map<String, dynamic> ride) {
    _hasBookings = (ride['bookings'] != null &&
        ride['bookings'] is List &&
        ride['bookings'].length != 0);

    appLog("HAS BOOKINGS: $_hasBookings");    // 🔹 Detect request type
    _departureController.text = ride['pickup_location'] ?? '';
    _destinationController.text = ride['destination'] ?? '';

    _selectedDate = _parseDate(ride['ride_date']); // ✅ FIXED
    _selectedTime = _parseTime(ride['ride_time']);
    // _isPermanent =
    //     ride['is_permanent'].toString() == "1" || ride['is_permanent'] == true;
    _isPermanent = ride['is_permanent'] == true || ride['is_permanent'].toString() == "1";
    _seats = int.tryParse(ride['number_of_seats'].toString()) ?? 1;
    _price = double.tryParse(ride['price'].toString()) ?? 0.0;
    _priceController.text = _price.toStringAsFixed(0); // ✅ FIX
    _acceptPackages = ride['accept_parcel'] == true;
    _selectedServiceIds =
        (ride['services'] as List?)?.map((e) => e.toString()).toList() ?? [];

  }

  DateTime? _parseDate(String? date) {
    if (date == null || date.isEmpty) return null;
    try {
      return DateFormat('dd-MM-yyyy').parse(date);
    } catch (_) {
      return null;
    }
  }


  TimeOfDay? _parseTime(String? time) {
    if (time == null) return null;
    final parts = time.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  // Load both cities and vehicles
  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadCities(),
      _loadVehicles(),
    ]);
  }
  Future<void> _loadVehicles() async {
    try {
      final provider = SearchProvider();
      await provider.fetchVehicles();

      setState(() {
        _vehicles = provider.vehicles;
        _isLoadingVehicles = false;

        if (_vehicles.isNotEmpty) {
          if (isEditMode && widget.ride != null) {
            // ✅ select ride's vehicle
            _selectedVehicle = _vehicles.firstWhere(
                  (v) => v.id.toString() == widget.ride!['vehicle_id'].toString(),
              orElse: () => _vehicles.first,
            );
          } else {
            // ✅ create mode → first vehicle
            _selectedVehicle = _vehicles.first;
          }
        }
      });
    } catch (e) {
      _isLoadingVehicles = false;
      _showMsg(context.watch<TranslateProvider>().t('txt_failed_to_load_vehicle'));
    }
  }

  void _showMsg(String msg, {bool long = false}) {
    if (!mounted) return; // ✅ FIX

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: Duration(seconds: long ? 4 : 2),
      ),
    );
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
      _showMsg(context.watch<TranslateProvider>().t('txt_failed_to_load_cities'));
    }
  }

  @override
  void dispose() {
    _departureController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Show loading while fetching initial data
    if (_isLoadingVehicles || _isLoadingCities) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.watch<TranslateProvider>().t('txt_create_ride'),
              style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface, fontSize: 18)),
          centerTitle: true,
          backgroundColor: cs.surface,
          elevation: 0,
          surfaceTintColor: cs.surface,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: cs.onSurface, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Determine which view to show based on vehicle availability
    final shouldShowNoVehicles = _vehicles.isEmpty;
    final shouldShowVehicleSelection = _selectedVehicle == null && _vehicles.isNotEmpty;
    final shouldShowRideForm = _selectedVehicle != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode
            ? context.watch<TranslateProvider>().t('txt_edit_ride')
            : context.watch<TranslateProvider>().t('txt_create_ride'),
            style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface, fontSize: 18)),
        centerTitle: true,
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: cs.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: cs.onSurface, size: 18),
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
          ),
        ),
        actions: [
          if (_vehicles.isNotEmpty)
            IconButton(
              onPressed: () => _openVehicleList(),
              icon: Icon(Icons.directions_car, color: cs.primary),
              tooltip: context.watch<TranslateProvider>().t('txt_select_vehicle'),
            )
        ],
      ),
      body: shouldShowNoVehicles
          ? _buildNoVehicleView(cs)
          : shouldShowVehicleSelection
          ? _buildVehicleSelectionView(cs, _vehicles)
          : _buildRideForm(cs, _selectedVehicle!),
      bottomNavigationBar: shouldShowRideForm
          ? _VehicleBottomBar(vehicle: _selectedVehicle!, compact: true)
          : null,
    );
  }
  Widget _permanentRideCard(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isPermanent
                  ? cs.primaryContainer.withOpacity(0.2)
                  : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.repeat,
              color: _isPermanent
                  ? cs.onPrimaryContainer
                  : cs.onSurfaceVariant,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Permanent Ride",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
          Switch(
            value: _isPermanent,
            onChanged: (v) => setState(() => _isPermanent = v),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeColor: cs.primary,
          ),
        ],
      ),
    );
  }
  // Vehicle selection view when no vehicle is selected
  Widget _buildVehicleSelectionView(ColorScheme cs, List<Vehicle> vehicles) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  shape: BoxShape.circle
              ),
              child: Icon(Icons.directions_car_outlined, size: 44, color: cs.primary),
            ),
            const SizedBox(height: 12),
            Text(context.watch<TranslateProvider>().t('txt_select_your_vehicle'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface)),
            const SizedBox(height: 6),
            Text(context.watch<TranslateProvider>().t('txt_choose_your_vehicle_to_select'),
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.3),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),

            // Vehicle list preview
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = vehicles[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: vehicle.imagePath != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(vehicle.imagePath!, width: 50, height: 50, fit: BoxFit.cover),
                      )
                          : Icon(Icons.directions_car, size: 50),
                      title: Text('${vehicle.brand} ${vehicle.model}'),
                      subtitle: Text('• ${vehicle.plate}'),
                      onTap: () {
                        setState(() {
                          _selectedVehicle = vehicle;
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _openVehicleList(),
              icon: const Icon(Icons.add, size: 18),
              label: Text(context.watch<TranslateProvider>().t('txt_manage_vehicle')),
              style: OutlinedButton.styleFrom(
                visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty state when no vehicles exist
  Widget _buildNoVehicleView(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cs.surfaceContainerLow, shape: BoxShape.circle),
              child: Icon(Icons.directions_car_outlined, size: 44, color: cs.primary),
            ),
            const SizedBox(height: 12),
            Text(context.watch<TranslateProvider>().t('txt_no_vehicle_found'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface)),
            const SizedBox(height: 6),
            Text(context.watch<TranslateProvider>().t('txt_add_a_vehicle'),
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.3),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _openVehicleList(),
              icon: const Icon(Icons.add, size: 18),
              label: Text(context.watch<TranslateProvider>().t('txt_add_vehicle')),
              style: FilledButton.styleFrom(
                visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Main form (your existing code)
  Widget _buildRideForm(ColorScheme cs, Vehicle vehicle) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sectionHeader(context.watch<TranslateProvider>().t('txt_route'), Icons.route, cs),
                const SizedBox(height: 8),
                _routeCard(cs),

                const SizedBox(height: 12),
                _sectionHeader(context.watch<TranslateProvider>().t('txt_schedule'), Icons.schedule, cs),
                const SizedBox(height: 8),
                _dateTimeCard(cs),

                const SizedBox(height: 12),
                _sectionHeader(context.watch<TranslateProvider>().t('txt_details'), Icons.info_outline, cs),
                const SizedBox(height: 8),
                _tripDetailsCard(cs),

                const SizedBox(height: 12),
                _sectionHeader(context.watch<TranslateProvider>().t('txt_extras'), Icons.star_outline, cs),
                const SizedBox(height: 8),
                _extrasCard(cs),

                const SizedBox(height: 12),
                _sectionHeader(context.watch<TranslateProvider>().t('txt_packages'), Icons.local_shipping_outlined, cs),
                const SizedBox(height: 8),
                _packageCard(cs),
                const SizedBox(height: 12),
                _sectionHeader("Permanent", Icons.repeat, cs),
                const SizedBox(height: 8),
                _permanentRideCard(cs),

                const SizedBox(height: 72),
              ]),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: BoxDecoration(
            color: cs.surface,
            boxShadow: [BoxShadow(color: cs.shadow.withOpacity(0.06), offset: const Offset(0, -1), blurRadius: 6)],
          ),
          child: SafeArea(
            child: FilledButton.icon(
              onPressed: _publishRide,
              icon: const Icon(Icons.rocket_launch, size: 18),
              label: Text(
                isEditMode
                    ? context.watch<TranslateProvider>().t('txt_update_ride')
                    : context.watch<TranslateProvider>().t('txt_publish_ride'),
              ),
              style: FilledButton.styleFrom(
                visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
                minimumSize: const Size.fromHeight(44),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openVehicleList() async {
    final selected = await Navigator.push<Vehicle>(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleListScreen(),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedVehicle = selected;
      });
    } else {
      // Refresh vehicles in case new one was added
      _loadVehicles();
    }
  }

  // Rest of your existing methods remain the same...
  Widget _sectionHeader(String title, IconData icon, ColorScheme cs) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration:
        BoxDecoration(color: cs.primaryContainer.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 16, color: cs.onPrimaryContainer),
      ),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
    ]);
  }

  Widget _routeCard(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(children: [
        // _LocationField(
        //     controller: _departureController,
        //     label: context.watch<TranslateProvider>().t('txt_leaving_from'),
        //     icon: "assets/images/red_icon.svg",
        //     options: _cities,
        //     cs: cs,
        //
        // ),
        InkWell(
          onTap: () {
            if (_hasBookings) {
              _showMsg("You can't edit after accept booking");
            }
          },
          child: AbsorbPointer(
            absorbing: _hasBookings,
            child: _LocationField(
              controller: _departureController,
              label: context.watch<TranslateProvider>().t('txt_leaving_from'),
              icon: "assets/images/red_icon.svg",
              options: _cities,
              cs: cs,
              enabled: !_hasBookings,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(children: [
          const SizedBox(width: 8),
          Icon(Icons.arrow_upward, color: cs.outline.withOpacity(0.9), size: 14),
          Icon(Icons.arrow_downward_sharp, color: cs.outline.withOpacity(0.9), size: 14),
        ]),
        const SizedBox(height: 6),
        // _LocationField(
        //     controller: _destinationController,
        //     label: context.watch<TranslateProvider>().t('txt_going_to'),
        //     icon: "assets/images/blue_icon.svg",
        //     options: _cities,
        //     cs: cs),
        InkWell(
          onTap: () {
            if (_hasBookings) {
              _showMsg("You can't edit drop after accept booking");
            }
          },
          child: AbsorbPointer(
            absorbing: _hasBookings,
            child: _LocationField(
              controller: _destinationController,
              label: context.watch<TranslateProvider>().t('txt_drop_city'),
              icon: "assets/images/blue_icon.svg",
              options: _cities,
              cs: cs,
              enabled: !_hasBookings,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _dateTimeCard(ColorScheme cs) {
    return InkWell(
      onTap: () async{
        if (_hasBookings) {
          _showMsg(
            "You can't edit after accept booking",
          );
          return;
        };
      },

      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(child: _datePicker(cs)),
          const SizedBox(width: 10),
          Expanded(child: _timePicker(cs)),
        ]),
      ),
    );
  }

  Widget _tripDetailsCard(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Expanded(child: _seatsDropdown(cs)),
        const SizedBox(width: 10),
        Expanded(child: _priceField(cs)),
      ]),
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

  Widget _packageCard(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _acceptPackages ? cs.primaryContainer.withOpacity(0.2) : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.local_shipping_outlined,
              color: _acceptPackages ? cs.onPrimaryContainer : cs.onSurfaceVariant, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(context.watch<TranslateProvider>().t('txt_accept_packages'),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
        ),
        Switch(
          value: _acceptPackages,
          onChanged: (v) => setState(() => _acceptPackages = v),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          activeColor: cs.primary,
        ),
      ]),
    );
  }

  Widget _datePicker(ColorScheme cs) {
    return InkWell(
      onTap: () {
        if (_hasBookings) {
          _showMsg("You can't edit after accept booking");
          return;
        }
        _selectDate(context);
      },
      child: AbsorbPointer(
        absorbing: _hasBookings,
        child: Opacity(
          opacity: _hasBookings ? 0.6 : 1,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _selectedDate != null
                    ? cs.primary
                    : cs.outline.withOpacity(0.25),
                width: _selectedDate != null ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              Icon(
                Icons.calendar_today_outlined,
                color: _selectedDate != null
                    ? cs.primary
                    : cs.onSurfaceVariant,
                size: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.watch<TranslateProvider>().t('txt_date'),
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedDate == null
                          ? context
                          .watch<TranslateProvider>()
                          .t('txt_select_date')
                          : _formatDate(_selectedDate!),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _timePicker(ColorScheme cs) {
    return GestureDetector(
      onTap: () => _selectTime(context),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _selectedTime != null ? cs.primary : cs.outline.withOpacity(0.25),
            width: _selectedTime != null ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Icon(Icons.access_time_outlined,
              color: _selectedTime != null ? cs.primary : cs.onSurfaceVariant, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.watch<TranslateProvider>().t('txt_ride_status_time'), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(_selectedTime == null ? context.watch<TranslateProvider>().t('txt_select_time') : _selectedTime!.format(context),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _seatsDropdown(ColorScheme cs) {
    return DropdownButtonFormField<int>(
      value: _seats,
      decoration: InputDecoration(
        labelText: context.watch<TranslateProvider>().t('txt_ride_status_seats'),
        labelStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.event_seat, color: cs.onPrimaryContainer, size: 16),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: cs.surface,
      ),
      items: List.generate(
        8,
            (i) => DropdownMenuItem(
          value: i + 1,
          child: Text('${i + 1} Seat${i + 1 > 1 ? 's' : ''}'),
        ),
      ),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _seats = val;
          });
        }
      },
      dropdownColor: cs.surface,
    );
  }

  Widget _priceField(ColorScheme cs) {
    return TextFormField(
      controller: _priceController, // ✅
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: context.watch<TranslateProvider>().t('txt_price_per_seat'),
        labelStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(6),
          decoration:
          BoxDecoration(color: cs.primaryContainer.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
          child: Text("c"),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outline.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        filled: true,
        fillColor: cs.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      validator: (v) => (v?.isEmpty == true || double.tryParse(v!) == null) ? 'Enter valid price' : null,
      onChanged: (v) => setState(() => _price = double.tryParse(v) ?? 0),
    );
  }

  Widget _extrasGrid(ColorScheme cs) {

    return Consumer<SearchProvider>(
      builder: (context, provider, _) {
        final services = provider.services;

        // for (var s in services) {
        //   if (isEditMode && _selectedServiceIds.contains(s.id.toString())) {
        //     s.isSelected = true; // ✅ AUTO SELECT
        //   }
        // }

        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // final services = provider.services;
        if (services.isEmpty) {
          return Text(context.watch<TranslateProvider>().t('txt_no_service_available'));
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    if (date.day == now.day && date.month == now.month && date.year == now.year) return 'Today';
    if (date.day == tomorrow.day && date.month == tomorrow.month && date.year == tomorrow.year) return 'Tomorrow';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _publishRide() async {
    if (_formKey.currentState?.validate() != true ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<TranslateProvider>().t('txt_please_fill_all_fields'),
          ),
        ),
      );
      return;
    }

    final provider = Provider.of<SearchProvider>(context, listen: false);

    try {
      final res = isEditMode
          ? await provider.updateRide(
        rideId: widget.ride!['ride_id'].toString(),
        departure: _departureController.text,
        destination: _destinationController.text,
        date: _selectedDate!,
        time: _selectedTime!,
        seats: _seats!,
        price: _price,
        vehicleId: _selectedVehicle!.id.toString(),
        extras: provider.services,
        acceptPackages: _acceptPackages,
        isPermanent: _isPermanent,

      )
          : await provider.publishRide(
        departure: _departureController.text,
        destination: _destinationController.text,
        date: _selectedDate!,
        time: _selectedTime!,
        seats: _seats!,
        price: _price,
        vehicleId: _selectedVehicle!.id.toString(),
        extras: provider.services,
        acceptPackages: _acceptPackages,
        isPermanent: _isPermanent,

      );

      if (!mounted) return;

      if (res['status'] == true) {
        final msg = isEditMode
            ? context.read<TranslateProvider>().t('txt_ride_updated_successfully')
            : context.read<TranslateProvider>().t('txt_ride_published_successfully');

        // ✅ SIMPLE snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );

        // ✅ navigate safely
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Viewresponcescreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }



  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: DatePickerThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            headerBackgroundColor: Theme.of(context).colorScheme.primary,
            headerForegroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _selectTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            dialBackgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          ),
        ),
        child: child!,
      ),
    );
    if (time != null) setState(() => _selectedTime = time);
  }
}

// Bottom vehicle bar (compact)
class _VehicleBottomBar extends StatelessWidget {
  final Vehicle vehicle;
  final bool compact;
  const _VehicleBottomBar({required this.vehicle, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant.withOpacity(0.4))),
        boxShadow: [BoxShadow(color: cs.shadow.withOpacity(0.06), offset: const Offset(0, -1), blurRadius: 6)],
      ),
      padding: EdgeInsets.all(compact ? 12 : 20),
      child: SafeArea(
        child: Row(children: [
          Container(
            width: compact ? 52 : 64,
            height: compact ? 52 : 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: vehicle.imagePath != null
                  ? Image.network("https://qadampayk.com/assets/vehicle_image/${vehicle.imagePath!}", fit: BoxFit.cover)
                  : Container(
                color: cs.primaryContainer.withOpacity(0.2),
                child: Icon(Icons.directions_car, color: cs.onPrimaryContainer, size: compact ? 22 : 28),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('${vehicle.brand} ${vehicle.model}',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: cs.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [
                const SizedBox(width: 6),
                _chip(vehicle.plate.toString(), Icons.numbers, cs, compact),
              ]),
            ]),
          ),
          // IconButton(
          //   onPressed: () {
          //     ScaffoldMessenger.of(context).showSnackBar(
          //         SnackBar(content: Text(context.watch<TranslateProvider>().t('txt_edi_vehicle_not_implemented')))
          //     );
          //   },
          //   icon: Icon(Icons.edit_outlined, color: cs.onSurfaceVariant, size: compact ? 18 : 20),
          //   style: IconButton.styleFrom(
          //     backgroundColor: cs.surfaceContainerLow,
          //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          //     visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
          //     padding: const EdgeInsets.all(8),
          //   ),
          // ),
        ]),
      ),
    );
  }

  Widget _chip(String text, IconData icon, ColorScheme cs, bool compact) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 3 : 4),
      decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: compact ? 12 : 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(fontSize: compact ? 11 : 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
      ]),
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
            child: SvgPicture.asset(widget.icon, height: 20),
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
    // for (var s in Provider.of<SearchProvider>(context, listen: false).services) {
    //   s.isSelected = false;
    // }
    super.dispose();
  }
}