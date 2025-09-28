import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../api_service/api_serviece.dart';
import '../../../api_service/app_constocter.dart';
import '../../../models/UserProfileModel.dart';
import '../../../service/local_cache.dart';
import '../../../service/user_data_locatl.dart';
import '../../mainView/HomeShell.dart';

class LoginProvider extends ChangeNotifier {
  final Api_Service apiService = Api_Service();
  final App_Constructor appConstructor = App_Constructor();

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? latestOtp;

  UserProfile? _profile;
  UserProfile? get profile => _profile;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool> sendOtp(BuildContext context, String phoneNumber) async {
    if (phoneNumber.isEmpty || phoneNumber.length < 9) {
      Fluttertoast.showToast(
        msg: "Please enter a valid phone number",
        backgroundColor: Colors.red,
      );
      return false;
    }

    setLoading(true);

    try {
      final response = await apiService.postFormRequest(
        endpoint: appConstructor.login,
        formData: {
          "phone_number": phoneNumber,
          "device_type": "android",
          "device_id": "12345",
          "device_token": "abcd1234",
          "otp": "123456",
        },
      );

      if (response["status"] == true) {
        final otp = response["data"]["otp"];
        latestOtp = otp.toString(); // convert to string
        Fluttertoast.showToast(
          msg: "OTP Sent: ${otp.toString()}", // ✅ Convert to string
          backgroundColor: Colors.green,
        );
        return true;
      }
      else {
        Fluttertoast.showToast(
          msg: response["message"] ?? "Failed to send OTP",
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: $e",
        backgroundColor: Colors.red,
      );
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> verifyOtp(BuildContext context, String phoneNumber, String otp) async {
    if (otp.isEmpty || otp.length < 4) {
      Fluttertoast.showToast(
        msg: "Enter a valid OTP",
        backgroundColor: Colors.red,
      );
      return false;
    }

    setLoading(true);
    final fcmToken = await LocalCache.getFcmToken();

    try {
      final response = await apiService.postFormRequest(
        endpoint: appConstructor.verify_otp,
        formData: {
          "phone_number": phoneNumber,
          "otp": otp,
          "fcm_token": fcmToken.toString()
        },
      );

      if (response["status"] == true) {
        final data = response["data"];
        final apiToken = data["api_token"];

        /// ✅ Save login state and token in LocalCache
        await LocalCache.setUserLoggedIn(true);
        await LocalCache.saveToken(apiToken);

        Fluttertoast.showToast(
          msg: response["message"] ?? "Login Successful",
          backgroundColor: Colors.green,
        );
        return true;
      } else {
        Fluttertoast.showToast(
          msg: response["message"] ?? "Invalid OTP",
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: $e",
        backgroundColor: Colors.red,
      );
      return false;
    } finally {
      setLoading(false);
    }
  }


  Future<bool> logout(BuildContext context) async {
    setLoading(true);
    try {
      final response = await apiService.logoutRequest(
        endpoint: appConstructor.logout, // Make sure logout endpoint is correct
      );

      if (response["status"] == true) {
        Fluttertoast.showToast(
          msg: response["message"] ?? "Logged out successfully",
          backgroundColor: Colors.green,
        );

        await LocalCache.logout();
        // await UserLocalStorage.clearUser();

        // ✅ Navigate back to home
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeShell()),
              (route) => false,
        );

        return true;
      } else {
        Fluttertoast.showToast(
          msg: response["message"] ?? "Failed to logout",
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: $e",
        backgroundColor: Colors.red,
      );
      return false;
    } finally {
      setLoading(false);
    }
  }


  Future<bool> fetchProfile() async {
    setLoading(true);
    try {
      final response = await apiService.getAuthRequest(
        endpoint: appConstructor.get_profile, // Replace with your profile endpoint
      );

      if (response['status'] == true) {
        _profile = UserProfile.fromJson(response['data']);
        notifyListeners();
        return true;
      } else {
        Fluttertoast.showToast(
          msg: response['message'] ?? "Failed to fetch profile",
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: $e",
        backgroundColor: Colors.red,
      );
      return false;
    } finally {
      setLoading(false);
    }
  }


  /// Helper method to get stored token later
  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("api_token");
  }

}
