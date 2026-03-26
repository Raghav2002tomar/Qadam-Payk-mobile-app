// // import 'dart:async';
// // import 'dart:convert';
// // import 'package:bla_bla_car/screens/courier/courier_request_dialoge.dart';
// // import 'package:bla_bla_car/screens/mainView/ProfileScreen/ViewResponceScreen.dart';
// // import 'package:bla_bla_car/screens/mainView/chat/ChatListScreen.dart';
// // import 'package:bla_bla_car/screens/mainView/mytrip/InterestedPassengersScreen.dart';
// // import 'package:bla_bla_car/screens/notification/model/AppNotificationModel.dart';
// // import 'package:bla_bla_car/screens/notification/screens/NewsDetailScreen.dart';
// // import 'package:bla_bla_car/services/api_service.dart';
// // import 'package:firebase_messaging/firebase_messaging.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// // import '../service/local_cache.dart';
// // import 'api_service/logger.dart';
// // import 'main.dart'; // 👈 Import your LocalCache
// // Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
// //   appLog("----------- 🌙 FULL FCM MESSAGE (BACKGROUND) ------------");
// //   appLog("ID: ${message.messageId}");
// //   appLog("Title: ${message.notification?.title}");
// //   appLog("Body: ${message.notification?.body}");
// //   appLog("Data: ${message.data}");
// //   appLog("---------------------------------------------------------");
// // }
// //
// // class NotificationHandler {
// //   static final NotificationHandler _instance =
// //   NotificationHandler._internal();
// //   factory NotificationHandler() => _instance;
// //   NotificationHandler._internal();
// //
// //   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
// //   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
// //   FlutterLocalNotificationsPlugin();
// //   bool _isDialogShowing = false;
// //   final ValueNotifier<List<RideRequest>> rideQueueNotifier =
// //   ValueNotifier<List<RideRequest>>([]);
// //
// //   bool _notificationHandled = false;
// //
// //   Future<void> init() async {
// //     // 🔑 Permission
// //     await _firebaseMessaging.requestPermission();
// //
// //     // 📢 Local notification init
// //     const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
// //     const iOSInit = DarwinInitializationSettings();
// //     const initSettings =
// //     InitializationSettings(android: androidInit, iOS: iOSInit);
// //
// //     await _flutterLocalNotificationsPlugin.initialize(
// //       initSettings,
// //       onDidReceiveNotificationResponse: (details) {
// //         _handleNotificationClick(details.payload);
// //       },
// //     );
// //
// //     // 🔑 Token
// //     await _fetchAndSaveFcmToken();
// //
// //     FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
// //       await LocalCache.saveFcmToken(token);
// //       print("fcm token ---- ${token}");
// //     });
// //
// //     // 🔔 FOREGROUND
// //     // FirebaseMessaging.onMessage.listen((message) {
// //     //   // _showLocalNotification(message);
// //     //   showRidePopup();
// //     //
// //     // });
// //     FirebaseMessaging.onMessage.listen((message) {
// //       final newRide = RideRequest(
// //         pickup: "City Mall",
// //         drop: "Airport",
// //         customerName: "Rahul ${rideQueueNotifier.value.length + 1}",
// //         customerPhone: "+91 9876543210",
// //         fare: 250,
// //         createdAt: DateTime.now(),
// //       );
// //
// //       final updatedList = List<RideRequest>.from(rideQueueNotifier.value);
// //       updatedList.insert(0, newRide); // add new ride to the queue
// //       rideQueueNotifier.value = updatedList;
// //
// //       showRidePopup();
// //       _startCountdown(); // start countdown for rides
// //
// //     });
// //
// //
// //     // 📲 BACKGROUND TAP
// //     FirebaseMessaging.onMessageOpenedApp.listen((message) {
// //       if (_notificationHandled) return;
// //       _notificationHandled = true;
// //
// //       appLog("🚀 OPENED FROM BACKGROUND");
// //       _openInterestedPassenger(message.data);
// //     });
// //
// //     // ❄️ COLD START (ONLY ONCE)
// //     final initialMessage =
// //     await FirebaseMessaging.instance.getInitialMessage();
// //
// //     if (initialMessage != null && !_notificationHandled) {
// //       _notificationHandled = true;
// //
// //       WidgetsBinding.instance.addPostFrameCallback((_) {
// //         _openInterestedPassenger(initialMessage.data);
// //       });
// //     }
// //   }
// //
// //   // 🔀 ROUTING
// //   void _openInterestedPassenger(Map<String, dynamic> data) {
// //     final type = data['notification_type']?.toString() ?? "";
// //
// //     appLog("🔔 TYPE: $type");
// //     appLog("📦 DATA: $data");
// //
// //     if (type == "4") {
// //       navigatorKey.currentState?.push(
// //         MaterialPageRoute(builder: (_) => Viewresponcescreen(initialTabIndex: 0)),
// //       );
// //     } if (type == "1"|| type == "3") {
// //       navigatorKey.currentState?.push(
// //         MaterialPageRoute(builder: (_) => Viewresponcescreen(initialTabIndex: 0)),
// //       );
// //     }
// //     else if (type == "2") {
// //       navigatorKey.currentState?.push(
// //         MaterialPageRoute(builder: (_) => Chatlistscreen()),
// //       );
// //     } else if (type == "99" || type == "100") {
// //       navigatorKey.currentState?.push(
// //         MaterialPageRoute(
// //           builder: (_) => NewsDetailScreen(
// //             notification: AppNotification(
// //               id: 0,
// //               title: data['title'] ?? "",
// //               description: data['body'] ?? "",
// //               type: int.parse(type),
// //               createdAt: DateTime.now().toString(),
// //             ),
// //           ),
// //         ),
// //       );
// //     }
// //   }
// //
// //   // 🔔 SHOW LOCAL
// //   Future<void> _showLocalNotification(RemoteMessage message) async {
// //     final notification = message.notification;
// //     if (notification == null) return;
// //
// //     const androidDetails = AndroidNotificationDetails(
// //       'default_channel',
// //       'General',
// //       importance: Importance.high,
// //       priority: Priority.high,
// //     );
// //
// //     await _flutterLocalNotificationsPlugin.show(
// //       notification.hashCode,
// //       notification.title,
// //       notification.body,
// //       const NotificationDetails(android: androidDetails),
// //       payload: jsonEncode(message.data),
// //     );
// //   }
// //
// //   void _handleNotificationClick(String? payload) {
// //     if (payload == null) return;
// //     final data = jsonDecode(payload);
// //     _openInterestedPassenger(data);
// //   }
// //
// //   Future<void> _fetchAndSaveFcmToken() async {
// //     try {
// //       final token = await _firebaseMessaging.getToken();
// //       if (token != null) {
// //         print("fcm token: $token");
// //         await LocalCache.saveFcmToken(token);
// //       }
// //     } catch (e) {
// //       print("Failed to fetch FCM token: $e");
// //       Future.delayed(const Duration(seconds: 5), _fetchAndSaveFcmToken);
// //     }
// //   }
// //
// //
// //   void showRidePopup() {
// //     final context = navigatorKey.currentContext;
// //     if (context == null || rideQueueNotifier.value.isEmpty) return;
// //
// //     if (_isDialogShowing) return; // dialog already open
// //     _isDialogShowing = true;
// //
// //     showDialog(
// //       context: context,
// //       barrierDismissible: false, // auto-remove will handle closing
// //       barrierColor: Colors.black.withOpacity(0.1),
// //       builder: (_) => WillPopScope(
// //         onWillPop: () async => false, // prevent manual back press
// //         child: RideRequestDialog(
// //           rideQueueNotifier: rideQueueNotifier,
// //         ),
// //       ),
// //     ).then((_) {
// //       _isDialogShowing = false;
// //     });
// //
// //     _startAutoRemoveQueue();
// //   }
// //
// //   void _startCountdown() {
// //     Timer.periodic(const Duration(seconds: 1), (timer) {
// //       final currentList = List<RideRequest>.from(rideQueueNotifier.value);
// //
// //       if (currentList.isEmpty) {
// //         timer.cancel();
// //         if (_isDialogShowing) {
// //           navigatorKey.currentState?.pop();
// //           _isDialogShowing = false;
// //         }
// //         return;
// //       }
// //
// //       bool updated = false;
// //
// //       for (int i = 0; i < currentList.length; i++) {
// //         currentList[i].remainingSeconds -= 1;
// //         if (currentList[i].remainingSeconds <= 0) {
// //           // remove expired ride
// //           currentList.removeAt(i);
// //           i--;
// //           updated = true;
// //         } else {
// //           updated = true;
// //         }
// //       }
// //
// //       if (updated) {
// //         rideQueueNotifier.value = currentList;
// //       }
// //     });
// //   }
// //
// //
// //
// //   void _startAutoRemoveQueue() async {
// //     while (rideQueueNotifier.value.isNotEmpty) {
// //       // Wait 15 seconds
// //       await Future.delayed(const Duration(seconds: 15));
// //
// //       final currentList = List<RideRequest>.from(rideQueueNotifier.value);
// //       if (currentList.isNotEmpty) {
// //         currentList.removeAt(0); // remove first ride
// //         rideQueueNotifier.value = currentList;
// //       }
// //
// //       // Close dialog if no rides left
// //       if (currentList.isEmpty && _isDialogShowing) {
// //         navigatorKey.currentState?.pop();
// //         _isDialogShowing = false;
// //       }
// //     }
// //   }
// //
// //
// // }
// //
// //
// // class RideRequest {
// //   final String pickup;
// //   final String drop;
// //   final String customerName;
// //   final String customerPhone;
// //   final double fare;
// //   final DateTime createdAt;
// //
// //   int remainingSeconds; // ⬅️ countdown in seconds
// //
// //   RideRequest({
// //     required this.pickup,
// //     required this.drop,
// //     required this.customerName,
// //     required this.customerPhone,
// //     required this.fare,
// //     required this.createdAt,
// //     this.remainingSeconds = 15, // default 15 sec
// //   });
// // }
//
//
// // import 'dart:async';
// // import 'dart:convert';
// // import 'package:bla_bla_car/screens/courier/courier_request_dialoge.dart';
// // import 'package:bla_bla_car/screens/mainView/ProfileScreen/ViewResponceScreen.dart';
// // import 'package:bla_bla_car/screens/mainView/chat/ChatListScreen.dart';
// // import 'package:bla_bla_car/screens/mainView/mytrip/InterestedPassengersScreen.dart';
// // import 'package:bla_bla_car/screens/notification/model/AppNotificationModel.dart';
// // import 'package:bla_bla_car/screens/notification/screens/NewsDetailScreen.dart';
// // import 'package:bla_bla_car/services/api_service.dart';
// // import 'package:firebase_messaging/firebase_messaging.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// // import '../service/local_cache.dart';
// // import 'api_service/logger.dart';
// // import 'main.dart';
// //
// // Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
// //   appLog("----------- 🌙 FULL FCM MESSAGE (BACKGROUND) ------------");
// //   appLog("ID: ${message.messageId}");
// //   appLog("Title: ${message.notification?.title}");
// //   appLog("Body: ${message.notification?.body}");
// //   appLog("Data: ${message.data}");
// //   appLog("---------------------------------------------------------");
// // }
// //
// // class NotificationHandler {
// //   static final NotificationHandler _instance =
// //   NotificationHandler._internal();
// //   factory NotificationHandler() => _instance;
// //   NotificationHandler._internal();
// //
// //   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
// //   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
// //   FlutterLocalNotificationsPlugin();
// //   bool _isDialogShowing = false;
// //   final ValueNotifier<List<RideRequest>> rideQueueNotifier =
// //   ValueNotifier<List<RideRequest>>([]);
// //
// //   bool _notificationHandled = false;
// //
// //   // ✅ Single shared timer — prevents multiple timers stacking
// //   Timer? _countdownTimer;
// //
// //   Future<void> init() async {
// //     await _firebaseMessaging.requestPermission();
// //
// //     const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
// //     const iOSInit = DarwinInitializationSettings();
// //     const initSettings =
// //     InitializationSettings(android: androidInit, iOS: iOSInit);
// //
// //     await _flutterLocalNotificationsPlugin.initialize(
// //       initSettings,
// //       onDidReceiveNotificationResponse: (details) {
// //         _handleNotificationClick(details.payload);
// //       },
// //     );
// //
// //     await _fetchAndSaveFcmToken();
// //
// //     FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
// //       await LocalCache.saveFcmToken(token);
// //       print("fcm token ---- $token");
// //     });
// //
// //     FirebaseMessaging.onMessage.listen((message) {
// //       // _showLocalNotification(message);
// //       final newRide = RideRequest(
// //         pickup: data['pickup_location'] ?? '',
// //         drop: data['drop_location'] ?? '',
// //         customerName: data['sender_name'] ?? '',
// //         customerPhone: data['sender_phone'] ?? '',
// //         fare: double.tryParse(data['suggested_price'] ?? '0') ?? 0,
// //         createdAt: DateTime.now(),
// //       );
// //
// //       final updatedList = List<RideRequest>.from(rideQueueNotifier.value);
// //       updatedList.insert(0, newRide);
// //       rideQueueNotifier.value = updatedList;
// //
// //       showRidePopup();
// //       _ensureCountdownRunning();
// //     });
// //
// //     FirebaseMessaging.onMessageOpenedApp.listen((message) {
// //       if (_notificationHandled) return;
// //       _notificationHandled = true;
// //       appLog("🚀 OPENED FROM BACKGROUND");
// //       _openInterestedPassenger(message.data);
// //     });
// //
// //     final initialMessage =
// //     await FirebaseMessaging.instance.getInitialMessage();
// //
// //     if (initialMessage != null && !_notificationHandled) {
// //       _notificationHandled = true;
// //       WidgetsBinding.instance.addPostFrameCallback((_) {
// //         _openInterestedPassenger(initialMessage.data);
// //       });
// //     }
// //   }
// //
// //   void _openInterestedPassenger(Map<String, dynamic> data) {
// //     final type = data['notification_type']?.toString() ?? "";
// //     appLog("🔔 TYPE: $type");
// //     appLog("📦 DATA: $data");
// //
// //     if (type == "4") {
// //       navigatorKey.currentState?.push(
// //         MaterialPageRoute(
// //             builder: (_) => Viewresponcescreen(initialTabIndex: 0)),
// //       );
// //     }
// //     if (type == "1" || type == "3") {
// //       navigatorKey.currentState?.push(
// //         MaterialPageRoute(
// //             builder: (_) => Viewresponcescreen(initialTabIndex: 0)),
// //       );
// //     } else if (type == "2") {
// //       navigatorKey.currentState?.push(
// //         MaterialPageRoute(builder: (_) => Chatlistscreen()),
// //       );
// //     } else if (type == "99" || type == "100") {
// //       navigatorKey.currentState?.push(
// //         MaterialPageRoute(
// //           builder: (_) => NewsDetailScreen(
// //             notification: AppNotification(
// //               id: 0,
// //               title: data['title'] ?? "",
// //               description: data['body'] ?? "",
// //               type: int.parse(type),
// //               createdAt: DateTime.now().toString(),
// //             ),
// //           ),
// //         ),
// //       );
// //     }
// //   }
// //
// //   Future<void> _showLocalNotification(RemoteMessage message) async {
// //     final notification = message.notification;
// //     if (notification == null) return;
// //
// //     const androidDetails = AndroidNotificationDetails(
// //       'default_channel',
// //       'General',
// //       importance: Importance.high,
// //       priority: Priority.high,
// //     );
// //
// //     await _flutterLocalNotificationsPlugin.show(
// //       notification.hashCode,
// //       notification.title,
// //       notification.body,
// //       const NotificationDetails(android: androidDetails),
// //       payload: jsonEncode(message.data),
// //     );
// //   }
// //
// //   void _handleNotificationClick(String? payload) {
// //     if (payload == null) return;
// //     final data = jsonDecode(payload);
// //     _openInterestedPassenger(data);
// //   }
// //
// //   Future<void> _fetchAndSaveFcmToken() async {
// //     try {
// //       final token = await _firebaseMessaging.getToken();
// //       if (token != null) {
// //         print("fcm token: $token");
// //         await LocalCache.saveFcmToken(token);
// //       }
// //     } catch (e) {
// //       print("Failed to fetch FCM token: $e");
// //       Future.delayed(const Duration(seconds: 5), _fetchAndSaveFcmToken);
// //     }
// //   }
// //
// //   void showRidePopup() {
// //     final context = navigatorKey.currentContext;
// //     if (context == null || rideQueueNotifier.value.isEmpty) return;
// //     if (_isDialogShowing) return;
// //     _isDialogShowing = true;
// //
// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       barrierColor: Colors.black.withOpacity(0.1),
// //       builder: (_) => WillPopScope(
// //         onWillPop: () async => false,
// //         child: RideRequestDialog(
// //           rideQueueNotifier: rideQueueNotifier,
// //         ),
// //       ),
// //     ).then((_) {
// //       _isDialogShowing = false;
// //     });
// //   }
// //
// //   /// ✅ Starts countdown only if not already running
// //   void _ensureCountdownRunning() {
// //     if (_countdownTimer != null && _countdownTimer!.isActive) return;
// //
// //     _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
// //       final currentList = List<RideRequest>.from(rideQueueNotifier.value);
// //
// //       if (currentList.isEmpty) {
// //         timer.cancel();
// //         _countdownTimer = null;
// //         if (_isDialogShowing) {
// //           navigatorKey.currentState?.pop();
// //           _isDialogShowing = false;
// //         }
// //         return;
// //       }
// //
// //       for (int i = currentList.length - 1; i >= 0; i--) {
// //         currentList[i].remainingSeconds -= 1;
// //         if (currentList[i].remainingSeconds <= 0) {
// //           currentList.removeAt(i);
// //         }
// //       }
// //
// //       rideQueueNotifier.value = List<RideRequest>.from(currentList);
// //
// //       // Close dialog if all expired
// //       if (currentList.isEmpty && _isDialogShowing) {
// //         navigatorKey.currentState?.pop();
// //         _isDialogShowing = false;
// //       }
// //     });
// //   }
// // }
// //
// // class RideRequest {
// //   final String courierId;
// //   final String pickup;
// //   final String drop;
// //   final String senderName;
// //   final String senderPhone;
// //   final String receiverName;
// //   final String receiverPhone;
// //   final String packageSize;
// //   final String tripType;
// //   final String paymentMethod;
// //   final String paidBy;
// //   final String dropLatitude;
// //   final String dropLongitude;
// //   final String expiresAt;
// //   final double fare;
// //   final DateTime createdAt;
// //
// //   int remainingSeconds;
// //
// //   RideRequest({
// //     required this.courierId,
// //     required this.pickup,
// //     required this.drop,
// //     required this.senderName,
// //     required this.senderPhone,
// //     required this.receiverName,
// //     required this.receiverPhone,
// //     required this.packageSize,
// //     required this.tripType,
// //     required this.paymentMethod,
// //     required this.paidBy,
// //     required this.dropLatitude,
// //     required this.dropLongitude,
// //     required this.expiresAt,
// //     required this.fare,
// //     required this.createdAt,
// //     this.remainingSeconds = 15,
// //   });
// // }
//
//
//
//
// import 'dart:async';
// import 'dart:convert';
// import 'package:bla_bla_car/screens/courier/courier_request_dialoge.dart';
// import 'package:bla_bla_car/screens/mainView/ProfileScreen/ViewResponceScreen.dart';
// import 'package:bla_bla_car/screens/mainView/chat/ChatListScreen.dart';
// import 'package:bla_bla_car/screens/notification/model/AppNotificationModel.dart';
// import 'package:bla_bla_car/screens/notification/screens/NewsDetailScreen.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import '../service/local_cache.dart';
// import 'main.dart';
//
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   print("🌙 BACKGROUND MESSAGE DATA: ${message.data}");
// }
//
// class NotificationHandler {
//   static final NotificationHandler _instance =
//   NotificationHandler._internal();
//   factory NotificationHandler() => _instance;
//   NotificationHandler._internal();
//
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _localNotifications =
//   FlutterLocalNotificationsPlugin();
//
//   final ValueNotifier<List<RideRequest>> rideQueueNotifier =
//   ValueNotifier<List<RideRequest>>([]);
//
//   bool _isDialogShowing = false;
//   bool _notificationHandled = false;
//   Timer? _countdownTimer;
//
//   Future<void> init() async {
//     await _firebaseMessaging.requestPermission();
//
//     const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const iOSInit = DarwinInitializationSettings();
//     const initSettings =
//     InitializationSettings(android: androidInit, iOS: iOSInit);
//
//     await _localNotifications.initialize(
//       initSettings,
//       onDidReceiveNotificationResponse: (details) {
//         if (details.payload != null) {
//           final data = jsonDecode(details.payload!);
//           _openInterestedPassenger(data);
//         }
//       },
//     );
//
//     await _fetchAndSaveFcmToken();
//
//     FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
//
//     FirebaseMessaging.onMessageOpenedApp.listen((message) {
//       if (_notificationHandled) return;
//       _notificationHandled = true;
//       _handleNotificationTap(message.data);
//     });
//
//     final initialMessage =
//     await FirebaseMessaging.instance.getInitialMessage();
//
//     if (initialMessage != null && !_notificationHandled) {
//       _notificationHandled = true;
//       _handleNotificationTap(initialMessage.data);
//     }
//   }
//
//   // ================= FOREGROUND =================
//
//   void _handleForegroundMessage(RemoteMessage message) {
//     print("🔔 FOREGROUND DATA: ${message.data}");
//
//     final type = message.data['notification_type']?.toString();
//
//     if (type == "15") {
//       _handleCourierNotification(message.data);
//     } else {
//       _showLocalNotification(message);
//     }
//   }
//
//   // ================= TYPE 15 COURIER =================
//
//   void _handleCourierNotification(Map<String, dynamic> data) {
//     final ride = RideRequest(
//       courierId: data['courier_id'] ?? '',
//       pickup: data['pickup_location'] ?? '',
//       drop: data['drop_location'] ?? '',
//       senderName: data['sender_name'] ?? '',
//       senderPhone: data['sender_phone'] ?? '',
//       receiverName: data['receiver_name'] ?? '',
//       receiverPhone: data['receiver_phone'] ?? '',
//       packageSize: data['package_size'] ?? '',
//       tripType: data['trip_type'] ?? '',
//       paymentMethod: data['payment_method'] ?? '',
//       paidBy: data['paid_by'] ?? '',
//       dropLatitude: data['drop_latitude'] ?? '',
//       dropLongitude: data['drop_longitude'] ?? '',
//       expiresAt: data['expires_at'] ?? '',
//       fare: double.tryParse(data['suggested_price'] ?? '0') ?? 0,
//       createdAt: DateTime.now(),
//     );
//
//     final list = List<RideRequest>.from(rideQueueNotifier.value);
//     list.insert(0, ride);
//     rideQueueNotifier.value = list;
//
//     _showCourierPopup();
//     _startCountdown();
//   }
//
//   void _showCourierPopup() {
//     final context = navigatorKey.currentContext;
//     if (context == null || rideQueueNotifier.value.isEmpty) return;
//     if (_isDialogShowing) return;
//
//     _isDialogShowing = true;
//
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => WillPopScope(
//         onWillPop: () async => false,
//         child: RideRequestDialog(
//           rideQueueNotifier: rideQueueNotifier,
//         ),
//       ),
//     ).then((_) {
//       _isDialogShowing = false;
//     });
//   }
//
//   void _startCountdown() {
//     if (_countdownTimer != null && _countdownTimer!.isActive) return;
//
//     _countdownTimer =
//         Timer.periodic(const Duration(seconds: 1), (timer) {
//           final list = List<RideRequest>.from(rideQueueNotifier.value);
//
//           if (list.isEmpty) {
//             timer.cancel();
//             _countdownTimer = null;
//             if (_isDialogShowing) {
//               navigatorKey.currentState?.pop();
//               _isDialogShowing = false;
//             }
//             return;
//           }
//
//           for (int i = list.length - 1; i >= 0; i--) {
//             list[i].remainingSeconds--;
//             if (list[i].remainingSeconds <= 0) {
//               list.removeAt(i);
//             }
//           }
//
//           rideQueueNotifier.value = list;
//         });
//   }
//
//   // ================= OTHER TYPES =================
//
//   Future<void> _showLocalNotification(RemoteMessage message) async {
//     final notification = message.notification;
//     if (notification == null) return;
//
//     const androidDetails = AndroidNotificationDetails(
//       'default_channel',
//       'General',
//       importance: Importance.high,
//       priority: Priority.high,
//     );
//
//     await _localNotifications.show(
//       notification.hashCode,
//       notification.title,
//       notification.body,
//       const NotificationDetails(android: androidDetails),
//       payload: jsonEncode(message.data),
//     );
//   }
//
//   void _handleNotificationTap(Map<String, dynamic> data) {
//     final type = data['notification_type']?.toString();
//
//     if (type == "15") {
//       _handleCourierNotification(data);
//       return;
//     }
//
//     _openInterestedPassenger(data);
//   }
//
//   void _openInterestedPassenger(Map<String, dynamic> data) {
//     final type = data['notification_type']?.toString() ?? "";
//
//     if (type == "4" || type == "1" || type == "3") {
//       navigatorKey.currentState?.push(
//         MaterialPageRoute(
//             builder: (_) => Viewresponcescreen(initialTabIndex: 0)),
//       );
//     } else if (type == "2") {
//       navigatorKey.currentState?.push(
//         MaterialPageRoute(builder: (_) => Chatlistscreen()),
//       );
//     } else if (type == "99" || type == "100") {
//       navigatorKey.currentState?.push(
//         MaterialPageRoute(
//           builder: (_) => NewsDetailScreen(
//             notification: AppNotification(
//               id: 0,
//               title: data['title'] ?? "",
//               description: data['body'] ?? "",
//               type: int.tryParse(type) ?? 0,
//               createdAt: DateTime.now().toString(),
//             ),
//           ),
//         ),
//       );
//     }
//   }
//
//   Future<void> _fetchAndSaveFcmToken() async {
//     final token = await _firebaseMessaging.getToken();
//     if (token != null) {
//       await LocalCache.saveFcmToken(token);
//       print("FCM Token: $token");
//     }
//   }
// }
//
// // ================= MODEL =================
//
// class RideRequest {
//   final String courierId;
//   final String pickup;
//   final String drop;
//   final String senderName;
//   final String senderPhone;
//   final String receiverName;
//   final String receiverPhone;
//   final String packageSize;
//   final String tripType;
//   final String paymentMethod;
//   final String paidBy;
//   final String dropLatitude;
//   final String dropLongitude;
//   final String expiresAt;
//   final double fare;
//   final DateTime createdAt;
//
//   int remainingSeconds;
//
//   RideRequest({
//     required this.courierId,
//     required this.pickup,
//     required this.drop,
//     required this.senderName,
//     required this.senderPhone,
//     required this.receiverName,
//     required this.receiverPhone,
//     required this.packageSize,
//     required this.tripType,
//     required this.paymentMethod,
//     required this.paidBy,
//     required this.dropLatitude,
//     required this.dropLongitude,
//     required this.expiresAt,
//     required this.fare,
//     required this.createdAt,
//     this.remainingSeconds = 15,
//   });
// }


import 'dart:async';
import 'dart:convert';
import 'package:bla_bla_car/screens/courier/courier_request_dialoge.dart';
import 'package:bla_bla_car/screens/courier/driver_courier_detail_screen.dart';
import 'package:bla_bla_car/screens/courier/order_detail_screen.dart';
import 'package:bla_bla_car/screens/mainView/ProfileScreen/ViewResponceScreen.dart';
import 'package:bla_bla_car/screens/mainView/chat/ChatListScreen.dart';
import 'package:bla_bla_car/screens/notification/model/AppNotificationModel.dart';
import 'package:bla_bla_car/screens/notification/screens/NewsDetailScreen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../service/local_cache.dart';
import 'main.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🌙 BACKGROUND MESSAGE DATA: ${message.data}");
}

