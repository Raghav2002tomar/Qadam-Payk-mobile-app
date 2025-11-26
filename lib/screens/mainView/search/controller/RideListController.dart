import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../api_service/api_serviece.dart';
import '../../../../api_service/app_constocter.dart';
import '../../../../service/local_cache.dart';
import '../model/ride_model.dart';

class RideListProvide extends ChangeNotifier {
  // Separate loading states
  bool _isLoadingTrips = false;
  bool _isLoadingRequests = false;
  bool _isLoadingParcels = false;

  bool get isLoadingTrips => _isLoadingTrips;
  bool get isLoadingRequests => _isLoadingRequests;
  bool get isLoadingParcels => _isLoadingParcels;
  bool get isLoading => _isLoadingTrips || _isLoadingRequests || _isLoadingParcels;


  // Separate lists for different data types
  List<RideDataModel> _tripList = [];
  List<RideRequestModel> _rideRequestList = [];
  List<RideRequestModel> _parcelRequestList = []; // New list for parcel requests


  List<RideDataModel> get tripList => _tripList;
  List<RideRequestModel> get rideRequestList => _rideRequestList;
  List<RideRequestModel> get parcelRequestList => _parcelRequestList; // New getter


  // Keep backward compatibility
  List<RideDataModel> get rideList => _tripList;

  Map<String, dynamic>? _driverData;
  Map<String, dynamic>? get driverData => _driverData;

  final App_Constructor appConstructor = App_Constructor();
  final Api_Service apiService = Api_Service();

  Future<void> fetchTripList(
      String pickup,
      String destination,
      String date,
      int seats,
      ) async {
    _isLoadingTrips = true;
    notifyListeners();
    final token = await LocalCache.getToken();

    try {
      final url = Uri.parse(
        '${appConstructor.BaseURL}${appConstructor.fetchtripridelist}'
            '?pickup_location=$pickup&destination=$destination&ride_date=$date&number_of_seats=$seats',
      );

      // 🔑 Replace this with your actual token

      debugPrint("Trip List API URL: $url");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // ✅ Add Bearer token here
        },
      );

      debugPrint("Trip List Response: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          RideList rideListResponse = RideList.fromJson(data);
          _tripList = rideListResponse.data ?? [];
          debugPrint("✅ Loaded ${_tripList.length} trips");
        } else {
          _tripList = [];
          debugPrint("❌ Trip List API Error: ${data['message']}");
        }
      } else {
        _tripList = [];
        debugPrint("❌ Trip List HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching trips: $e");
      _tripList = [];
    }

    _isLoadingTrips = false;
    notifyListeners();
  }


  Future<void> fetchRiderequestlist(
      String pickup,
      String destination,
      String date,
      int seats,
      ) async {
    _isLoadingRequests = true;
    notifyListeners();

    try {
      final url = Uri.parse(
        '${appConstructor.BaseURL}${appConstructor.fetchriderequestlist}'
            '?pickup_location=$pickup&destination=$destination&ride_date=$date&number_of_seats=$seats',
      );

      final response = await http.get(url);

      debugPrint("Ride Request API URL: $url");
      debugPrint("Ride Request Response: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          // Parse as RideRequestModel list
          List<RideRequestModel> requests = [];
          if (data['data'] != null) {
            for (var item in data['data']) {
              requests.add(RideRequestModel.fromJson(item));
            }
          }
          _rideRequestList = requests;
          debugPrint("✅ Loaded ${_rideRequestList.length} ride requests");
        } else {
          _rideRequestList = [];
          debugPrint("❌ Ride Request API Error: ${data['message']}");
        }
      } else {
        _rideRequestList = [];
        debugPrint("❌ Ride Request HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching ride requests: $e");
      _rideRequestList = [];
    }

    _isLoadingRequests = false;
    notifyListeners();
  }

  // New method for fetching parcel requests
  Future<void> fetchParcelequestlist(
      String pickup,
      String destination,
      String date,
      int seats,
      ) async {
    _isLoadingParcels = true;
    notifyListeners();

    try {
      final url = Uri.parse(
        '${appConstructor.BaseURL}${appConstructor.fetchParcelequestlist}'
            '?pickup_location=$pickup&destination=$destination&ride_date=$date&number_of_seats=$seats',
      );

      final response = await http.get(url);

      debugPrint("Parcel Request API URL: $url");
      debugPrint("Parcel Request Response: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          List<RideRequestModel> parcelRequests = [];
          if (data['data'] != null) {
            for (var item in data['data']) {
              parcelRequests.add(RideRequestModel.fromJson(item));
            }
          }
          _parcelRequestList = parcelRequests;
          debugPrint("✅ Loaded ${_parcelRequestList.length} parcel requests");
        } else {
          _parcelRequestList = [];
          debugPrint("❌ Parcel Request API Error: ${data['message']}");
        }
      } else {
        _parcelRequestList = [];
        debugPrint("❌ Parcel Request HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching parcel requests: $e");
      _parcelRequestList = [];
    }

    _isLoadingParcels = false;
    notifyListeners();
  }



  Future<void> fetchDriverDetail(int driverId) async {
    _isLoadingTrips = true;
    notifyListeners();

    try {
      final url = Uri.parse(
          '${appConstructor.BaseURL}${appConstructor.fetchdriverdetail}?user_id=$driverId');
      final response = await http.get(url);

      debugPrint("Driver Detail API URL: $url");
      debugPrint("Driver Detail Response: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          final driverList = data['data'];
          if (driverList is List && driverList.isNotEmpty) {
            _driverData = driverList[0]; // ✅ take first element
          } else {
            _driverData = null;
          }
        } else {
          _driverData = null;
          debugPrint("Driver Detail API Error: ${data['message']}");
        }
      } else {
        _driverData = null;
        debugPrint("Driver Detail HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching driver: $e");
      _driverData = null;
    }

    _isLoadingTrips = false;
    notifyListeners();
  }


  // Method to refresh both lists
  Future<void> refreshAllData(
      String pickup,
      String destination,
      String date,
      int seats,
      ) async {
    await Future.wait([
      fetchTripList(pickup, destination, date, seats),
      fetchRiderequestlist(pickup, destination, date, seats),
    ]);
  }

  // Method to clear all data
  void clearAllData() {
    _tripList.clear();
    _rideRequestList.clear();
    _driverData = null;
    notifyListeners();
  }
}