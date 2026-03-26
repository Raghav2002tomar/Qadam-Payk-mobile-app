import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCache {
  static const String _onboardingKey = "onboarding_seen";
  static const String _loginKey = "user_logged_in";
  static const String _tokenKey = "api_token";
  static const String _fcmTokenKey = "fcm_token";
  static const String _drivermodeKey = "is_driver_mode";
  static const String _driverModeKey = "driver_mode";

  static Future<void> setDriverMode(bool value) async {
    final box = await Hive.openBox('appBox');
    await box.put(_driverModeKey, value);
  }

  static Future<bool> getDriverMode() async {
    final box = await Hive.openBox('appBox');
    return box.get(_driverModeKey, defaultValue: false);
  }

  static Future<void> clearDriverMode() async {
    final box = await Hive.openBox('appBox');
    await box.delete(_driverModeKey);
  }
  static Future<void> saveDriverMode(bool isDriver) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_driver_mode', isDriver);
  }
  //
  // static Future<bool> getDriverMode() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   return prefs.getBool('is_driver_mode') ?? false;
  // }

  /// Save onboarding as completed
  static Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  /// Check if onboarding is already seen
  static Future<bool> isOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  /// Save user login status
  static Future<void> setUserLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loginKey, value);
  }

  /// Check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loginKey) ?? false;
  }

  /// Save API token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Get stored API token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Save FCM token
  static Future<void> saveFcmToken(String fcmToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, fcmToken);
  }

  /// Get FCM token
  static Future<String?> getFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenKey);
  }

  /// Clear token & login state
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginKey);
    await prefs.remove(_tokenKey);
    // Keep FCM token even after logout (optional)
  }
}
