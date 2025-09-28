import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../service/local_cache.dart';
import 'app_constocter.dart';

class Api_Service {
  final App_Constructor appConstructor = App_Constructor();


  // get request
  Future<dynamic> getRequest({
    required String endpoint,
    Map<String, String>? queryParams,
  }) async {
    try {
      Uri uri = Uri.parse("${appConstructor.BaseURL}$endpoint")
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          "Server Error: ${response.statusCode} - ${response.reasonPhrase}",

        );
      }
    } on SocketException {
      throw Exception("No Internet connection");
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }

  // post requset

  /// POST Request
  /// POST Request (Form Data)
  Future<dynamic> postFormRequest({
    required String endpoint,
    required Map<String, String> formData,
    Map<String, String>? queryParams,
  }) async {
    try {
      Uri uri = Uri.parse("${appConstructor.BaseURL}$endpoint")
          .replace(queryParameters: queryParams);

      final response = await http.post(
        uri,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded',
        },
        body: formData, // Directly send as form data
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          "Server Error: ${response.statusCode} - ${response.reasonPhrase}",
        );
      }
    } on SocketException {
      throw Exception("No Internet connection");
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }


  Future<dynamic> postWithCsrfTokenForm({
    required String endpoint,
    required Map<String, String> body, // all values as String
  }) async {
    try {
      // Step 1: Get CSRF token
      final tokenResponse = await http.get(
        Uri.parse("${appConstructor.BaseURL}api/getcsrftoken"),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      );
      final csrfToken = jsonDecode(tokenResponse.body)["CSRF_MEH_MD"];

      // Step 2: Add CSRF token to form body
      final formBody = {
        "CSRF_MEH_MD": csrfToken,
        ...body,
      };

      print("Form Body BEFORE POST: $formBody");

      // Step 3: POST as x-www-form-urlencoded
      final response = await http.post(
        Uri.parse("${appConstructor.BaseURL}$endpoint"),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded',
        },
        body: formBody,
      );

      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            "Server Error: ${response.statusCode} - ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Error in postWithCsrfTokenForm: $e");
      throw Exception("Unexpected error: $e");
    }
  }


  Future<dynamic> postWithCsrfTokenMultipart({
    required String endpoint,
    required Map<String, String> fields, // text fields
    File? file, // optional image/file
    String fileFieldName = "image", // backend file field key
  }) async {
    try {
      // Step 1: Get CSRF token
      final tokenResponse = await http.get(
        Uri.parse("${appConstructor.BaseURL}api/getcsrftoken"),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      );
      final csrfToken = jsonDecode(tokenResponse.body)["CSRF_MEH_MD"];

      // Step 2: Create Multipart Request
      final uri = Uri.parse("${appConstructor.BaseURL}$endpoint");
      final request = http.MultipartRequest("POST", uri);

      // Add CSRF token + fields
      request.fields["CSRF_MEH_MD"] = csrfToken;
      request.fields.addAll(fields);

      // Add file if exists
      if (file != null) {
        request.files.add(
          await http.MultipartFile.fromPath(fileFieldName, file.path),
        );
      }

      // Step 3: Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("Multipart Response status: ${response.statusCode}");
      print("Multipart Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            "Server Error: ${response.statusCode} - ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Error in postWithCsrfTokenMultipart: $e");
      throw Exception("Unexpected error: $e");
    }
  }


  /// POST Request with Authorization header (token taken from LocalCache)
  Future<dynamic> postAuthFormRequest({
    required String endpoint,
    required Map<String, String> formData,
    Map<String, String>? queryParams,
  }) async {
    try {
      // Get token from LocalCache
      final token = await LocalCache.getToken();

      Uri uri = Uri.parse("${appConstructor.BaseURL}$endpoint")
          .replace(queryParameters: queryParams);

      final response = await http.post(
        uri,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded',
          HttpHeaders.authorizationHeader: "Bearer $token", // Attach token
        },
        body: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception("Unauthorized: Invalid or expired token");
      } else {
        throw Exception(
          "Server Error: ${response.statusCode} - ${response.reasonPhrase}",
        );
      }
    } on SocketException {
      throw Exception("No Internet connection");
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }


  // api_service.dart

  Future<dynamic> logoutRequest({
    required String endpoint,
  }) async {
    try {
      // ✅ Get saved token from LocalCache
      final token = await LocalCache.getToken();

      if (token == null) {
        throw Exception("No auth token found");
      }

      final uri = Uri.parse("${appConstructor.BaseURL}$endpoint");

      final response = await http.post(
        uri,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded',
          HttpHeaders.authorizationHeader: "Bearer $token", // ✅ Send token
        },
        body: {}, // empty form-data
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          "Server Error: ${response.statusCode} - ${response.reasonPhrase}",
        );
      }
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }


  /// Custom GET request with Authorization header
  Future<dynamic> getAuthRequest({
    required String endpoint,
    Map<String, String>? queryParams,
  }) async {
    try {
      // ✅ Get token from LocalCache
      final token = await LocalCache.getToken();

      if (token == null) {
        throw Exception("No auth token found");
      }

      // Build URI with optional query parameters
      Uri uri = Uri.parse("${appConstructor.BaseURL}$endpoint")
          .replace(queryParameters: queryParams);

      // Send GET request with Authorization header
      final response = await http.get(
        uri,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: "Bearer $token",
        },
      );

      // Handle response
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception("Unauthorized: Invalid or expired token");
      } else {
        throw Exception(
            "Server Error: ${response.statusCode} - ${response.reasonPhrase}");
      }
    } on SocketException {
      throw Exception("No Internet connection");
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }



}
