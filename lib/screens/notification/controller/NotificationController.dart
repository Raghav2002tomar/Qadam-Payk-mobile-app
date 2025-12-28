import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/AppNotificationModel.dart';

class NotificationService {
  static Future<List<AppNotification>> fetchNotifications(String token) async {
    final uri = Uri.parse(
      'https://qadampayk.com/api/get-user-notifications',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      final List list = decoded['data'];

      return list.map((e) => AppNotification.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load notifications');
    }
  }
}
