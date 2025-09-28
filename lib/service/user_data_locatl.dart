// import 'package:shared_preferences/shared_preferences.dart';
//
// // Expanded User Model
// import 'package:shared_preferences/shared_preferences.dart';
//
// class ProfileUser {
//   final String mobileNumber;
//   final String fullName;
//   final String profilePicturePath;
//   final String miniBio;
//   final String travelPreferences;
//   final String vehicle;
//   final bool isGovtIdVerified;
//   final bool isEmailConfirmed;
//
//   const ProfileUser({
//     this.mobileNumber = '+91 6261547921', // Demo data
//     this.fullName = 'Raghav Sharma',
//     this.profilePicturePath = 'assets/images/user_avatar.png',
//     this.miniBio = '',
//     this.travelPreferences = '',
//     this.vehicle = '',
//     this.isGovtIdVerified = false,
//     this.isEmailConfirmed = false,
//   });
//
//   // ✅ COPYWITH
//   ProfileUser copyWith({
//     String? mobileNumber,
//     String? fullName,
//     String? profilePicturePath,
//     String? miniBio,
//     String? travelPreferences,
//     String? vehicle,
//     bool? isGovtIdVerified,
//     bool? isEmailConfirmed,
//   }) {
//     return ProfileUser(
//       mobileNumber: mobileNumber ?? this.mobileNumber,
//       fullName: fullName ?? this.fullName,
//       profilePicturePath: profilePicturePath ?? this.profilePicturePath,
//       miniBio: miniBio ?? this.miniBio,
//       travelPreferences: travelPreferences ?? this.travelPreferences,
//       vehicle: vehicle ?? this.vehicle,
//       isGovtIdVerified: isGovtIdVerified ?? this.isGovtIdVerified,
//       isEmailConfirmed: isEmailConfirmed ?? this.isEmailConfirmed,
//     );
//   }
//
//   // ✅ TO JSON
//   Map<String, dynamic> toJson() => {
//     'mobileNumber': mobileNumber,
//     'fullName': fullName,
//     'profilePicturePath': profilePicturePath,
//     'miniBio': miniBio,
//     'travelPreferences': travelPreferences,
//     'vehicle': vehicle,
//     'isGovtIdVerified': isGovtIdVerified,
//     'isEmailConfirmed': isEmailConfirmed,
//   };
//
//   // ✅ FROM JSON
//   factory ProfileUser.fromJson(Map<String, dynamic> json) => ProfileUser(
//     mobileNumber: json['mobileNumber'] ?? '+91 6261547921',
//     fullName: json['fullName'] ?? 'Raghav Sharma',
//     profilePicturePath: json['profilePicturePath'] ?? 'assets/images/user_avatar.png',
//     miniBio: json['miniBio'] ?? '',
//     travelPreferences: json['travelPreferences'] ?? '',
//     vehicle: json['vehicle'] ?? '',
//     isGovtIdVerified: json['isGovtIdVerified'] ?? false,
//     isEmailConfirmed: json['isEmailConfirmed'] ?? false,
//   );
// }
//
// // Local Storage Class using SharedPreferences
// class UserLocalStorage {
//   static const String _keyMobileNumber = 'userMobileNumber';
//   static const String _keyFullName = 'userFullName';
//   static const String _keyProfilePicturePath = 'userProfilePicturePath';
//   static const String _keyMiniBio = 'userMiniBio';
//   static const String _keyTravelPreferences = 'userTravelPreferences';
//   static const String _keyVehicle = 'userVehicle';
//   static const String _keyIsGovtIdVerified = 'userIsGovtIdVerified';
//   static const String _keyIsEmailConfirmed = 'userIsEmailConfirmed';
//
//   static Future<SharedPreferences> _getPrefs() async {
//     return await SharedPreferences.getInstance();
//   }
//
//   static Future<void> saveUser(ProfileUser user) async {
//     final prefs = await _getPrefs();
//     await prefs.setString(_keyMobileNumber, user.mobileNumber);
//     await prefs.setString(_keyFullName, user.fullName);
//     await prefs.setString(_keyProfilePicturePath, user.profilePicturePath);
//     await prefs.setString(_keyMiniBio, user.miniBio);
//     await prefs.setString(_keyTravelPreferences, user.travelPreferences);
//     await prefs.setString(_keyVehicle, user.vehicle);
//     await prefs.setBool(_keyIsGovtIdVerified, user.isGovtIdVerified);
//     await prefs.setBool(_keyIsEmailConfirmed, user.isEmailConfirmed);
//   }
//
//   static Future<ProfileUser> getUser() async {
//     final prefs = await _getPrefs();
//     return ProfileUser(
//       mobileNumber: prefs.getString(_keyMobileNumber) ?? '+91 6261547921',
//       fullName: prefs.getString(_keyFullName) ?? 'demo user',
//       profilePicturePath: prefs.getString(_keyProfilePicturePath) ?? 'assets/images/demo_user.png',
//       miniBio: prefs.getString(_keyMiniBio) ?? '',
//       travelPreferences: prefs.getString(_keyTravelPreferences) ?? '',
//       vehicle: prefs.getString(_keyVehicle) ?? '',
//       isGovtIdVerified: prefs.getBool(_keyIsGovtIdVerified) ?? false,
//       isEmailConfirmed: prefs.getBool(_keyIsEmailConfirmed) ?? false,
//     );
//   }
//   // Save only mobile number (used at login time)
//   static Future<void> saveUserMobile(String mobileNumber) async {
//     final prefs = await _getPrefs();
//     await prefs.setString(_keyMobileNumber, mobileNumber);
//   }
//
//
//   static Future<void> clearUser() async {
//     final prefs = await _getPrefs();
//     await prefs.clear();
//   }
// }