class NotificationHandler {
  static final NotificationHandler _instance =
  NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // Driver side queue
  final ValueNotifier<List<CourierRequest>> driverQueueNotifier =
  ValueNotifier<List<CourierRequest>>([]);

  // User side queue (for drivers interested in user's courier)
  final ValueNotifier<List<DriverInterest>> userQueueNotifier =
  ValueNotifier<List<DriverInterest>>([]);

  bool _isDriverDialogShowing = false;
  bool _isUserDialogShowing = false;
  bool _notificationHandled = false;
  Timer? _driverCountdownTimer;
  Timer? _userCountdownTimer;

  Future<void> init() async {
    await _firebaseMessaging.requestPermission();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSInit = DarwinInitializationSettings();
    const initSettings =
    InitializationSettings(android: androidInit, iOS: iOSInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          final data = jsonDecode(details.payload!);
          _handleNotificationTap(data);
        }
      },
    );

    await _fetchAndSaveFcmToken();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (_notificationHandled) return;
      _notificationHandled = true;
      _handleNotificationTap(message.data);
    });

    final initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null && !_notificationHandled) {
      _notificationHandled = true;
      _handleNotificationTap(initialMessage.data);
    }
  }

  // ================= FOREGROUND =================

  void _handleForegroundMessage(RemoteMessage message) {
    print("🔔 FOREGROUND DATA: ${message.data}");

    final type = message.data['notification_type']?.toString();

    if (type == "15") {
      // Driver side - New courier request
      _handleDriverCourierNotification(message.data);
    } else if (type == "16") {
      // User side - Driver interested in courier
      _handleUserDriverInterestNotification(message.data);
    } else {
      _showLocalNotification(message);
    }
  }

  // ================= TYPE 15 - DRIVER SIDE (New Courier Request) =================

  void _handleDriverCourierNotification(Map<String, dynamic> data) {
    final request = CourierRequest(
      courierId: data['courier_id']?.toString() ?? '',
      pickup: data['pickup_location'] ?? '',
      drop: data['drop_location'] ?? '',
      senderName: data['sender_name'] ?? '',
      senderPhone: data['sender_phone'] ?? '',
      receiverName: data['receiver_name'] ?? '',
      receiverPhone: data['receiver_phone'] ?? '',
      packageSize: data['package_size'] ?? '',
      tripType: data['trip_type'] ?? '',
      paymentMethod: data['payment_method'] ?? '',
      paidBy: data['paid_by'] ?? '',
      dropLatitude: data['drop_latitude'] ?? '',
      dropLongitude: data['drop_longitude'] ?? '',
      expiresAt: data['expires_at'] ?? '',
      fare: double.tryParse(data['suggested_price']?.toString() ?? '0') ?? 0,
      time: data['time'] ?? '',
      distance: data['distance'] ?? '',
      userImage: data['user_image'] ?? '',
      createdAt: DateTime.now(),
    );

    final list = List<CourierRequest>.from(driverQueueNotifier.value);
    list.insert(0, request);
    driverQueueNotifier.value = list;

    _showDriverPopup();
    _startDriverCountdown();
  }

  void _showDriverPopup() {
    final context = navigatorKey.currentContext;
    if (context == null || driverQueueNotifier.value.isEmpty) return;
    if (_isDriverDialogShowing) return;

    _isDriverDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: DriverRideRequestDialog(
          queueNotifier: driverQueueNotifier,
        ),
      ),
    ).then((_) {
      _isDriverDialogShowing = false;
    });
  }

  void _startDriverCountdown() {
    if (_driverCountdownTimer != null && _driverCountdownTimer!.isActive) return;

    _driverCountdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
          final list = List<CourierRequest>.from(driverQueueNotifier.value);

          if (list.isEmpty) {
            timer.cancel();
            _driverCountdownTimer = null;
            if (_isDriverDialogShowing) {
              navigatorKey.currentState?.pop();
              _isDriverDialogShowing = false;
            }
            return;
          }

          for (int i = list.length - 1; i >= 0; i--) {
            list[i].remainingSeconds--;
            if (list[i].remainingSeconds <= 0) {
              list.removeAt(i);
            }
          }

          driverQueueNotifier.value = list;
        });
  }

  // ================= TYPE 16 - USER SIDE (Driver Interested) =================

  void _handleUserDriverInterestNotification(Map<String, dynamic> data) {
    final interest = DriverInterest(
      courierId: data['courier_id']?.toString() ?? '',
      driverId: data['driver_id']?.toString() ?? '',
      driverName: data['driver_name'] ?? '',
      driverPhone: data['driver_phone'] ?? '',
      driverImage: data['driver_image'] ?? '',
      driverPrice: double.tryParse(data['driver_price']?.toString() ?? '0') ?? 0,
      suggestedPrice: double.tryParse(data['suggested_price']?.toString() ?? '0') ?? 0,
      driverMessage: data['driver_message'] ?? '',
      pickup: data['pickup_location'] ?? '',
      drop: data['drop_location'] ?? '',
      senderName: data['sender_name'] ?? '',
      senderPhone: data['sender_phone'] ?? '',
      receiverName: data['receiver_name'] ?? '',
      receiverPhone: data['receiver_phone'] ?? '',
      packageSize: data['package_size'] ?? '',
      tripType: data['trip_type'] ?? '',
      paymentMethod: data['payment_method'] ?? '',
      paidBy: data['paid_by'] ?? '',
      dropLatitude: data['drop_latitude'] ?? '',
      dropLongitude: data['drop_longitude'] ?? '',
      time: data['time'] ?? '',
      distance: data['distance'] ?? '',
      expiresAt: data['expires_at'] ?? '',
      createdAt: DateTime.now(),
    );

    final list = List<DriverInterest>.from(userQueueNotifier.value);
    list.insert(0, interest);
    userQueueNotifier.value = list;

    _showUserPopup();
    _startUserCountdown();
  }

  void _showUserPopup() {
    final context = navigatorKey.currentContext;
    if (context == null || userQueueNotifier.value.isEmpty) return;
    if (_isUserDialogShowing) return;

    _isUserDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: UserDriverInterestDialog(
          queueNotifier: userQueueNotifier,
        ),
      ),
    ).then((_) {
      _isUserDialogShowing = false;
    });
  }

  void _startUserCountdown() {
    if (_userCountdownTimer != null && _userCountdownTimer!.isActive) return;

    _userCountdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
          final list = List<DriverInterest>.from(userQueueNotifier.value);

          if (list.isEmpty) {
            timer.cancel();
            _userCountdownTimer = null;
            if (_isUserDialogShowing) {
              navigatorKey.currentState?.pop();
              _isUserDialogShowing = false;
            }
            return;
          }

          for (int i = list.length - 1; i >= 0; i--) {
            list[i].remainingSeconds--;
            if (list[i].remainingSeconds <= 0) {
              list.removeAt(i);
            }
          }

          userQueueNotifier.value = list;
        });
  }

  // ================= NOTIFICATION TAP HANDLER =================

  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['notification_type']?.toString();

    if (type == "15") {
      // Open driver courier detail
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => DriverCourierDetailScreen(
            courierId: data['courier_id']!.toString(),
          ),
        ),
      );    } else if (type == "16" || type == "18") {
      // Open user courier detail with driver info
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => CourierDetailScreen(  // ← Changed to user screen
            orderId: data['courier_id']!.toString(),
          ),
        ),
      );    } else if (type == "4" || type == "1" || type == "3") {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
            builder: (_) => Viewresponcescreen(initialTabIndex: 0)),
      );
    } else if (type == "2") {
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
                type: int.tryParse(type.toString()) ?? 0,
                createdAt: DateTime.now().toString(),
            ),
          ),
        ),
      );
    }
  }

  void _openDriverCourierDetail(Map<String, dynamic> data) {
    // Create a CourierModel from the notification data
    final courier = CourierModel(
      id: int.tryParse(data['courier_id']?.toString() ?? '0') ?? 0,
      userId: 0,
      pickupLocation: data['pickup_location'] ?? '',
      dropLocation: data['drop_location'] ?? '',
      pickupLatitude: data['pickup_latitude']?.toString(),
      pickupLongitude: data['pickup_longitude']?.toString(),
      dropLatitude: data['drop_latitude']?.toString(),
      dropLongitude: data['drop_longitude']?.toString(),
      distance: data['distance'] ?? '',
      time: data['time'] ?? '',
      tripType: data['trip_type'] ?? '',
      senderName: data['sender_name'] ?? '',
      senderPhone: data['sender_phone'] ?? '',
      receiverName: data['receiver_name'] ?? '',
      receiverPhone: data['receiver_phone'] ?? '',
      packageDescription: data['package_description'] ?? '',
      packageSize: data['package_size'] ?? '',
      suggestedPrice: data['suggested_price']?.toString() ?? '0',
      paymentMethod: data['payment_method'] ?? '',
      status: 'pending',
      senderImage: data['user_image'] ?? '',
    );

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => DriverCourierDetailScreen(courierId: data['courier_id']!.toString(),),
      ),
    );
  }

  void _openUserCourierDetail(Map<String, dynamic> data) {
    // Navigate to user's courier detail with driver info
    // You'll need to implement UserCourierDetailScreen similarly
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => UserCourierDetailScreen(
          courierId: int.tryParse(data['courier_id']?.toString() ?? '0') ?? 0,
          driverId: int.tryParse(data['driver_id']?.toString() ?? '0') ?? 0,
        ),
      ),
    );
  }

  // ================= LOCAL NOTIFICATION =================

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'General',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(android: androidDetails),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> _fetchAndSaveFcmToken() async {
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await LocalCache.saveFcmToken(token);
      print("FCM Token: $token");
    }
  }
}

