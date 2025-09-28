//
// // ============== TRIP/RIDE MODELS ==============
// class RideList {
//   bool? status;
//   String? message;
//   List<RideDataModel>? data;
//
//   RideList({this.status, this.message, this.data});
//
//   RideList.fromJson(Map<String, dynamic> json) {
//     status = json['status'];
//     message = json['message'];
//     if (json['data'] != null) {
//       data = <RideDataModel>[];
//       json['data'].forEach((v) {
//         data!.add(RideDataModel.fromJson(v));
//       });
//     }
//   }
// }
//
// class RideDataModel {
//   int? rideId;
//   String? pickupLocation;
//   String? destination;
//   int? numberOfSeats;
//   double? price;
//   String? rideDate;
//   String? rideTime;
//   List<ServiceModel>? services; // ✅ updated
//   bool? acceptParcel;
//   int? vehicleId;
//   String? brand;
//   String? model;
//   String? vehicleImage;
//   String? numberPlate;
//   int? driverId;
//   String? driverName;
//   String? driverImage;
//   String? driverStatus;
//   String? driverRating;
//   List<String>? governmentId; // ✅ changed from String? to List<String>?
//
//
//   RideDataModel({
//     this.rideId,
//     this.pickupLocation,
//     this.destination,
//     this.numberOfSeats,
//     this.price,
//     this.rideDate,
//     this.rideTime,
//     this.services,
//     this.acceptParcel,
//     this.vehicleId,
//     this.brand,
//     this.model,
//     this.vehicleImage,
//     this.numberPlate,
//     this.driverId,
//     this.driverName,
//     this.driverImage,
//     this.driverStatus,
//     this.driverRating,
//   });
//
//   RideDataModel.fromJson(Map<String, dynamic> json) {
//     rideId = json['ride_id'];
//     pickupLocation = json['pickup_location'];
//     destination = json['destination'];
//     numberOfSeats = json['number_of_seats'];
//     price = (json['price'] != null)
//         ? double.tryParse(json['price'].toString())
//         : null;
//     rideDate = json['ride_date'];
//     rideTime = json['ride_time'];
//
//     // ✅ updated to handle list of service objects
//     if (json['services'] != null && json['services'] is List) {
//       services = <ServiceModel>[];
//       json['services'].forEach((v) {
//         services!.add(ServiceModel.fromJson(v));
//       });
//     }
//     if (json['government_id'] != null) {
//       if (json['government_id'] is List) {
//         governmentId = List<String>.from(json['government_id']);
//       } else if (json['government_id'] is String) {
//         // fallback in case API returns a single string
//         governmentId = [json['government_id']];
//       }
//     }
//
//     acceptParcel = json['accept_parcel'];
//     vehicleId = json['vehicle_id'];
//     brand = json['brand'];
//     model = json['model'];
//     vehicleImage = json['vehicle_image'];
//     numberPlate = json['number_plate'];
//     driverId = json['driver_id'];
//     driverName = json['driver_name'];
//     driverImage = json['driver_image'];
//     driverStatus = json['driver_status'];
//     driverRating = json['driver_rating']?.toString();
//   }
// }
//
// // ✅ New model for services
// class ServiceModel {
//   int? id;
//   String? serviceName;
//   String? serviceImage;
//
//   ServiceModel({this.id, this.serviceName, this.serviceImage});
//
//   ServiceModel.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     serviceName = json['service_name'];
//     serviceImage = json['service_image'];
//   }
// }
//
// // ============== RIDE REQUEST MODELS ==============
// class RideRequestList {
//   bool? status;
//   String? message;
//   List<RideRequestModel>? data;
//
//   RideRequestList({this.status, this.message, this.data});
//
//   RideRequestList.fromJson(Map<String, dynamic> json) {
//     status = json['status'];
//     message = json['message'];
//     if (json['data'] != null) {
//       data = <RideRequestModel>[];
//       json['data'].forEach((v) {
//         data!.add(RideRequestModel.fromJson(v));
//       });
//     }
//   }
// }
//
// class RideRequestModel {
//   int? id;
//   int? userId;
//   int? type;
//   String? pickupLocation;
//   String? destination;
//   int? numberOfSeats;
//   String? pickupContactName;
//   String? pickupContactNo;
//   String? dropContactName;
//   String? dropContactNo;
//   String? parcelDetails;
//   String? parcelImages;
//   String? rideDate;
//   String? rideTime;
//   List<String>? services; // ✅ still array of strings for requests
//   int? driverId;
//   String? status;
//   String? createdAt;
//   String? updatedAt;
//   String? image;
//   String? name;
//   String? phoneNumber;
//   int? isPhoneVerify;
//   String? email;
//   String? role;
//   String? dob;
//   String? gender;
//   String? governmentId;
//   int? idVerified;
//   String? appleToken;
//   String? facebookToken;
//   String? googleToken;
//   int? isSocial;
//   String? deviceType;
//   String? deviceId;
//   String? deviceToken;
//   String? apiToken;
//   String? vehicleNumber;
//   String? vehicleType;
//
//   RideRequestModel({
//     this.id,
//     this.userId,
//     this.type,
//     this.pickupLocation,
//     this.destination,
//     this.numberOfSeats,
//     this.pickupContactName,
//     this.pickupContactNo,
//     this.dropContactName,
//     this.dropContactNo,
//     this.parcelDetails,
//     this.parcelImages,
//     this.rideDate,
//     this.rideTime,
//     this.services,
//     this.driverId,
//     this.status,
//     this.createdAt,
//     this.updatedAt,
//     this.image,
//     this.name,
//     this.phoneNumber,
//     this.isPhoneVerify,
//     this.email,
//     this.role,
//     this.dob,
//     this.gender,
//     this.governmentId,
//     this.idVerified,
//     this.appleToken,
//     this.facebookToken,
//     this.googleToken,
//     this.isSocial,
//     this.deviceType,
//     this.deviceId,
//     this.deviceToken,
//     this.apiToken,
//     this.vehicleNumber,
//     this.vehicleType,
//   });
//
//   RideRequestModel.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     userId = json['user_id'];
//     type = json['type'];
//     pickupLocation = json['pickup_location'];
//     destination = json['destination'];
//     numberOfSeats = json['number_of_seats'];
//     pickupContactName = json['pickup_contact_name'];
//     pickupContactNo = json['pickup_contact_no'];
//     dropContactName = json['drop_contact_name'];
//     dropContactNo = json['drop_contact_no'];
//     parcelDetails = json['parcel_details'];
//     parcelImages = json['parcel_images'];
//     rideDate = json['ride_date'];
//     rideTime = json['ride_time'];
//
//     if (json['services'] != null) {
//       if (json['services'] is List) {
//         services = List<String>.from(json['services']);
//       } else if (json['services'] is String) {
//         services = [json['services']];
//       }
//     }
//
//     driverId = json['driver_id'];
//     status = json['status'];
//     createdAt = json['created_at'];
//     updatedAt = json['updated_at'];
//     image = json['image'];
//     name = json['name'];
//     phoneNumber = json['phone_number'];
//     isPhoneVerify = json['is_phone_verify'];
//     email = json['email'];
//     role = json['role'];
//     dob = json['dob'];
//     gender = json['gender'];
//     governmentId = json['government_id'];
//     idVerified = json['id_verified'];
//     appleToken = json['apple_token'];
//     facebookToken = json['facebook_token'];
//     googleToken = json['google_token'];
//     isSocial = json['is_social'];
//     deviceType = json['device_type'];
//     deviceId = json['device_id'];
//     deviceToken = json['device_token'];
//     apiToken = json['api_token'];
//     vehicleNumber = json['vehicle_number'];
//     vehicleType = json['vehicle_type'];
//   }
//
//   // Helpers
//   String? get fullImageUrl {
//     if (image != null && image!.isNotEmpty) {
//       return "$image";
//     }
//     return null;
//   }
//
//   String get displayName {
//     return name ?? "Passenger";
//   }
//
//   bool get isPending {
//     return status?.toLowerCase() == 'pending';
//   }
//
//   String get formattedServices {
//     if (services == null || services!.isEmpty) return "No services";
//     return services!.join(", ");
//   }
// }


