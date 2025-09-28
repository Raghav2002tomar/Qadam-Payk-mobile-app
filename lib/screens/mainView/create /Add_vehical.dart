import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../HomeShell.dart';
import '../search/controller/search_provoder.dart';
import 'VehicleStorage.dart';

class VehicleScreen extends StatefulWidget {
  final Vehicle? vehicle; // If null → add, else → edit
  const VehicleScreen({super.key, this.vehicle});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _vehicleImage;
  bool _imageError = false;

  final _plateCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();

  final SuggestionsController<String> _modelSuggestionsController =
  SuggestionsController();
  final FocusNode _modelFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Pre-fill fields if editing
    if (widget.vehicle != null) {
      _brandCtrl.text = widget.vehicle!.brand ?? '';
      _modelCtrl.text = widget.vehicle!.model ?? '';
      _plateCtrl.text = widget.vehicle!.plate ?? '';
      if (widget.vehicle!.imagePath != null &&
          widget.vehicle!.imagePath!.startsWith('http')) {
        // leave _vehicleImage null → show network image
      } else if (widget.vehicle!.imagePath != null) {
        _vehicleImage = File(widget.vehicle!.imagePath!);
      }
    }

    // Fetch brands when screen loads
    Future.microtask(() {
      Provider.of<SearchProvider>(context, listen: false).fetchCarBrands();
    });

    _modelFocusNode.addListener(() {
      final provider = Provider.of<SearchProvider>(context, listen: false);
      if (_modelFocusNode.hasFocus &&
          _modelCtrl.text.isEmpty &&
          !provider.isLoading &&
          provider.models.isNotEmpty) {
        _modelSuggestionsController.refresh();
        _modelSuggestionsController.open();
      }
    });
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _modelSuggestionsController.dispose();
    _modelFocusNode.dispose();
    super.dispose();
  }

  String? _requiredText(String? v) =>
      (v == null || v.isEmpty) ? 'This field is required' : null;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _vehicleImage = File(pickedFile.path);
        _imageError = false;
      });
    }
  }

  Future<void> _saveVehicle() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (_vehicleImage == null && (widget.vehicle?.imagePath == null)) {
      setState(() => _imageError = true);
    }
    if (!ok || (_vehicleImage == null && widget.vehicle?.imagePath == null))
      return;

    final newVehicle = Vehicle(
      id: widget.vehicle?.id,
      brand: _brandCtrl.text,
      model: _modelCtrl.text,
      plate: _plateCtrl.text,
      imagePath: _vehicleImage?.path ?? widget.vehicle?.imagePath,
    );

    await VehicleStorage.save(newVehicle);

    final provider = Provider.of<SearchProvider>(context, listen: false);

    try {
      if (widget.vehicle != null) {
        // Edit mode
        await provider.updateVehicle(
          id: widget.vehicle!.id.toString(),
          brand: newVehicle.brand ?? "",
          model: newVehicle.model ?? "",
          plate: newVehicle.plate ?? "",
          vehicleImagePath: _vehicleImage?.path ?? newVehicle.imagePath,
        );
      } else {
        // Add mode
        await provider.addVehicle(
          brand: newVehicle.brand ?? "",
          model: newVehicle.model ?? "",
          plate: newVehicle.plate ?? "",
          vehicleImagePath: _vehicleImage?.path ?? '',
        );
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to save vehicle"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.vehicle != null
              ? "✅ Vehicle updated successfully!"
              : "✅ Vehicle added successfully!",
        ),
        backgroundColor: const Color(0xFF008955),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.pop(context, newVehicle);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Consumer<SearchProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: Text(
              widget.vehicle != null ? "Edit Vehicle" : "Add Vehicle",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          body: provider.isLoading && provider.brands.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionTitle("Vehicle Information"),
                  const SizedBox(height: 12),
                  _buildCard(
                    child: Column(
                      children: [
                        _typeAheadField(
                          label: "Car Brand",
                          controller: _brandCtrl,
                          cs: cs,
                          suggestions:
                          provider.brands.map((b) => b.brand ?? '').toList(),
                          onSelected: (brand) async {
                            _brandCtrl.text = brand;
                            _modelCtrl.clear();
                            await provider.fetchCarModels(brand);
                            _modelSuggestionsController.refresh();
                            FocusScope.of(context)
                                .requestFocus(_modelFocusNode);
                          },
                        ),
                        const SizedBox(height: 12),
                        _typeAheadField(
                          label: "Car Model",
                          controller: _modelCtrl,
                          cs: cs,
                          enabled: _brandCtrl.text.isNotEmpty &&
                              !provider.isLoading,
                          suggestions: provider.models,
                          suggestionsController: _modelSuggestionsController,
                          focusNode: _modelFocusNode,
                        ),
                        const SizedBox(height: 12),
                        _licensePlateField(cs),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Vehicle Image"),
                  const SizedBox(height: 12),
                  _buildCard(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: cs.surfaceVariant.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _imageError
                                ? cs.error
                                : cs.outline.withOpacity(0.4),
                            width: 1.2,
                          ),
                        ),
                        child: _vehicleImage != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _vehicleImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                            : (widget.vehicle?.imagePath != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network("https://qadampayk.com/assets/vehicle_image/${widget.vehicle!.imagePath!}"
                            ,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                            : Center(
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_rounded,
                                size: 36,
                                color: _imageError
                                    ? cs.error
                                    : const Color(0xFF666666),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Tap to upload vehicle image",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: _imageError
                                      ? cs.error
                                      : const Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ),
                    ),
                  ),
                  if (_imageError)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        "Vehicle image is required",
                        style: TextStyle(color: cs.error, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.save_rounded),
                    onPressed: _saveVehicle,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF008955),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: Text(
                      widget.vehicle != null ? 'Update Vehicle' : 'Save Vehicle',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),

                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _typeAheadField({
    required String label,
    required TextEditingController controller,
    required ColorScheme cs,
    required List<String> suggestions,
    void Function(String)? onSelected,
    bool enabled = true,
    SuggestionsController<String>? suggestionsController,
    FocusNode? focusNode,
  }) {
    return TypeAheadField<String>(
      suggestionsController: suggestionsController,
      focusNode: focusNode,
      suggestionsCallback: (pattern) {
        return suggestions
            .where((e) => e.toLowerCase().contains(pattern.toLowerCase()))
            .toList();
      },
      builder: (context, textEditingController, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      itemBuilder: (context, suggestion) => ListTile(
        dense: true,
        leading: Icon(Icons.directions_car, color: cs.primary, size: 16),
        title: Text(suggestion,
            style: TextStyle(fontSize: 13, color: cs.onSurface)),
      ),
      onSelected: (s) {
        controller.text = s;
        if (onSelected != null) onSelected(s);
      },
    );
  }

  Widget _licensePlateField(ColorScheme cs) {
    return TextFormField(
      controller: _plateCtrl,
      validator: _requiredText,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: "License Plate Number",
        labelStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF1A1A1A),
    ),
  );

  Widget _buildCard({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}
