import 'package:bla_bla_car/screens/mainView/search/parcel_list_screen.dart';
import 'package:bla_bla_car/screens/mainView/search/ride_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';


import '../../../providers/translate_provider.dart';
import '../../../service/colors.dart';
import 'controller/search_provoder.dart';

class SearchHome extends StatefulWidget {
  const SearchHome({super.key});

  @override
  State<SearchHome> createState() => _SearchHomeState();
}

class _SearchHomeState extends State<SearchHome> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();

  final GlobalKey<_LocationFieldState> _fromFieldKey = GlobalKey();
  final GlobalKey<_LocationFieldState> _toFieldKey = GlobalKey();
  final GlobalKey<_LocationFieldState> _pickupFieldKey = GlobalKey();
  final GlobalKey<_LocationFieldState> _dropFieldKey = GlobalKey();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  int _passengerCount = 1;
  int _selectedTabIndex = 0; // 0 = Ride, 1 = Parcel

  List<String> _cityNames = [];
  bool _isLoadingCities = true;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    final provider = SearchProvider();
    await provider.fetchCities();
    setState(() {
      _cityNames = provider.cities.map((e) => e.cityName).toList();
      _isLoadingCities = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final String bgImage = _selectedTabIndex == 0
        ? "assets/images/ride_car.png"
        : "assets/images/parcel.png";

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        // ✅ Close keyboard
        FocusScope.of(context).unfocus();

        // ✅ Close any open dropdowns
        // _fromFieldKey.currentState?._hideDropdown();
        // _toFieldKey.currentState?._hideDropdown();
        // _pickupFieldKey.currentState?._hideDropdown();
        // _dropFieldKey.currentState?._hideDropdown();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,

        body: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                bgImage,
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 200),
                    Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: 16,
                          left: 16,
                          right: 16,
                          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: cs.surfaceVariant.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                children: [
                                  _buildTabButton(context.watch<TranslateProvider>().t('txt_taxi'), 0, cs),
                                  _buildTabButton(context.watch<TranslateProvider>().t('txt_parcel'), 1, cs),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _selectedTabIndex == 0
                                ? _buildRideSearch(cs)
                                : _buildParcelSearch(cs),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoadingCities)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index, ColorScheme cs) {
    final bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedTabIndex != index) {
            setState(() {
              _selectedTabIndex = index;

              // _fromFieldKey.currentState?.clear();
              // _toFieldKey.currentState?.clear();
              // _pickupFieldKey.currentState?.clear();
              // _dropFieldKey.currentState?.clear();

              _selectedDate = DateTime.now();
              _selectedTime = null;
              _passengerCount = 1;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRideSearch(ColorScheme cs) {
    return Column(
      children: [
        _LocationField(
          key: _fromFieldKey,
          label: context.watch<TranslateProvider>().t('txt_leaving_from'),
          controller: _fromController,
          options: _cityNames,
          icon: "assets/images/red_icon.svg",
          cs: cs,
        ),
        const SizedBox(height: 16),
        _LocationField(
          key: _toFieldKey,
          label: context.watch<TranslateProvider>().t('txt_going_to'),
          controller: _toController,
          options: _cityNames,
          icon: "assets/images/blue_icon.svg",
          cs: cs,
        ),
        const SizedBox(height: 16),
        _buildDatePicker(cs),
        const SizedBox(height: 8),
        _buildPassengerSelector(cs),
        const SizedBox(height: 24),
        _buildSearchButton(cs),
      ],
    );
  }

  Widget _buildParcelSearch(ColorScheme cs) {
    return Column(
      children: [
        _LocationField(
          key: _pickupFieldKey,
          label: context.watch<TranslateProvider>().t('txt_pickup_location'),
          controller: _pickupController,
          options: _cityNames,
          icon: "assets/images/red_icon.svg",
          cs: cs,
        ),
        const SizedBox(height: 16),
        _LocationField(
          key: _dropFieldKey,
          label: context.watch<TranslateProvider>().t('txt_drop_location'),
          controller: _dropController,
          options: _cityNames,
          icon: "assets/images/blue_icon.svg",
          cs: cs,
        ),
        const SizedBox(height: 16),
        _buildDatePicker(cs),
        const SizedBox(height: 8),
        _buildTimePicker(cs),
        const SizedBox(height: 24),
        _buildSearchButton(cs),
      ],
    );
  }

  Widget _buildDatePicker(ColorScheme cs) {
    return InkWell(
      onTap: () async {
        FocusScope.of(context).unfocus();

          // Close keyboard
          FocusScope.of(context).unfocus();

          // Close all open dropdowns
          // _fromFieldKey.currentState?._hideDropdown();
          // _toFieldKey.currentState?._hideDropdown();
          // _pickupFieldKey.currentState?._hideDropdown();
          // _dropFieldKey.currentState?._hideDropdown();


        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset("assets/images/calendar.png", height: 20),
                const SizedBox(width: 8),
                Text(
                  context.watch<TranslateProvider>().t('txt_date'),
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              DateFormat('EEE, MMM d').format(_selectedDate),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(ColorScheme cs) {
    return InkWell(
      onTap: () async {
        FocusScope.of(context).unfocus();
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (picked != null) setState(() => _selectedTime = picked);
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  context.watch<TranslateProvider>().t('txt_pickup_time'),
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              _selectedTime != null
                  ? _selectedTime!.format(context)
                  : context.watch<TranslateProvider>().t('txt_select_time'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerSelector(ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset("assets/images/user.png", width: 24, height: 24),
            const SizedBox(width: 8),
            Text(
              context.watch<TranslateProvider>().t('txt_passengers'),
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: cs.primary),
              onPressed: _passengerCount > 1
                  ? () => setState(() => _passengerCount--)
                  : null,
            ),
            Text(
              '$_passengerCount',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: cs.primary),
              onPressed: () => setState(() => _passengerCount++),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchButton(ColorScheme cs) {
    final String label = _selectedTabIndex == 0 ? context.watch<TranslateProvider>().t('txt_search_ride') : context.watch<TranslateProvider>().t('txt_search_parcel');
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
          onPressed: () {
            if (_selectedTabIndex == 0) {
              final rideData = {
                "from": _fromController.text,
                "to": _toController.text,
                "date": DateFormat('dd-MM-yyyy').format(_selectedDate),
                "passengers": _passengerCount,
              };
              print("Ride Data: $rideData");

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RideListScreen(rideData: rideData),
                ),
              );
            } else {
              final parcelData = {
                "pickup": _pickupController.text,
                "drop": _dropController.text,
                "date": DateFormat("dd-MM-yyyy").format(_selectedDate),
                "time": _selectedTime?.format(context) ?? "",
              };
              print("Parcel Data: $parcelData");

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ParcelListScreen(parcelData: parcelData),
                ),
              );
            }
          },
        child: Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

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
  final FocusNode _focusNode = FocusNode();
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
    widget.controller.addListener(_filterOptions);
  }

  void _filterOptions() {
    final query = widget.controller.text.toLowerCase();
    setState(() {
      _filteredOptions = query.isEmpty
          ? widget.options
          : widget.options
          .where((city) => city.toLowerCase().contains(query))
          .toList();
    });
    if (_filteredOptions.isNotEmpty && _focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    _overlayEntry = _createOverlay();
    Overlay.of(context).insert(_overlayEntry!);

    // Listen to scrolling to hide dropdown
    _scrollPosition = Scrollable.of(context)?.position;
    _scrollPosition?.addListener(_removeOverlay);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;

    // Remove scroll listener
    _scrollPosition?.removeListener(_removeOverlay);
    _scrollPosition = null;
  }

  OverlayEntry _createOverlay() {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32, // adjust padding
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60), // height of TextField + margin
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
                    leading: const Icon(Icons.location_city,
                        color: AppTheme.seedPrimary),
                    title: Text(city),
                    onTap: () {
                      widget.controller.text = city;
                      _removeOverlay();
                      FocusScope.of(context).unfocus(); // ✅ hide keyboard

                      // _focusNode.requestFocus(); // keep keyboard open
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        focusNode: _focusNode,
        controller: widget.controller,
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
          _focusNode.requestFocus();
          Future.delayed(const Duration(microseconds: 800), () {
            if (_filteredOptions.isNotEmpty && _focusNode.hasFocus) {
              _showOverlay();
            }
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_filterOptions);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }
}
