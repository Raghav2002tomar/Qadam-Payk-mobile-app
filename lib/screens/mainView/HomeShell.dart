import 'package:flutter/material.dart';
import '../../service/local_cache.dart';
import '../auth/SignInScreen.dart';
import 'CurvedNavItem.dart';
import 'ProfileScreen/ProfileScreen.dart';
import 'create /Add_vehical.dart';
import 'create /Create_selection.dart';
import '../mainView/search/Search_Screen.dart';
import 'mytrip/RideStatusScreen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  final List<Widget> screens = [
    const SearchHome(),
    const RideStatusScreen(),
    SelectCrationScreen(),
    const Center(child: Text('Notifications')),
    ProfileScreen(),
  ];

  Future<void> _handleTabChange(int newIndex) async {
    final loggedIn = await LocalCache.isUserLoggedIn();

    // Always allow Search
    if (newIndex == 0) {
      setState(() => index = 0);
      return;
    }

    // If user is NOT logged in, redirect to login
    if (!loggedIn) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PhoneNumberScreen()),
        ).then((value) async {
          // When returning from login, check login status again
          final loggedInAfter = await LocalCache.isUserLoggedIn();
          if (loggedInAfter) {
            setState(() => index = newIndex); // now allow navigation
          }
        });
      }
      return;
    }

    // If logged in, allow navigation
    setState(() => index = newIndex);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false, // Prevent FAB from moving on keyboard open
      body: screens[index],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 45, // distance from bottom
            left: MediaQuery.of(context).size.width / 2 - 28, // center FAB, radius=28
            child: FloatingActionButton(
              onPressed: () => _handleTabChange(2),
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 32),
            ),
          ),
        ],
      ),

      bottomNavigationBar: CurvedNavBar(
        currentIndex: index == 2 ? 0 : (index > 2 ? index - 1 : index),
        onTap: (i) {
          final newIndex = i >= 2 ? i + 1 : i; // skip FAB
          _handleTabChange(newIndex);
        },
        items: [
          CurvedNavItem(
            svgAsset: 'assets/images/search.svg',
            label: 'Search',
            activeColor: scheme.primary,
          ),
          CurvedNavItem(
            svgAsset: 'assets/images/tripcom.svg',
            label: 'My Trips',
            activeColor: scheme.primary,
          ),
          CurvedNavItem(
            svgAsset: 'assets/images/notificationsvgrepocom.svg',
            label: 'Notifications',
            activeColor: scheme.primary,
          ),
          CurvedNavItem(
            svgAsset: 'assets/images/profileicon.svg',
            label: 'Profile',
            activeColor: scheme.primary,
          ),
        ],
      ),
    );
  }
}
