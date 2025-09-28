// import 'dart:async';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// class NotificationHandler {
//   static final NotificationHandler _instance = NotificationHandler._internal();
//   factory NotificationHandler() => _instance;
//
//   NotificationHandler._internal();
//
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//   FlutterLocalNotificationsPlugin();
//
//   Future<void> init(BuildContext context) async {
//     // Request permissions (iOS)
//
//      await _firebaseMessaging.requestPermission();
//     // await _firebaseMessaging.requestPermission(
//     //   alert: true,
//     //   badge: true,
//     //   sound: true,
//     // );
//
//
//     // Initialize local notifications
//     const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const iOSInit = DarwinInitializationSettings();
//     const initSettings =
//     InitializationSettings(android: androidInit, iOS: iOSInit);
//     await _flutterLocalNotificationsPlugin.initialize(initSettings,
//         onDidReceiveNotificationResponse: (details) {
//           // When user taps on notification
//           _handleNotificationClick(context, details.payload);
//         });
//
//     // Get the FCM token (for backend registration)
//     String? token = await _firebaseMessaging.getToken();
//     debugPrint("🔑 FCM Token: $token");
//
//     // Foreground messages
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       debugPrint("📩 Foreground message: ${message.notification?.title}");
//       _showLocalNotification(message);
//     });
//
//     // Background messages (tapped notification when app is in background)
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       debugPrint("📲 App opened from background notification");
//       _handleNotificationClick(context, message.data['route']);
//     });
//
//     // When app is launched by tapping a notification (cold start)
//     RemoteMessage? initialMessage =
//     await FirebaseMessaging.instance.getInitialMessage();
//     if (initialMessage != null) {
//       _handleNotificationClick(context, initialMessage.data['route']);
//     }
//   }
//
//   Future<void> _showLocalNotification(RemoteMessage message) async {
//     final notification = message.notification;
//     if (notification == null) return;
//
//     const androidDetails = AndroidNotificationDetails(
//       'default_channel',
//       'General Notifications',
//       channelDescription: 'This channel is used for app notifications',
//       importance: Importance.high,
//       priority: Priority.high,
//       playSound: true,
//     );
//     const iOSDetails = DarwinNotificationDetails();
//
//     const platformDetails =
//     NotificationDetails(android: androidDetails, iOS: iOSDetails);
//
//     await _flutterLocalNotificationsPlugin.show(
//       notification.hashCode,
//       notification.title,
//       notification.body,
//       platformDetails,
//       payload: message.data['route'], // You can send a custom route from backend
//     );
//   }
//
//   void _handleNotificationClick(BuildContext context, String? route) {
//     if (route != null && route.isNotEmpty) {
//       // Example navigation: You can map routes to screens
//       Navigator.pushNamed(context, route);
//     }
//   }
// }
//
// // Background message handler must be a top-level function
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   debugPrint("📥 Background message received: ${message.messageId}");
// }


import 'dart:async';
import 'package:bla_bla_car/services/api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../service/local_cache.dart'; // 👈 Import your LocalCache

class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._internal();
  factory NotificationHandler() => _instance;

  NotificationHandler._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init(BuildContext context) async {
    // 🔑 Request permissions (iOS)
    await _firebaseMessaging.requestPermission();

    // 📢 Initialize local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSInit = DarwinInitializationSettings();
    const initSettings =
    InitializationSettings(android: androidInit, iOS: iOSInit);

    await _flutterLocalNotificationsPlugin.initialize(initSettings,
        onDidReceiveNotificationResponse: (details) {
          _handleNotificationClick(context, details.payload);
        });

    // ✅ Get and save FCM token
    await _fetchAndSaveFcmToken();

    // 🔄 Listen for token refresh events (when FCM rotates token)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint("♻️ FCM Token refreshed: $newToken");
      await LocalCache.saveFcmToken(newToken);
      // await _sendTokenToBackend(newToken);
    });

    // 📩 Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("📩 Foreground message: ${message.notification?.title}");
      _showLocalNotification(message);
    });

    // 📲 When notification is tapped (app in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("📲 App opened from background notification");
      _handleNotificationClick(context, message.data['route']);
    });

    // 🚀 App launched by tapping a notification (cold start)
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(context, initialMessage.data['route']);
    }
  }

  /// Fetch FCM token, save locally, and send to backend
  Future<void> _fetchAndSaveFcmToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      debugPrint("🔑 FCM Token: $token");
      await LocalCache.saveFcmToken(token);
      // await _sendTokenToBackend(token);
    }
  }



  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'General Notifications',
      channelDescription: 'This channel is used for app notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const iOSDetails = DarwinNotificationDetails();

    const platformDetails =
    NotificationDetails(android: androidDetails, iOS: iOSDetails);

    await _flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
      payload: message.data['route'],
    );
  }

  void _handleNotificationClick(BuildContext context, String? route) {
    if (route != null && route.isNotEmpty) {
      Navigator.pushNamed(context, route);
    }
  }
}

// Background message handler must be a top-level function
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("📥 Background message received: ${message.messageId}");
}