// ================= MODELS =================

class CourierRequest {
  final String courierId;
  final String pickup;
  final String drop;
  final String senderName;
  final String senderPhone;
  final String receiverName;
  final String receiverPhone;
  final String packageSize;
  final String tripType;
  final String paymentMethod;
  final String paidBy;
  final String dropLatitude;
  final String dropLongitude;
  final String expiresAt;
  final double fare;
  final String time;
  final String distance;
  final String userImage;
  final DateTime createdAt;

  int remainingSeconds;

  CourierRequest({
    required this.courierId,
    required this.pickup,
    required this.drop,
    required this.senderName,
    required this.senderPhone,
    required this.receiverName,
    required this.receiverPhone,
    required this.packageSize,
    required this.tripType,
    required this.paymentMethod,
    required this.paidBy,
    required this.dropLatitude,
    required this.dropLongitude,
    required this.expiresAt,
    required this.fare,
    required this.time,
    required this.distance,
    required this.userImage,
    required this.createdAt,
    this.remainingSeconds = 15,
  });
}

class DriverInterest {
  final String courierId;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String driverImage;
  final double driverPrice;
  final double suggestedPrice;
  final String driverMessage;
  final String pickup;
  final String drop;
  final String senderName;
  final String senderPhone;
  final String receiverName;
  final String receiverPhone;
  final String packageSize;
  final String tripType;
  final String paymentMethod;
  final String paidBy;
  final String dropLatitude;
  final String dropLongitude;
  final String time;
  final String distance;
  final String expiresAt;
  final DateTime createdAt;

