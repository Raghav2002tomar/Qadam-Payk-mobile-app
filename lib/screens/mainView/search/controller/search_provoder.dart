import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path/path.dart';
//
import 'package:provider/provider.dart';

import '../../../../api_service/api_serviece.dart';
import '../../../../api_service/app_constocter.dart';
import '../../../../api_service/logger.dart';
import '../../../../models/CityModel.dart';
import '../../../../models/carModel.dart';

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../api_service/app_constocter.dart';
import '../../../../models/CityModel.dart';
import '../../../../providers/translate_provider.dart';
import '../../../../service/local_cache.dart';
import '../../create/VehicleStorage.dart';
import '../model/service_model.dart';

class SearchProvider extends ChangeNotifier {
  final App_Constructor appConstructor = App_Constructor();
  final Api_Service apiService = Api_Service(); // Instance of Api_Service

  // ✅ Car Brand & Model Data
  List<BrandData> _brands = [];
  List<BrandData> get brands => _brands;

  List<String> _models = [];
  List<String> get models => _models;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  List<City> _cities = [];
  List<City> get cities => _cities;
  List<ServiceModel> _services = []; // <-- new list for services
  List<ServiceModel> get services => _services;

  // bool _isLoading = false;
  // bool get isLoading => _isLoading;

  Future<void> fetchCities(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final language =
          context.read<TranslateProvider>().locale; // ✅ dynamic language

      final url = Uri.parse('${appConstructor.BaseURL}${appConstructor.getCity}?language=$language');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          _cities = (data['data'] as List)
              .map((json) => City.fromJson(json))
              .toList();
        }
      }
    } catch (e) {
      appLog("Error fetching cities: $e");
    }

    _isLoading = false;
    notifyListeners();
  }
  /// ✅ Fetch Car Brands
  Future<void> fetchCarBrands() async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse('${appConstructor.BaseURL}${appConstructor.getCarBrand}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          _brands = (data['data'] as List)
              .map((json) => BrandData.fromJson(json))
              .toList();
        }
      }
    } catch (e) {
      appLog("❌ Error fetching car brands: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  /// ✅ Fetch Car Models (based on selected brand)
  Future<void> fetchCarModels(String brand) async {
    _isLoading = true;
    _models = []; // ✅ clear previous data first
    notifyListeners();

    try {
      // ✅ encode brand in case it has spaces or special chars
      final encodedBrand = Uri.encodeComponent(brand);
      final url = Uri.parse('${appConstructor.BaseURL}/api/get-car-models/$encodedBrand');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          _models = List<String>.from(data['data']);
        } else {
          _models = []; // ✅ if API says no data, reset models
        }
      } else {
        _models = []; // ✅ reset on error
      }
    } catch (e) {
      appLog("❌ Error fetching car models: $e");
      _models = []; // ✅ reset on exception
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchServices() async {
    _isLoading = true;
    _services = [];
    notifyListeners();

    try {
      final url = Uri.parse('${appConstructor.BaseURL}${appConstructor.fetchServices}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final parsed = FetchServicesResponse.fromJson(jsonData);

        if (parsed.status == true) {
          _services = parsed.data ?? [];
        } else {
          _services = [];
        }
      } else {
        _services = [];
      }
    } catch (e) {
      appLog("❌ Error fetching services: $e");
      _services = [];
    }

    _isLoading = false;
    notifyListeners();
  }


  Future<dynamic> addVehicle({
    required String brand,
    required String model,
    required String plate,
    required String vehicleImagePath, // local path string
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await LocalCache.getToken();
      final uri = Uri.parse('${appConstructor.BaseURL}${appConstructor.addCar}');
      var request = http.MultipartRequest('POST', uri);

      // Add text fields
      request.fields['brand'] = brand;
      request.fields['model'] = model;
      request.fields['number_plate'] = plate;

      // ✅ Attach file from path
      if (vehicleImagePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'vehicle_image',
            vehicleImagePath,
            filename: vehicleImagePath.split('/').last,
          ),
        );
      }

      // Headers
      request.headers['Authorization'] = "Bearer $token";

      // Send
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          "Server Error: ${response.statusCode} - ${response.reasonPhrase}\n${response.body}",
        );
      }
    } catch (e) {
      appLog("❌ Error adding vehicle: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<dynamic> updateVehicle({
    required String id,
    required String brand,
    required String model,
    required String plate,
    required String? vehicleImagePath, // can be null if not updating
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await LocalCache.getToken();
      final uri = Uri.parse(
        '${appConstructor.BaseURL}${appConstructor.updateCar}',
      );
      // 👆 Make sure updateCar is defined in your App_Constructor

      var request = http.MultipartRequest('POST', uri);

      // Required fields
      request.fields['brand'] = brand;
      request.fields['model'] = model;
      request.fields['number_plate'] = plate;
      request.fields['vehicle_id'] = id;

      // ✅ Attach file only if new image picked
      if (vehicleImagePath != null && vehicleImagePath.isNotEmpty && !vehicleImagePath.startsWith("http")) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'vehicle_image',
            vehicleImagePath,
            filename: vehicleImagePath.split('/').last,
          ),
        );
      }

      // Headers
      request.headers['Authorization'] = "Bearer $token";

      // Send
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          "Server Error: ${response.statusCode} - ${response.reasonPhrase}\n${response.body}",
        );
      }
    } catch (e) {
      appLog("❌ Error updating vehicle");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  List<Vehicle> _vehicles = [];
  List<Vehicle> get vehicles => _vehicles;

  bool _isLoadingVehicles = false;
  bool get isLoadingVehicles => _isLoadingVehicles;

  Future<void> fetchVehicles() async {
    _isLoadingVehicles = true;
    notifyListeners();

    try {
      final token = await LocalCache.getToken();
      final url = Uri.parse('${appConstructor.BaseURL}${appConstructor.fetchCar}'); // Your API endpoint
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          _vehicles = (data['data'] as List)
              .map((json) => Vehicle.fromJson(json))
              .toList();
        } else {
          _vehicles = [];
        }
      } else {
        _vehicles = [];
      }
    } catch (e) {
      appLog("❌ Error fetching vehicles: $e");
      _vehicles = [];
    } finally {
      _isLoadingVehicles = false;
      notifyListeners();
    }
  }



  Future<Map<String, dynamic>> publishRide({
    required String departure,
    required String destination,
    required DateTime date,
    required TimeOfDay time,
    required int seats,
    required double price,
    required String vehicleId,
    required List<ServiceModel> extras, // your ServiceModel list
    required bool acceptPackages,
  }) async {
    try {
      final token = await LocalCache.getToken(); // your auth token
      final uri = Uri.parse('${appConstructor.BaseURL}${appConstructor.publishRide}');

      // Convert selected services to a list of IDs as strings
      List<String> selectedServiceIds = extras
          .where((s) => s.isSelected)
          .map((s) => s.id.toString())
          .toList();

      final body = {
        "pickup_location": departure,
        "destination": destination,
        "ride_date": date.toIso8601String(),
        "ride_time": "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
        "number_of_seats": seats.toString(), // <-- sending as string
        "price": price.toString(),           // <-- sending as string
        "vehicle_id": vehicleId,
        "services": selectedServiceIds,      // <-- list of strings
        "accept_parcel": acceptPackages ? "1" : "0",
      };


      final response = await http.post(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to publish ride: ${response.body}");
      }
    } catch (e) {
      appLog("❌ Error publishing ride: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateRide({
    required String rideId,
    required String departure,
    required String destination,
    required DateTime date,
    required TimeOfDay time,
    required int seats,
    required double price,
    required String vehicleId,
    required List<ServiceModel> extras,
    required bool acceptPackages,
  }) async {
    try {
      final token = await LocalCache.getToken();
      final uri = Uri.parse(
        '${appConstructor.BaseURL}${appConstructor.updateRide}', // 👈 NEW endpoint
      );

      // Selected services → IDs
      List<String> selectedServiceIds = extras
          .where((s) => s.isSelected)
          .map((s) => s.id.toString())
          .toList();

      final body = {
        "ride_id": rideId.toString(), // ✅ REQUIRED FOR UPDATE
        "pickup_location": departure,
        "destination": destination,
        // "ride_date": date.toString(),
        "ride_date": DateFormat('dd-MM-yyyy').format(date),
        "ride_time":
        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
        "number_of_seats": seats.toString(),
        "price": price.toString(),
        "vehicle_id": vehicleId,
        "services": selectedServiceIds,
        "accept_parcel": acceptPackages ? "1" : "0",
      };

      final response = await http.post( // or http.put if backend supports
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to update ride: ${response.body}");
      }
    } catch (e) {
      appLog("❌ Error updating ride: $e");
      rethrow;
    }
  }



}




class BrandData {
  String? brand;
  BrandData({this.brand});

  factory BrandData.fromJson(Map<String, dynamic> json) {
    return BrandData(brand: json['brand']);
  }

  Map<String, dynamic> toJson() => {'brand': brand};
}

