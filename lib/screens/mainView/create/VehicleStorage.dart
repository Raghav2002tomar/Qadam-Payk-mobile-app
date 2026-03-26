import 'package:hive/hive.dart';


class Vehicle {
  dynamic? id;
  String? brand;
  String? model;
  String? plate;
  String? imagePath;

  Vehicle({this.id, this.brand, this.model, this.plate, this.imagePath});

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] is String
          ? int.parse(json['id'])
          : json['id'],      brand: json['brand'],
      model: json['model'],
      plate: json['number_plate'],
      imagePath: json['vehicle_image'], // depends on API response key
    );
  }
}



// class Vehicle {
//   final String brand;
//   final String model;
//   final String plate;
//   final String? imagePath;
//
//   const Vehicle({
//     required this.brand,
//     required this.model,
//     required this.plate,
//     this.imagePath,
//   });
//
//   Map<String, dynamic> toJson() => {
//     'brand': brand,
//     'model': model,
//     'plate': plate,
//     'imagePath': imagePath,
//   };
//
//   factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
//     brand: json['brand'],
//     model: json['model'],
//     plate: json['plate'],
//     imagePath: json['imagePath'],
//   );
// }

class VehicleStorage {
  static const String _boxName = 'vehicles';
  static const String _keyList = 'list';

  /// 🔹 Ensure box is opened before using
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  /// 🔹 Save or update a vehicle
  static Future<List<Vehicle>> save(Vehicle v) async {
    await init();
    final box = Hive.box(_boxName);

    final rawList = box.get(_keyList, defaultValue: []) as List;
    final list = rawList.map((e) => Map<String, dynamic>.from(e)).toList();

    final index = list.indexWhere((e) => e['plate'] == v.plate);
    // if (index >= 0) {
    //   list[index] = v.toJson();
    // } else {
    //   list.add(v.toJson());
    // }

    await box.put(_keyList, list);
    return getAll();
  }

  /// 🔹 Get all vehicles
  static List<Vehicle> getAll() {
    final box = Hive.box(_boxName);
    final rawList = box.get(_keyList, defaultValue: []) as List;
    return rawList
        .map((e) => Vehicle.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// 🔹 Remove vehicle by plate
  static Future<List<Vehicle>> remove(String plate) async {
    await init();
    final box = Hive.box(_boxName);
    final rawList = box.get(_keyList, defaultValue: []) as List;
    final list = rawList.map((e) => Map<String, dynamic>.from(e)).toList();

    list.removeWhere((e) => e['plate'] == plate);

    await box.put(_keyList, list);
    return getAll();
  }

  /// 🔹 Clear all vehicles
  static Future<void> clear() async {
    await init();
    final box = Hive.box(_boxName);
    await box.put(_keyList, []);
  }
}