  int remainingSeconds;

  DriverInterest({
    required this.courierId,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.driverImage,
    required this.driverPrice,
    required this.suggestedPrice,
    required this.driverMessage,
    required this.pickup,
    required this.drop,
    required this.senderName,
    required this.senderPhone,
    required this.receiverName,
    required this.receiverPhone,
    required this.packageSize,
    required this.tripType,
    required this.paymentMethod,
    required this.paidBy,
    required this.dropLatitude,
    required this.dropLongitude,
    required this.time,
    required this.distance,
    required this.expiresAt,
    required this.createdAt,
    this.remainingSeconds = 15,
  });
}

// You'll need to import your existing CourierModel
class CourierModel {
  final int id;
  final int userId;
  final String pickupLocation;
  final String dropLocation;
  final String? pickupLatitude;
  final String? pickupLongitude;
  final String? dropLatitude;
  final String? dropLongitude;
  final String distance;
  final String time;
  final String tripType;
  final String senderName;
  final String senderPhone;
  final String receiverName;
  final String receiverPhone;
  final String packageDescription;
  final String packageSize;
  final String suggestedPrice;
  final String paymentMethod;
  final String status;
  final String senderImage;

  CourierModel({
    required this.id,
    required this.userId,
    required this.pickupLocation,
    required this.dropLocation,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropLatitude,
    this.dropLongitude,
    required this.distance,
    required this.time,
    required this.tripType,
    required this.senderName,
    required this.senderPhone,
    required this.receiverName,
    required this.receiverPhone,
    required this.packageDescription,
    required this.packageSize,
    required this.suggestedPrice,
    required this.paymentMethod,
    required this.status,
    required this.senderImage,
  });
}

// Placeholder for UserCourierDetailScreen - you need to create this
class UserCourierDetailScreen extends StatelessWidget {
  final int courierId;
  final int driverId;

  const UserCourierDetailScreen({
    super.key,
    required this.courierId,
    required this.driverId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Courier Detail")),
      body: Center(
        child: Text("Courier ID: $courierId\nDriver ID: $driverId"),
      ),
    );
  }
}