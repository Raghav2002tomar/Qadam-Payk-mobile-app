class UserProfile {
  final int id;
  final String? image;
  final String? name;
  final String phoneNumber;
  final bool isPhoneVerified;
  final String? email;
  final bool isEmailVerified;
  final String? vehicleNumber;
  final String? vehicleType;
  final String apiToken;
  final String? dob;
  final String? gender;
  final String? governmentId;
  final bool idVerified;
  final String? appleToken;
  final String? facebookToken;
  final String? googleToken;
  final bool isSocial;
  final String? deviceType;
  final String? deviceId;
  final String? deviceToken;
  final String? otp;
  final String? otpSentAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    this.image,
    this.name,
    required this.phoneNumber,
    required this.isPhoneVerified,
    this.email,
    required this.isEmailVerified,
    this.vehicleNumber,
    this.vehicleType,
    required this.apiToken,
    this.dob,
    this.gender,
    this.governmentId,
    required this.idVerified,
    this.appleToken,
    this.facebookToken,
    this.googleToken,
    required this.isSocial,
    this.deviceType,
    this.deviceId,
    this.deviceToken,
    this.otp,
    this.otpSentAt,
    this.createdAt,
    this.updatedAt,
  });

  // ✅ fromJson factory constructor
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      image: json['image'],
      name: json['name'],
      phoneNumber: json['phone_number'] ?? '',
      isPhoneVerified: json['is_phone_verify'] == 1,
      email: json['email'],
      isEmailVerified: json['email_verified'] == 1,
      vehicleNumber: json['vehicle_number'],
      vehicleType: json['vehicle_type'],
      apiToken: json['api_token'] ?? '',
      dob: json['dob'],
      gender: json['gender'],
      governmentId: json['government_id'],
      idVerified: json['id_verified'] == 1,
      appleToken: json['apple_token'],
      facebookToken: json['facebook_token'],
      googleToken: json['google_token'],
      isSocial: json['is_social'] == 1,
      deviceType: json['device_type'],
      deviceId: json['device_id'],
      deviceToken: json['device_token'],
      otp: json['otp'],
      otpSentAt: json['otp_sent_at'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  // ✅ copyWith method
  UserProfile copyWith({
    int? id,
    String? image,
    String? name,
    String? phoneNumber,
    bool? isPhoneVerified,
    String? email,
    bool? isEmailVerified,
    String? vehicleNumber,
    String? vehicleType,
    String? apiToken,
    String? dob,
    String? gender,
    String? governmentId,
    bool? idVerified,
    String? appleToken,
    String? facebookToken,
    String? googleToken,
    bool? isSocial,
    String? deviceType,
    String? deviceId,
    String? deviceToken,
    String? otp,
    String? otpSentAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      image: image ?? this.image,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      email: email ?? this.email,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      apiToken: apiToken ?? this.apiToken,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      governmentId: governmentId ?? this.governmentId,
      idVerified: idVerified ?? this.idVerified,
      appleToken: appleToken ?? this.appleToken,
      facebookToken: facebookToken ?? this.facebookToken,
      googleToken: googleToken ?? this.googleToken,
      isSocial: isSocial ?? this.isSocial,
      deviceType: deviceType ?? this.deviceType,
      deviceId: deviceId ?? this.deviceId,
      deviceToken: deviceToken ?? this.deviceToken,
      otp: otp ?? this.otp,
      otpSentAt: otpSentAt ?? this.otpSentAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