// ============== TRIP/RIDE MODELS ==============
class RideList {
  bool? status;
  String? message;
  List<RideDataModel>? data;

  RideList({this.status, this.message, this.data});

  RideList.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <RideDataModel>[];
      json['data'].forEach((v) {
        data!.add(RideDataModel.fromJson(v));
      });
    }
  }
}

class RideDataModel {
  int? rideId;
  String? pickupLocation;
  String? destination;
  int? numberOfSeats;
  double? price;
  String? rideDate;
  String? rideTime;
  List<ServiceModel>? services;
  bool? acceptParcel;
  int? vehicleId;
  String? brand;
  String? model;
  String? vehicleImage;
  String? numberPlate;
  int? driverId;
  String? driverName;
  String? driverImage;
  String? driverStatus;
  String? driverRating;
  List<String>? governmentId; // ✅ updated to List<String>

  RideDataModel({
    this.rideId,
    this.pickupLocation,
    this.destination,
    this.numberOfSeats,
    this.price,
    this.rideDate,
    this.rideTime,
    this.services,
    this.acceptParcel,
    this.vehicleId,
    this.brand,
    this.model,
    this.vehicleImage,
    this.numberPlate,
    this.driverId,
    this.driverName,
    this.driverImage,
    this.driverStatus,
    this.driverRating,
    this.governmentId,
  });

