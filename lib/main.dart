
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   // Initialize Hive
//   await Hive.initFlutter();
//   await Hive.openBox('vehicles');
//
//   // Initialize TranslateProvider
//   final translateProvider = TranslateProvider();
//   await translateProvider.init();
//
//   // Check if onboarding was seen
//   final seenOnboarding = await LocalCache.isOnboardingSeen();
//
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => ThemeProvider()),
//         ChangeNotifierProvider(create: (_) => ProductProvider()),
//         ChangeNotifierProvider(create: (_) => CartProvider()),
//         ChangeNotifierProvider.value(value: translateProvider), // reuse initialized provider
//         ChangeNotifierProvider(create: (_) => LoginProvider()), // ✅ added here
//         ChangeNotifierProvider(create: (_) => SearchProvider()), // ✅ added here
//         ChangeNotifierProvider(create: (_) => PassengerRequestProvider()),
//
//
//
//       ],
//       child: MyApp(seenOnboarding: seenOnboarding),
//     ),
//   );
// }
//
// class MyApp extends StatelessWidget {
//   final bool seenOnboarding;
//
//   const MyApp({super.key, required this.seenOnboarding});
//
//   @override
//   Widget build(BuildContext context) {
//     final mode = context.watch<ThemeProvider>().mode;
//     final locale = context.watch<TranslateProvider>().locale; // now you can watch locale
//
//      return MaterialApp(
//       title: 'ShopEase Professional',
//       debugShowCheckedModeBanner: false,
//       theme: AppTheme.light(),
//       darkTheme: AppTheme.dark(),
//       themeMode: mode,
//       locale: Locale(locale), // ✅ this is required
//       home: seenOnboarding
//           ? const HomeShell()
//           : const OnboardingScreen(),
//     );
//
//   }
// }


import 'package:bla_bla_car/providers/cart_provider.dart';
import 'package:bla_bla_car/providers/product_provider.dart';
import 'package:bla_bla_car/providers/theme_provider.dart';
import 'package:bla_bla_car/providers/translate_provider.dart' show TranslateProvider;
import 'package:bla_bla_car/screens/auth/controller/auth_provider.dart' show LoginProvider;
import 'package:bla_bla_car/screens/mainView/HomeShell.dart';
import 'package:bla_bla_car/screens/mainView/create%20/cantroller/passenger_request_provider.dart';
import 'package:bla_bla_car/screens/mainView/search/controller/RideListController.dart';
import 'package:bla_bla_car/screens/mainView/search/controller/search_provoder.dart';
import 'package:bla_bla_car/screens/onboarding/OnBoardingScreen.dart';
import 'package:bla_bla_car/service/colors.dart';
import 'package:bla_bla_car/service/local_cache.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';


import 'notification_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('vehicles');

  // Initialize TranslateProvider
  final translateProvider = TranslateProvider();
  await translateProvider.init();

  final seenOnboarding = await LocalCache.isOnboardingSeen();

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
      ],
      child: MyApp(seenOnboarding: seenOnboarding),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool seenOnboarding;
  const MyApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    // Initialize notification handler after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationHandler().init(context);
    });

    final mode = context.watch<ThemeProvider>().mode;
    final locale = context.watch<TranslateProvider>().locale;

    return MaterialApp(
      title: 'ShopEase Professional',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      locale: Locale(locale),
      home: seenOnboarding ? const HomeShell() : const OnboardingScreen(),
    );
  }
}
