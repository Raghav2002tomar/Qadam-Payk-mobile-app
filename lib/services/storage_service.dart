import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/cart_item.dart';

class StorageService {
  static late Box _box;
  static const String _cartKey = 'cart_items';

  static Future<void> init() async {
    _box = await Hive.openBox('ecommerce_storage');
  }

  static Future<void> saveCartItems(List<CartItem> items) async {
    final jsonList = items.map((item) => item.toJson()).toList();
    await _box.put(_cartKey, jsonEncode(jsonList));
  }

  static List<CartItem> getCartItems() {
    try {
      final jsonString = _box.get(_cartKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => CartItem.fromJson(json)).toList();
    } catch (e) {
      print('Error loading cart items: $e');
      return [];
    }
  }

  static Future<void> clearCart() async {
    await _box.delete(_cartKey);
  }
}