  RideDataModel.fromJson(Map<String, dynamic> json) {
    rideId = json['ride_id'];
    pickupLocation = json['pickup_location'];
    destination = json['destination'];
    numberOfSeats = json['number_of_seats'];
    price = (json['price'] != null)
        ? double.tryParse(json['price'].toString())
        : null;
    rideDate = json['ride_date'];
    rideTime = json['ride_time'];

    // Parse services
    if (json['services'] != null && json['services'] is List) {
      services = <ServiceModel>[];
      json['services'].forEach((v) {
        services!.add(ServiceModel.fromJson(v));
      });
    }

    // Parse governmentId
    if (json['government_id'] != null) {
      governmentId = [];
      if (json['government_id'] is List) {
        json['government_id'].forEach((e) {
          if (e is String) {
            governmentId!.add(e);
          } else if (e is Map && e['id'] != null) {
            governmentId!.add(e['id'].toString());
          }
        });
      } else if (json['government_id'] is String) {
        governmentId!.add(json['government_id']);
      }
    }

    acceptParcel = json['accept_parcel'];
    vehicleId = json['vehicle_id'];
    brand = json['brand'];
    model = json['model'];
    vehicleImage = json['vehicle_image'];
    numberPlate = json['number_plate'];
    driverId = json['driver_id'];
    driverName = json['driver_name'];
    driverImage = json['driver_image'];
    driverStatus = json['driver_status'];
    driverRating = json['driver_rating']?.toString();
  }
}

// ✅ New model for services
class ServiceModel {
  int? id;
  String? serviceName;
  String? serviceImage;

  ServiceModel({this.id, this.serviceName, this.serviceImage});

  ServiceModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    serviceName = json['service_name'];
    serviceImage = json['service_image'];
  }
}

// ============== RIDE REQUEST MODELS ==============
class RideRequestList {
  bool? status;
  String? message;
  List<RideRequestModel>? data;

  RideRequestList({this.status, this.message, this.data});

  RideRequestList.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <RideRequestModel>[];
      json['data'].forEach((v) {
        data!.add(RideRequestModel.fromJson(v));
      });
    }
  }
}

