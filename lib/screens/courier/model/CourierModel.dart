class CourierModel {
  final int id;
  final int userId;
  final String pickupLocation;
  final String? pickupLatitude;
  final String? pickupLongitude;
  final String dropLocation;
  final String? dropLatitude;
  final String? dropLongitude;
  final String distance;
  final String time;
  final String tripType;
  final String senderName;
  final String senderPhone;
  final String senderLandmark;
  final String receiverName;
  final String receiverPhone;
  final String receiverLandmark;
  final String packageDescription;
  final String packageSize;
  final String instruction;
  final String suggestedPrice;
  final String paymentMethod;
  final String paidBy;
  late final String status;
  final int? acceptedDriverId;
  final String? expiresAt;
  final String createdAt;

  // Sender (user) details
  final String? senderImage;     // raw filename from API
  final String? senderFullName;  // sender.name
  final String? senderPhone2;    // sender.phone_number

  CourierModel({
    required this.id,
    required this.userId,
    required this.pickupLocation,
    this.pickupLatitude,
    this.pickupLongitude,
    required this.dropLocation,
    this.dropLatitude,
    this.dropLongitude,
    required this.distance,
    required this.time,
    required this.tripType,
    required this.senderName,
    required this.senderPhone,
    required this.senderLandmark,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverLandmark,
    required this.packageDescription,
    required this.packageSize,
    required this.instruction,
    required this.suggestedPrice,
    required this.paymentMethod,
    required this.paidBy,
    required this.status,
    this.acceptedDriverId,
    this.expiresAt,
    required this.createdAt,
    this.senderImage,
    this.senderFullName,
    this.senderPhone2,
  });

  factory CourierModel.fromJson(Map<String, dynamic> json) {
    String rawStatus = json["status"] ?? "";

    String uiStatus;
    switch (rawStatus.toLowerCase()) {
      case "pending":
        uiStatus = "Searching";
        break;
      case "accepted":
        uiStatus = "Accepted";
        break;
      case "in_transit":
        uiStatus = "In Transit";
        break;
      case "completed":
        uiStatus = "Delivered";
        break;
      default:
        uiStatus = rawStatus;
    }

    // Parse nested sender object
    final sender = json["sender"] as Map<String, dynamic>?;

    return CourierModel(
      id: json["id"] ?? 0,
      userId: json["user_id"] ?? 0,
      pickupLocation: json["pickup_location"] ?? "",
      pickupLatitude: json["pickup_latitude"]?.toString(),
      pickupLongitude: json["pickup_longitude"]?.toString(),
      dropLocation: json["drop_location"] ?? "",
      dropLatitude: json["drop_latitude"]?.toString(),
      dropLongitude: json["drop_longitude"]?.toString(),
      distance: json["distance"] ?? "",
      time: json["time"] ?? "",
      tripType: json["trip_type"] ?? "",
      senderName: json["sender_name"] ?? "",
      senderPhone: json["sender_phone"] ?? "",
      senderLandmark: json["sender_landmark"] ?? "",
      receiverName: json["receiver_name"] ?? "",
      receiverPhone: json["receiver_phone"] ?? "",
      receiverLandmark: json["receiver_landmark"] ?? "",
      packageDescription: json["package_description"] ?? "",
      packageSize: json["package_size"] ?? "",
      instruction: json["instruction"] ?? "",
      suggestedPrice: json["suggested_price"]?.toString() ?? "0",
      paymentMethod: json["payment_method"] ?? "",
      paidBy: json["paid_by"] ?? "",
      status: uiStatus,
      acceptedDriverId: json["accepted_driver_id"],
      expiresAt: json["expires_at"],
      createdAt: json["created_at"] ?? "",
      // Sender nested object
      senderImage: sender?["image"]?.toString(),
      senderFullName: sender?["name"]?.toString(),
      senderPhone2: sender?["phone_number"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user_id": userId,
      "pickup_location": pickupLocation,
      "pickup_latitude": pickupLatitude,
      "pickup_longitude": pickupLongitude,
      "drop_location": dropLocation,
      "drop_latitude": dropLatitude,
      "drop_longitude": dropLongitude,
      "distance": distance,
      "time": time,
      "trip_type": tripType,
      "sender_name": senderName,
      "sender_phone": senderPhone,
      "sender_landmark": senderLandmark,
      "receiver_name": receiverName,
      "receiver_phone": receiverPhone,
      "receiver_landmark": receiverLandmark,
      "package_description": packageDescription,
      "package_size": packageSize,
      "instruction": instruction,
      "suggested_price": suggestedPrice,
      "payment_method": paymentMethod,
      "paid_by": paidBy,
      "status": _rawStatus(),
      "accepted_driver_id": acceptedDriverId,
      "expires_at": expiresAt,
      "created_at": createdAt,
    };
  }

  String _rawStatus() {
    switch (status) {
      case "Searching":  return "pending";
      case "Accepted":   return "accepted";
      case "In Transit": return "in_transit";
      case "Delivered":  return "completed";
      default:           return status;
    }
  }

  /// Helper: full image URL. Pass your base storage URL, e.g. "https://yourapi.com/storage/"
  String? senderImageUrl(String storageBaseUrl) {
    if (senderImage == null || senderImage!.isEmpty) return null;
    return "$storageBaseUrl$senderImage";
  }

  /// Friendly time ago from createdAt
  String get timeAgo {
    try {
      final created = DateTime.parse(createdAt).toLocal();
      final diff = DateTime.now().difference(created);
      if (diff.inMinutes < 1) return "just now";
      if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
      if (diff.inHours < 24) return "${diff.inHours} hr ago";
      return "${diff.inDays} days ago";
    } catch (_) {
      return "";
    }
  }
}