import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color kPrimaryColor = Color(0xFF008955);

class AddressSearchScreen extends StatefulWidget {
  final LatLng? currentLocation;

  const AddressSearchScreen({super.key, this.currentLocation});

  @override
  State<AddressSearchScreen> createState() => _AddressSearchScreenState();
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List results = [];
  List<Map<String, dynamic>> recentLocations = [];
  bool isLoading = false;
  bool showRecent = true;

  @override
  void initState() {
    super.initState();
    _loadRecentLocations();
  }

  Future<void> _loadRecentLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final recent = prefs.getStringList('recent_locations') ?? [];
    setState(() {
      recentLocations = recent
          .map((item) => json.decode(item) as Map<String, dynamic>)
          .toList();
    });
  }

  Future<void> _saveRecentLocation(Map<String, dynamic> location) async {
    final prefs = await SharedPreferences.getInstance();

    recentLocations.removeWhere(
          (item) => item['address'] == location['address'],
    );

    recentLocations.insert(0, location);

    if (recentLocations.length > 5) {
      recentLocations = recentLocations.sublist(0, 5);
    }

    await prefs.setStringList(
      'recent_locations',
      recentLocations.map((item) => json.encode(item)).toList(),
    );
  }

  Future<void> searchAddress(String query) async {
    if (query.length < 3) {
      setState(() {
        results = [];
        showRecent = true;
      });
      return;
    }

    setState(() {
      isLoading = true;
      showRecent = false;
    });

    try {
      String url = "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=10";

      if (widget.currentLocation != null) {
        url +=
        "&lat=${widget.currentLocation!.latitude}&lon=${widget.currentLocation!.longitude}";
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'com.qadampayk.app'},
      );

      if (response.statusCode == 200) {
        setState(() {
          results = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Search error: $e");
    }
  }

  void _selectLocation(Map<String, dynamic> location) {
    _saveRecentLocation(location);
    Navigator.pop(context, location);
  }

  Future<void> _clearRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_locations');
    setState(() {
      recentLocations = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Select Location",
          style: TextStyle(color: Colors.black87, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          // Compact Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Search location...",
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: kPrimaryColor, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      results = [];
                      showRecent = true;
                    });
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
              onChanged: searchAddress,
            ),
          ),

          // Loading indicator
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 3),
            ),

          // Recent locations
          if (showRecent && recentLocations.isNotEmpty && !isLoading)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Recent",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        TextButton(
                          onPressed: _clearRecent,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text("Clear", style: TextStyle(fontSize: 12, color: kPrimaryColor)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: recentLocations.length,
                      itemBuilder: (context, index) {
                        final location = recentLocations[index];
                        return _buildCompactLocationTile(
                          address: location['address'],
                          icon: Icons.history,
                          iconColor: Colors.grey.shade600,
                          onTap: () => _selectLocation(location),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Search results
          if (!showRecent && !isLoading)
            Expanded(
              child: results.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "No results found",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final place = results[index];
                  return _buildCompactLocationTile(
                    address: place['display_name'],
                    icon: Icons.location_on,
                    iconColor: kPrimaryColor,
                    onTap: () {
                      final location = {
                        "lat": double.parse(place['lat']),
                        "lng": double.parse(place['lon']),
                        "address": place['display_name']
                      };
                      _selectLocation(location);
                    },
                  );
                },
              ),
            ),

          // Empty state
          if (showRecent && recentLocations.isEmpty && !isLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_searching,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Search for a location",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Enter address or place name",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactLocationTile({
    required String address,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final parts = address.split(',');
    final mainPart = parts.isNotEmpty ? parts[0].trim() : address;
    final detailPart = parts.length > 1
        ? parts.sublist(1).join(',').trim()
        : '';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mainPart,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (detailPart.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      detailPart,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}