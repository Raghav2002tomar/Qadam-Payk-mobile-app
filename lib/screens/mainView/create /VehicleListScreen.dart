import 'package:flutter/material.dart';
import '../search/controller/search_provoder.dart';
import 'Add_vehical.dart';
import 'VehicleStorage.dart';
import 'Ride_Screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    try {
      final provider = SearchProvider();
      await provider.fetchVehicles();
      setState(() {
        _vehicles = provider.vehicles;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load vehicles')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Vehicle'),
        centerTitle: true,
        actions: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VehicleScreen()),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.add),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
          ? const Center(child: Text('No Vehicles Found'))
          : RefreshIndicator(
        onRefresh: _loadVehicles, // ✅ pull to refresh
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(), // ✅ ensures pull works even if list is small
          padding: const EdgeInsets.all(12),
          itemCount: _vehicles.length,
          itemBuilder: (context, index) {
            final v = _vehicles[index];
            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: v.imagePath != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network("https://qadampayk.com/assets/vehicle_image/${v.imagePath!}",
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.directions_car,
                            size: 40, color: Colors.grey),
                      );
                    },
                  ),
                )
                    : const Icon(Icons.directions_car, size: 50),
                title: Text(
                  '${v.brand} ${v.model}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    v.plate.toString(),
                    style: const TextStyle(
                        fontSize: 14, color: Colors.black87),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon:
                      const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () async {
                        // Navigate to VehicleScreen in edit mode
                        final updatedVehicle =
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                VehicleScreen(vehicle: v),
                          ),
                        );

                        if (updatedVehicle != null) {
                          setState(() {
                            _vehicles[index] = updatedVehicle;
                          });
                        }
                      },
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
                onTap: () {
                  Navigator.pop(context, v); // select vehicle
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
