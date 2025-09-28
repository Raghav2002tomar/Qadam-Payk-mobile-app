import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/storage_service.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  void loadCartItems() {
    _items = StorageService.getCartItems();
    notifyListeners();
  }

  void addItem(Product product, int quantity) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }

    _saveToStorage();
    notifyListeners();
  }

  void updateQuantity(int productId, int newQuantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);

    if (index >= 0) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = newQuantity;
      }
      _saveToStorage();
      notifyListeners();
    }
  }

  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _saveToStorage();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    StorageService.clearCart();
    notifyListeners();
  }

  void _saveToStorage() {
    StorageService.saveCartItems(_items);
  }
}
