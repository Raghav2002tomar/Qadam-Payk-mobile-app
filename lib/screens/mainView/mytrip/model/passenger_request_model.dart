import 'dart:convert';

class PassengerRequest {
  final int id;
  final int userId;
  final int type; // 0 = normal ride, 1 = parcel
  final String pickupLocation;
  final String destination;
  final int numberOfSeats;
  final String? pickupContactName;
  final String? pickupContactNo;
  final String? dropContactName;
  final String? dropContactNo;
  final String? parcelDetails;
  final List<String> parcelImages;
  final String? budget;
  final String? preferredTime;
  final String? rideDate;
  final String? rideTime;
  final List<Service> services;
  final String status; // ✅ normalized to lowercase

  PassengerRequest({
    required this.id,
    required this.userId,
    required this.type,
    required this.pickupLocation,
    required this.destination,
    required this.numberOfSeats,
    this.pickupContactName,
    this.pickupContactNo,
    this.dropContactName,
    this.dropContactNo,
    this.parcelDetails,
    required this.parcelImages,
    this.budget,
    this.preferredTime,
    this.rideDate,
    this.rideTime,
    required this.services,
    required this.status,
  });

  factory PassengerRequest.fromJson(Map<String, dynamic> json) {
    // ✅ Parse parcel images safely
    List<String> parsedImages = [];
    if (json['parcel_images'] != null) {
      try {
        final dynamic imagesData = json['parcel_images'];
        if (imagesData is String) {
          final List<dynamic> decoded = jsonDecode(imagesData);
          parsedImages = decoded.cast<String>();
        } else if (imagesData is List) {
          parsedImages = imagesData.cast<String>();
        }
      } catch (e) {
        parsedImages = [];
      }
    }

    // ✅ Parse services safely
    List<Service> parsedServices = [];
    if (json['services'] != null && json['services'] is List) {
      parsedServices =
          (json['services'] as List).map((s) => Service.fromJson(s)).toList();
    }

    return PassengerRequest(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      type: json['type'] ?? 0,
      pickupLocation: json['pickup_location'] ?? '',
      destination: json['destination'] ?? '',
      numberOfSeats: json['number_of_seats'] ?? 0,
      pickupContactName: json['pickup_contact_name'],
      pickupContactNo: json['pickup_contact_no'],
      dropContactName: json['drop_contact_name'],
      dropContactNo: json['drop_contact_no'],
      parcelDetails: json['parcel_details'],
      parcelImages: parsedImages,
      budget: json['budget']?.toString(),
      preferredTime: json['preferred_time'],
      rideDate: json['ride_date'],
      rideTime: json['ride_time'],
      services: parsedServices,
      status: (json['status'] ?? '').toString().trim().toLowerCase(), // ✅ normalize
    );
  }

  // ✅ Helper methods for UI
  bool get isConfirmed => status == "confirmed";
  bool get isPending => status == "pending";
  bool get isCancelled => status == "cancelled";

  String get displayStatus {
    if (isConfirmed) return "Confirmed";
    if (isPending) return "Pending";
    if (isCancelled) return "Cancelled";
    return status.isNotEmpty ? status : "Unknown";
  }
}

class Service {
  final int id;
  final String serviceName;
  final String serviceImage;

  Service({
    required this.id,
    required this.serviceName,
    required this.serviceImage,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] ?? 0,
      serviceName: json['service_name'] ?? '',
      serviceImage: json['service_image'] ?? '',
    );
  }
}