class RideRequestModel {
  int? id;
  int? userId;
  int? type;
  String? pickupLocation;
  String? destination;
  int? numberOfSeats;
  String? pickupContactName;
  String? pickupContactNo;
  String? dropContactName;
  String? dropContactNo;
  String? parcelDetails;
  String? parcelImages;
  String? rideDate;
  String? rideTime;
  List<String>? services;
  int? driverId;
  String? status;
  String? createdAt;
  String? updatedAt;
  String? image;
  String? name;
  String? phoneNumber;
  int? isPhoneVerify;
  String? email;
  String? role;
  String? dob;
  String? gender;
  List<String>? governmentId; // ✅ updated
  int? idVerified;
  String? appleToken;
  String? facebookToken;
  String? googleToken;
  int? isSocial;
  String? deviceType;
  String? deviceId;
  String? deviceToken;
  String? apiToken;
  String? vehicleNumber;
  String? vehicleType;

  RideRequestModel({
    this.id,
    this.userId,
    this.type,
    this.pickupLocation,
    this.destination,
    this.numberOfSeats,
    this.pickupContactName,
    this.pickupContactNo,
    this.dropContactName,
    this.dropContactNo,
    this.parcelDetails,
    this.parcelImages,
    this.rideDate,
    this.rideTime,
    this.services,
    this.driverId,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.image,
    this.name,
    this.phoneNumber,
    this.isPhoneVerify,
    this.email,
    this.role,
    this.dob,
    this.gender,
    this.governmentId,
    this.idVerified,
    this.appleToken,
    this.facebookToken,
    this.googleToken,
    this.isSocial,
    this.deviceType,
    this.deviceId,
    this.deviceToken,
    this.apiToken,
    this.vehicleNumber,
    this.vehicleType,
  });

  RideRequestModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    type = json['type'];
    pickupLocation = json['pickup_location'];
    destination = json['destination'];
    numberOfSeats = json['number_of_seats'];
    pickupContactName = json['pickup_contact_name'];
    pickupContactNo = json['pickup_contact_no'];
    dropContactName = json['drop_contact_name'];
    dropContactNo = json['drop_contact_no'];
    parcelDetails = json['parcel_details'];
    parcelImages = json['parcel_images'];
    rideDate = json['ride_date'];
    rideTime = json['ride_time'];

    // parse services safely
    if (json['services'] != null) {
      services = [];
      if (json['services'] is List) {
        json['services'].forEach((e) {
          if (e is String) services!.add(e);
        });
      } else if (json['services'] is String) {
        services!.add(json['services']);
      }
    }

    driverId = json['driver_id'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    image = json['image'];
    name = json['name'];
    phoneNumber = json['phone_number'];
    isPhoneVerify = json['is_phone_verify'];
    email = json['email'];
    role = json['role'];
    dob = json['dob'];
    gender = json['gender'];

    // parse governmentId safely
    if (json['government_id'] != null) {
      governmentId = [];
      if (json['government_id'] is List) {
        json['government_id'].forEach((e) {
          if (e is String) {
            governmentId!.add(e);
          } else if (e is Map && e['id'] != null) {
            governmentId!.add(e['id'].toString());
          }
        });
      } else if (json['government_id'] is String) {
        governmentId!.add(json['government_id']);
      }
    }

    idVerified = json['id_verified'];
    appleToken = json['apple_token'];
    facebookToken = json['facebook_token'];
    googleToken = json['google_token'];
    isSocial = json['is_social'];
    deviceType = json['device_type'];
    deviceId = json['device_id'];
    deviceToken = json['device_token'];
    apiToken = json['api_token'];
    vehicleNumber = json['vehicle_number'];
    vehicleType = json['vehicle_type'];
  }

  // Helpers
  String? get fullImageUrl => (image != null && image!.isNotEmpty) ? image : null;

  String get displayName => name ?? "Passenger";

  bool get isPending => status?.toLowerCase() == 'pending';

  String get formattedServices => (services == null || services!.isEmpty)
      ? "No services"
      : services!.join(", ");
}
