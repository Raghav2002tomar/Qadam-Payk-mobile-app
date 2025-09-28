import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../models/product.dart';

class ApiService {
  static const String baseUrl = 'https://fakestoreapi.com';
  static final http.Client _client = http.Client();

  static Future<List<Product>> fetchProducts() async {
    // ✅ First check internet availability
    final hasConnection = await _hasInternet();
    if (!hasConnection) {
      throw Exception('No Internet Connection');
    }

    const maxAttempts = 3;
    Duration delay = const Duration(milliseconds: 500);

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final uri = Uri.parse('$baseUrl/products');
        final resp = await _client
            .get(uri, headers: {
          'Accept': 'application/json',
          'User-Agent': 'ShopEase/1.0 (+flutter)'
        })
            .timeout(const Duration(seconds: 15));

        if (resp.statusCode == 200) {
          final List<dynamic> list = json.decode(resp.body);
          return list.map((j) => Product.fromJson(j)).toList();
        }
        throw Exception('HTTP ${resp.statusCode} ${resp.reasonPhrase}');
      } on TimeoutException {
        if (attempt == maxAttempts) {
          throw Exception('Request timed out (attempt $attempt/$maxAttempts)');
        }
        await Future.delayed(delay);
        delay *= 2;
      } catch (e) {
        if (attempt == maxAttempts) rethrow;
        await Future.delayed(delay);
        delay *= 2;
      }
    }
    throw Exception('Unreachable');
  }

  static Future<bool> _hasInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return false;

    // Use the singleton instance
    return await InternetConnectionChecker.instance.hasConnection;
  }

  static void dispose() {
    _client.close();
  }
}
