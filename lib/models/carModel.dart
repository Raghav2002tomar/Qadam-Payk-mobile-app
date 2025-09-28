
// car brand data model

class CarBrand {
  bool? status;
  String? message;
  List<BrandData>? data;

  CarBrand({this.status, this.message, this.data});

  CarBrand.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <BrandData>[];
      json['data'].forEach((v) {
        data!.add(new BrandData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class CarBrandData {
  String? brand;

  CarBrandData({this.brand});

  CarBrandData.fromJson(Map<String, dynamic> json) {
    brand = json['brand'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['brand'] = this.brand;
    return data;
  }
}
class CarBrandModel {
  bool? status;
  String? message;
  List<BrandData>? data;

  CarBrandModel({this.status, this.message, this.data});

  CarBrandModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <BrandData>[];
      json['data'].forEach((v) {
        data!.add(new BrandData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class BrandData {
  String? brand;

  BrandData({this.brand});

  BrandData.fromJson(Map<String, dynamic> json) {
    brand = json['brand'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['brand'] = this.brand;
    return data;
  }
}



// car model data
class CarModel {
  bool? status;
  String? message;
  String? brand;
  List<String>? data;

  CarModel({this.status, this.message, this.brand, this.data});

  CarModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    brand = json['brand'];
    data = json['data'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    data['brand'] = this.brand;
    data['data'] = this.data;
    return data;
  }
}