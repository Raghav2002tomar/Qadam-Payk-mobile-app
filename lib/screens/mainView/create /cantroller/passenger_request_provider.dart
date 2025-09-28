import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../api_service/api_serviece.dart';
import '../../../../api_service/app_constocter.dart';
import '../../../../service/local_cache.dart'; // ✅ to get token

class PassengerRequestProvider with ChangeNotifier {
  final Api_Service apiService = Api_Service();
  final App_Constructor appConstructor = App_Constructor();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _responseData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get responseData => _responseData;

  Future<void> createPassengerRequest({
    required String fromCity,
    required String toCity,
    required String price,
    required int seats,
    required String rideDate,
    List<String>? services, // ✅ List of services
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final url = Uri.parse("${appConstructor.BaseURL}${appConstructor.passenger_request}");
    double? priceValue = double.tryParse(price.toString()) ?? 0.0;
    int budgetInt = priceValue.toInt();
    try {
      final token = await LocalCache.getToken(); // ✅ Get token from local cache
      var request = http.MultipartRequest('POST', url);

      // ✅ Add form-data fields
      request.fields['pickup_location'] = fromCity;
      request.fields['destination'] = toCity;
      request.fields['number_of_seats'] = seats.toString();
      request.fields['ride_date'] = rideDate;
      // double? priceValue = double.tryParse(price.toString()) ?? 0.0;
      // int budgetInt = priceValue.toInt();
      // request.fields['budget'] = budgetInt.toString();
      double? priceValue = double.tryParse(price.toString()) ?? 0.0;
      request.fields['budget'] = priceValue.toString(); // ✅ sends float like "123.45"



      // if (services != null && services.isNotEmpty) {
      //   services.forEach((service) {
      //     request.fields.addAll({'services[]': service});
      //   });
      // }
      // if (services != null && services.isNotEmpty) {
      //   for (var service in services) {
      //     request.fields.putIfAbsent('services[]', () => service);
      //   }
      //
      // }
      print("🚀 Sending request with data: ${request.fields}"); // ✅ Debug print



      // ✅ Send token in headers
      request.headers['Authorization'] = "Bearer $token";

      // ✅ Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _responseData = json.decode(response.body);
      } else {
        _errorMessage = "Error: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      _errorMessage = "Exception: $e";
    }

    _isLoading = false;
    notifyListeners();
  }



  Future<void> createParcelRequest({
    required String rideDate,
    required String rideTime,
    required String pickupLocation,
    required String destination,
    required String pickupContactName,
    required String pickupContactNo,
    required String dropContactName,
    required String dropContactNo,
    required String parcelprice,
    required String parcelDetails,
    File? parcelImage,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final url = Uri.parse("${appConstructor.BaseURL}/api/store-parcel-request");

    try {
      final token = await LocalCache.getToken();
      var request = http.MultipartRequest('POST', url);

      // Add text fields
      request.fields['ride_date'] = rideDate;
      request.fields['ride_time'] = rideTime;
      request.fields['pickup_location'] = pickupLocation;
      request.fields['destination'] = destination;
      request.fields['pickup_contact_name'] = pickupContactName;
      request.fields['pickup_contact_no'] = pickupContactNo;
      request.fields['drop_contact_name'] = dropContactName;
      request.fields['drop_contact_no'] = dropContactNo;
      request.fields['parcel_details'] = parcelDetails;
      request.fields['budget'] = parcelprice;

      // Add image if exists
      if (parcelImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'parcel_images[]',
          parcelImage.path,
        ));
      }

      // Add token header
      request.headers['Authorization'] = "Bearer $token";

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _responseData = json.decode(response.body);
      } else {
        _errorMessage = "Error: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      _errorMessage = "Exception: $e";
    }

    _isLoading = false;
    notifyListeners();
  }


}
