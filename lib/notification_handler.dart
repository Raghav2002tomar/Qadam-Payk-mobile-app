import 'dart:async';
import 'dart:convert';
import 'package:bla_bla_car/screens/mainView/ProfileScreen/ViewResponceScreen.dart';
import 'package:bla_bla_car/screens/mainView/chat/ChatListScreen.dart';
import 'package:bla_bla_car/screens/mainView/mytrip/InterestedPassengersScreen.dart';
import 'package:bla_bla_car/screens/notification/model/AppNotificationModel.dart';
import 'package:bla_bla_car/screens/notification/screens/NewsDetailScreen.dart';
import 'package:bla_bla_car/services/api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../service/local_cache.dart';
import 'main.dart'; // 👈 Import your LocalCache

// class NotificationHandler {
//   static final NotificationHandler _instance = NotificationHandler._internal();
//   factory NotificationHandler() => _instance;
//
//   NotificationHandler._internal();
//
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();
//
//   Future<void> init(BuildContext context) async {
//     // 🔑 Request permissions (iOS)
//     await _firebaseMessaging.requestPermission();
//
//     // 📢 Initialize local notifications
//     const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const iOSInit = DarwinInitializationSettings();
//     const initSettings = InitializationSettings(
//       android: androidInit,
//       iOS: iOSInit,
//     );
//
//     await _flutterLocalNotificationsPlugin.initialize(
//       initSettings,
//       onDidReceiveNotificationResponse: (details) {
//         _handleNotificationClick(context, details.payload);
//       },
//     );
//
//     // ✅ Get and save FCM token
//     await _fetchAndSaveFcmToken();
//
//     // 🔄 Listen for token refresh events (when FCM rotates token)
//     FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
//       debugPrint("♻️ FCM Token refreshed: $newToken");
//       await LocalCache.saveFcmToken(newToken);
//       // await _sendTokenToBackend(newToken);
//     });
//
//     // 📩 Foreground messages
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       debugPrint("----------- 🔥 FULL FCM MESSAGE (FOREGROUND) ------------");
//       debugPrint("ID: ${message.messageId}");
//       debugPrint("Title: ${message.notification?.title}");
//       debugPrint("Body: ${message.notification?.body}");
//       debugPrint("Data: ${message.data}");
//       debugPrint("Sender ID: ${message.senderId}");
//       debugPrint("Collapse Key: ${message.collapseKey}");
//       debugPrint("Category: ${message.category}");
//       debugPrint("Thread ID: ${message.threadId}");
//       debugPrint("---------------------------------------------------------");
//       _showLocalNotification(message);
//     });
//
//     // 📲 When notification is tapped (app in background)
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
//       debugPrint("----------- 🚀 OPENED FROM NOTIFICATION ------------");
//       debugPrint("Route: ${message.data['route']}");
//       debugPrint("Full Data: ${message.data}");
//       debugPrint("----------------------------------------------------");
//       // _handleNotificationClick(context, message.data['route']);
//       RemoteMessage? initialMessage = await FirebaseMessaging.instance
//           .getInitialMessage();
//       if (initialMessage != null) {
//         _openInterestedPassenger(context, initialMessage.data);
//       }
//       Future.delayed(const Duration(seconds: 2), () {
//         print('One second has passed.'); // Prints after 1 second.
//         _openInterestedPassenger(context, message.data);
//       });
//     });
//
//     // 🚀 App launched from terminated state by tapping notification
//     RemoteMessage? initialMessage = await FirebaseMessaging.instance
//         .getInitialMessage();
//     if (initialMessage != null) {
//       debugPrint("🚀 App launched by tapping notification (COLD START)");
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _openInterestedPassenger(context, initialMessage.data);
//       });
//     }
//   }
//
//   void _openInterestedPassenger(
//     BuildContext context,
//     Map<String, dynamic> data, {
//     RemoteMessage? message,
//   }) {
//     final type = data['notification_type']?.toString() ?? "";
//     final title = data['body']?.toString() ?? "";
//     final body = data['title']?.toString() ?? "";
//
//     debugPrint("🔔 Notification Type: $type");
//     debugPrint("📦 Data: $data");
//
//     if (type == "4") {
//       // → Go to Response screen
//       navigatorKey.currentState?.push(
//         MaterialPageRoute(
//           builder: (_) => Viewresponcescreen(initialTabIndex: 0),
//         ),
//       );
//     } else if (type == "3") {
//       // → Go to Chat screen
//       final chatId = data['chat_id']?.toString() ?? "";
//       navigatorKey.currentState?.push(
//         MaterialPageRoute(
//           builder: (_) => Chatlistscreen(), // <-- adjust to your chat page
//         ),
//       );
//     } else if (type == "2") {
//       // → Go to Chat screen
//       final chatId = data['chat_id']?.toString() ?? "";
//       navigatorKey.currentState?.push(
//         MaterialPageRoute(
//           builder: (_) => Chatlistscreen(), // <-- adjust to your chat page
//         ),
//       );
//     }
//     // TYPE 99 & 100 → News / Announcement
//     else if (type == "99" || type == "100") {
//       final title = data['title']?.toString() ?? "";
//       final body  = data['body']?.toString() ?? "";
//
//       debugPrint("📰 FINAL TITLE: $title");
//       debugPrint("📰 FINAL BODY: $body");
//       debugPrint("📰 FINAL TYPE: $type");
//
//       navigatorKey.currentState?.push(
//         MaterialPageRoute(
//           builder: (_) => NewsDetailScreen(
//             notification: AppNotification(
//               id: 0,
//               title: title,
//               description: body,
//               type: int.parse(type),
//               createdAt: DateTime.now().toString(),
//             ),
//           ),
//         ),
//       );
//     }
//   }
//
//   /// Fetch FCM token, save locally, and send to backend
//   Future<void> _fetchAndSaveFcmToken() async {
//     String? token = await _firebaseMessaging.getToken();
//     if (token != null) {
//       debugPrint("🔑 FCM Token: $token");
//       await LocalCache.saveFcmToken(token);
//       // await _sendTokenToBackend(token);
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
//     const platformDetails = NotificationDetails(
//       android: androidDetails,
//       iOS: iOSDetails,
//     );
//
//     await _flutterLocalNotificationsPlugin.show(
//       notification.hashCode,
//       notification.title,
//       notification.body,
//       platformDetails,
//       payload: jsonEncode(message.data), // ✅ FULL DATA
//     );
//   }
//
//   void _handleNotificationClick(BuildContext context, String? payload) {
//     if (payload == null || payload.isEmpty) return;
//
//     final Map<String, dynamic> data = jsonDecode(payload);
//     _openInterestedPassenger(context, data);
//   }
// }
//
// // Background message handler must be a top-level function
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("----------- 🌙 FULL FCM MESSAGE (BACKGROUND) ------------");
  debugPrint("ID: ${message.messageId}");
  debugPrint("Title: ${message.notification?.title}");
  debugPrint("Body: ${message.notification?.body}");
  debugPrint("Data: ${message.data}");
  debugPrint("---------------------------------------------------------");
}

