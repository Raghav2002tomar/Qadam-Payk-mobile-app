import 'package:bla_bla_car/providers/translate_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../api_service/logger.dart';
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

  final _customBrandCtrl = TextEditingController();
  final _customModelCtrl = TextEditingController();

  bool isCustom = false;

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
      if (widget.vehicle!.imagePath != null) {
        _vehicleImage = null;
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
    _customBrandCtrl.dispose();
    _customModelCtrl.dispose();
    _modelSuggestionsController.dispose();
    _modelFocusNode.dispose();
    super.dispose();
  }

  String? _requiredText(String? v) =>
      (v == null || v.isEmpty) ? context.watch<TranslateProvider>().t('txt_field_required') : null;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File originalFile = File(pickedFile.path);

      final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        originalFile.path,
        "${originalFile.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg",
        quality: 60,
        minWidth: 1000,
        minHeight: 1000,
      );

      File? compressedFile = compressedXFile != null ? File(compressedXFile.path) : null;

      setState(() {
        _vehicleImage = compressedFile ?? originalFile;
        _imageError = false;
      });
    }
  }

  Future<void> _saveVehicle() async {
    final ok = _formKey.currentState?.validate() ?? false;

    if (_vehicleImage == null && (widget.vehicle?.imagePath == null)) {
      setState(() => _imageError = true);
    }

    if (!ok || (_vehicleImage == null && widget.vehicle?.imagePath == null)) return;

    final brand = isCustom ? _customBrandCtrl.text : _brandCtrl.text;
    final model = isCustom ? _customModelCtrl.text : _modelCtrl.text;

    final newVehicle = Vehicle(
      id: widget.vehicle?.id,
      brand: brand,
      model: model,
      plate: _plateCtrl.text,
      imagePath: _vehicleImage?.path ?? widget.vehicle?.imagePath,
    );

    await VehicleStorage.save(newVehicle);

    final provider = Provider.of<SearchProvider>(context, listen: false);

    try {
      if (widget.vehicle != null) {
        await provider.updateVehicle(
          id: widget.vehicle!.id.toString(),
          brand: newVehicle.brand ?? "",
          model: newVehicle.model ?? "",
          plate: newVehicle.plate ?? "",
          vehicleImagePath: _vehicleImage?.path ?? "",
        );
      } else {
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
          content: Text(context.read<TranslateProvider>().t('txt_failed_to_save_vehicle')),
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
              ? context.read<TranslateProvider>().t('txt_vehicle_updated_success')
              : context.read<TranslateProvider>().t('txt_vehicle_added_success'),
        ),
        backgroundColor: const Color(0xFF008955),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.push(context, MaterialPageRoute(builder: (context) => HomeShell()));
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
              widget.vehicle != null
                  ? context.watch<TranslateProvider>().t('txt_edit_vehicle')
                  : context.watch<TranslateProvider>().t('txt_add_vehicle'),
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
                  _buildSectionTitle(context.watch<TranslateProvider>().t('txt_vehicle_info')),
                  const SizedBox(height: 12),
                  _buildCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  isCustom = !isCustom;
                                  if (!isCustom) {
                                    _customBrandCtrl.clear();
                                    _customModelCtrl.clear();
                                  }
                                });
                              },
                              child: Row(
                                children: [
                                  Text(
                                    isCustom ? "Cancel" : "Custom",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue),
                                  ),
                                  Icon(
                                    isCustom ? Icons.close : Icons.add,
                                    color: Colors.blue,
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        isCustom
                            ? Column(
                          children: [
                            TextFormField(
                              controller: _customBrandCtrl,
                              validator: _requiredText,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                labelText: context
                                    .watch<TranslateProvider>()
                                    .t('txt_car_brand'),
                                labelStyle: TextStyle(
                                    fontSize: 13,
                                    color: cs.onSurfaceVariant),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _customModelCtrl,
                              validator: _requiredText,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                labelText: context
                                    .watch<TranslateProvider>()
                                    .t('txt_car_model'),
                                labelStyle: TextStyle(
                                    fontSize: 13,
                                    color: cs.onSurfaceVariant),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        )
                            : Column(
                          children: [
                            _typeAheadField(
                              label: context
                                  .watch<TranslateProvider>()
                                  .t('txt_car_brand'),
                              controller: _brandCtrl,
                              cs: cs,
                              suggestions: provider.brands
                                  .map((b) => b.brand ?? '')
                                  .toList(),
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
                              label: context
                                  .watch<TranslateProvider>()
                                  .t('txt_car_model'),
                              controller: _modelCtrl,
                              cs: cs,
                              enabled: _brandCtrl.text.isNotEmpty &&
                                  !provider.isLoading,
                              suggestions: provider.models,
                              suggestionsController: _modelSuggestionsController,
                              focusNode: _modelFocusNode,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _licensePlateField(cs),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context.watch<TranslateProvider>().t('txt_vehicle_image')),
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
                          child: Image.network(
                            "https://qadampayk.com/assets/vehicle_image/${widget.vehicle!.imagePath!}",
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              appLog("Image Load Error: $error");
                              return Center(
                                child: Icon(Icons.broken_image,
                                    size: 40, color: Colors.red),
                              );
                            },
                          ),
                        )
                            : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                                context
                                    .watch<TranslateProvider>()
                                    .t('txt_tap_to_upload'),
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
                        context.watch<TranslateProvider>().t('txt_vehicle_image_required'),
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
                      widget.vehicle != null
                          ? context.watch<TranslateProvider>().t('txt_update_vehicle')
                          : context.watch<TranslateProvider>().t('txt_save_vehicle'),
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
        labelText: context.watch<TranslateProvider>().t('txt_license_plate_no'),
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
