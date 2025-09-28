class FetchServicesResponse {
  bool? status;
  String? message;
  List<ServiceModel>? data;

  FetchServicesResponse({this.status, this.message, this.data});

  factory FetchServicesResponse.fromJson(Map<String, dynamic> json) {
    return FetchServicesResponse(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null
          ? (json['data'] as List)
          .map((e) => ServiceModel.fromJson(e))
          .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "status": status,
      "message": message,
      "data": data?.map((e) => e.toJson()).toList(),
    };
  }
}


class ServiceModel {
  final int? id;
  final String? serviceName;
  final String? serviceImage;
  bool isSelected; // <-- add this

  ServiceModel({
    this.id,
    this.serviceName,
    this.serviceImage,
    this.isSelected = false, // <-- default false
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      serviceName: json['service_name'],
      serviceImage: json['service_image'],
      isSelected: false, // always false when first fetched
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_name': serviceName,
      'service_image': serviceImage,
      'isSelected': isSelected,
    };
  }
}