class NotificationHandler {
  static final NotificationHandler _instance =
  NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  bool _notificationHandled = false;

  Future<void> init(BuildContext context) async {
    // 🔑 Permission
    await _firebaseMessaging.requestPermission();

    // 📢 Local notification init
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSInit = DarwinInitializationSettings();
    const initSettings =
    InitializationSettings(android: androidInit, iOS: iOSInit);

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationClick(details.payload);
      },
    );

    // 🔑 Token
    await _fetchAndSaveFcmToken();

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      await LocalCache.saveFcmToken(token);
    });

    // 🔔 FOREGROUND
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    // 📲 BACKGROUND TAP
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (_notificationHandled) return;
      _notificationHandled = true;

      debugPrint("🚀 OPENED FROM BACKGROUND");
      _openInterestedPassenger(message.data);
    });

    // ❄️ COLD START (ONLY ONCE)
    final initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null && !_notificationHandled) {
      _notificationHandled = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openInterestedPassenger(initialMessage.data);
      });
    }
  }

  // 🔀 ROUTING
  void _openInterestedPassenger(Map<String, dynamic> data) {
    final type = data['notification_type']?.toString() ?? "";

    debugPrint("🔔 TYPE: $type");
    debugPrint("📦 DATA: $data");

    if (type == "4") {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => Viewresponcescreen(initialTabIndex: 0)),
      );
    } if (type == "1"|| type == "3") {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => Viewresponcescreen(initialTabIndex: 0)),
      );
    }
    else if (type == "2") {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => Chatlistscreen()),
      );
    } else if (type == "99" || type == "100") {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => NewsDetailScreen(
            notification: AppNotification(
              id: 0,
              title: data['title'] ?? "",
              description: data['body'] ?? "",
              type: int.parse(type),
              createdAt: DateTime.now().toString(),
            ),
          ),
        ),
      );
    }
  }

  // 🔔 SHOW LOCAL
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'General',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(android: androidDetails),
      payload: jsonEncode(message.data),
    );
  }

  void _handleNotificationClick(String? payload) {
    if (payload == null) return;
    final data = jsonDecode(payload);
    _openInterestedPassenger(data);
  }

  Future<void> _fetchAndSaveFcmToken() async {
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await LocalCache.saveFcmToken(token);
    }
  }
}
