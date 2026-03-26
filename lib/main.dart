

import 'package:bla_bla_car/providers/cart_provider.dart';
import 'package:bla_bla_car/providers/product_provider.dart';
import 'package:bla_bla_car/providers/theme_provider.dart';
import 'package:bla_bla_car/providers/translate_provider.dart' show TranslateProvider;
import 'package:bla_bla_car/screens/auth/controller/auth_provider.dart' show LoginProvider;
import 'package:bla_bla_car/screens/courier/driver_home_shell.dart';
import 'package:bla_bla_car/screens/mainView/HomeShell.dart';
import 'package:bla_bla_car/screens/mainView/create/cantroller/passenger_request_provider.dart';
import 'package:bla_bla_car/screens/mainView/provide/ChatProvider.dart';
import 'package:bla_bla_car/screens/mainView/search/controller/RideListController.dart';
import 'package:bla_bla_car/screens/mainView/search/controller/search_provoder.dart';
import 'package:bla_bla_car/screens/onboarding/OnBoardingScreen.dart';
import 'package:bla_bla_car/service/colors.dart';
import 'package:bla_bla_car/service/local_cache.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';


import 'api_service/logger.dart';
import 'notification_handler.dart';
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('vehicles');
  initAppLogger();

  // Initialize TranslateProvider
  final translateProvider = TranslateProvider();
  await translateProvider.init();

  final seenOnboarding = await LocalCache.isOnboardingSeen();

  PaintingBinding.instance.imageCache.maximumSize = 200;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 200 << 20; // 200MB
  await NotificationHandler().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider.value(value: translateProvider),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => PassengerRequestProvider()),
        ChangeNotifierProvider(create: (_) => RideListProvide()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MyApp(),
    ),
  );
}

// class MyApp extends StatelessWidget {
//   final bool seenOnboarding;
//   const MyApp({super.key, required this.seenOnboarding});
//
//   @override
//   Widget build(BuildContext context) {
//     bool isDriver = false;
//     bool isLoaded = false;
//     // Initialize notification handler after build
//     // WidgetsBinding.instance.addPostFrameCallback((_) {
//     //   NotificationHandler().init(context);
//     // });
//
//     final mode = context.watch<ThemeProvider>().mode;
//     final locale = context.watch<TranslateProvider>().locale;
//
//     return MaterialApp(
//       navigatorKey: navigatorKey,
//       title: 'ShopEase Professional',
//       debugShowCheckedModeBanner: false,
//       theme: AppTheme.light(),
//       // darkTheme: AppTheme.dark(),
//       themeMode: mode,
//       locale: Locale(locale),
//       navigatorObservers: [routeObserver],
//       // home: seenOnboarding ? const HomeShell() : const OnboardingScreen(),
//       // home:  HomeShell() ,
//       home:  DriverHomeShell() ,
//     );
//   }
// }
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? isDriver;

  @override
  void initState() {
    super.initState();
    _loadDriverMode();
  }

  Future<void> _loadDriverMode() async {
    final driver = await LocalCache.getDriverMode();
    print("APP START DRIVER MODE = $driver");

    if (!mounted) return;

    setState(() {
      isDriver = driver;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeProvider>().mode;
    final locale = context.watch<TranslateProvider>().locale;

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      themeMode: mode,
      locale: Locale(locale),
      navigatorObservers: [routeObserver],
      home: isDriver == null
          ? const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      )
          : isDriver!
          ? const DriverHomeShell()
          : const HomeShell(),
    );
  }
}