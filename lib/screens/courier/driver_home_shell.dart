// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:provider/provider.dart';
// import '../../providers/translate_provider.dart';
// import '../mainView/CurvedNavItem.dart';
// import '../mainView/ProfileScreen/ProfileScreen.dart';
// import '../mainView/chat/ChatListScreen.dart';
// import 'all_order_list_screen.dart';
// import 'driver_ride_feed_screen.dart';
//
// class DriverHomeShell extends StatefulWidget {
//   const DriverHomeShell({super.key});
//
//   @override
//   State<DriverHomeShell> createState() => _DriverHomeShellState();
// }
//
// class _DriverHomeShellState extends State<DriverHomeShell> {
//   int index = 0;
//
//   late final List<Widget> screens = [
//     DriverRideFeedScreen(),
//     const ProfileScreen(),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;
//
//     return Scaffold(
//       extendBody: true,
//       body: Stack(
//         children: [
//           /// Current Screen
//           screens[index],
//
//           /// Draggable Chat Button
//           Positioned(
//             bottom: 90, // adjust if needed
//             left: 0,
//             right: 0,
//             child: Center(
//               child: DragFloatingChatButton(),
//             ),
//           ),        ],
//       ),
//
//       bottomNavigationBar: CurvedNavBar(
//         currentIndex: index,
//         onTap: (i) {
//           setState(() => index = i);
//         },
//         items: [
//           CurvedNavItem(
//             svgAsset: 'assets/images/courier.svg',
//             label: context.watch<TranslateProvider>().t('Order Feed'),
//             activeColor: scheme.primary,
//           ),
//           CurvedNavItem(
//             svgAsset: 'assets/images/profileicon.svg',
//             label: context.watch<TranslateProvider>().t('txt_profile'),
//             activeColor: scheme.primary,
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// /// ===============================
// /// DRAGGABLE FLOATING CHAT BUTTON
// /// ===============================
// class DragFloatingChatButton extends StatefulWidget {
//   const DragFloatingChatButton({super.key});
//
//   @override
//   State<DragFloatingChatButton> createState() =>
//       _DragFloatingChatButtonState();
// }
//
// class _DragFloatingChatButtonState
//     extends State<DragFloatingChatButton> {
//   Offset position = const Offset(300, 500);
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//
//     final screen = MediaQuery.of(context).size;
//
//     /// Initial position (bottom right)
//     position = Offset(
//       screen.width - 70,
//       screen.height - 180,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screen = MediaQuery.of(context).size;
//     final scheme = Theme.of(context).colorScheme;
//
//     return Positioned(
//       left: position.dx,
//       top: position.dy,
//       child: GestureDetector(
//         onPanUpdate: (details) {
//           setState(() {
//             position += details.delta;
//
//             const size = 60.0;
//
//             /// Keep inside screen
//             position = Offset(
//               position.dx.clamp(0, screen.width - size),
//               position.dy.clamp(
//                 80,
//                 screen.height - size - 90, // avoid bottom nav
//               ),
//             );
//           });
//         },
//         onPanEnd: (_) {
//           setState(() {
//             /// Snap left or right
//             if (position.dx > screen.width / 2) {
//               position = Offset(screen.width - 60, position.dy);
//             } else {
//               position = Offset(10, position.dy);
//             }
//           });
//         },
//         child: Container(
//           height: 55,
//           width: 55,
//           decoration: BoxDecoration(
//             color: scheme.primary,
//             shape: BoxShape.circle,
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.25),
//                 blurRadius: 10,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: InkWell(
//             borderRadius: BorderRadius.circular(50),
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => Chatlistscreen(),
//                 ),
//               );
//             },
//                child: Center(
//           child: SvgPicture.asset(
//           "assets/images/chat.svg",
//             width: 30,
//             height: 30,
//             colorFilter: const ColorFilter.mode(
//               Colors.white,
//               BlendMode.srcIn,
//             ),
//           ),
//         ),
//           ),
//         ),
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../providers/translate_provider.dart';
import '../mainView/CurvedNavItem.dart';
import '../mainView/ProfileScreen/ProfileScreen.dart';
import '../mainView/chat/ChatListScreen.dart';
import 'all_order_list_screen.dart';
import 'driver_ride_feed_screen.dart';

class DriverHomeShell extends StatefulWidget {
  const DriverHomeShell({super.key});

  @override
  State<DriverHomeShell> createState() => _DriverHomeShellState();
}

class _DriverHomeShellState extends State<DriverHomeShell> {
  int index = 0;
  int chatBadgeCount = 3; // Example badge count - replace with actual logic

  late final List<CurvedNavItem> navItems = [
    CurvedNavItem(
      svgAsset: 'assets/images/courier.svg',
      label: 'Order Feed',
    ),
    CurvedNavItem(
      svgAsset: 'assets/images/profileicon.svg',
      label: 'txt_profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final translator = context.watch<TranslateProvider>();

    return Scaffold(
      extendBody: true,
      body: screens[index],

      // Centered Chat Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Chatlistscreen(),
            ),
          );
        },
        backgroundColor: scheme.primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: SvgPicture.asset(
          "assets/images/chat.svg",
          width: 28,
          height: 28,
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: CurvedNavBar(
        currentIndex: index,
        onTap: (i) {
          setState(() => index = i);
        },
        items: [
          CurvedNavItem(
            svgAsset: 'assets/images/courier.svg',
            label: translator.t('Order Feed'),
            activeColor: scheme.primary,
          ),
          CurvedNavItem(
            svgAsset: 'assets/images/profileicon.svg',
            label: translator.t('txt_profile'),
            activeColor: scheme.primary,
            badgeCount: index == 1 ? null : chatBadgeCount, // Show badge on profile tab
          ),
        ],
      ),
    );
  }

  List<Widget> get screens => [
    DriverRideFeedScreen(),
    const ProfileScreen(),
  ];
}



/// Curved navigation bar item
class CurvedNavItem {
  final String svgAsset;
  final String label;
  final Color? activeColor;
  final int? badgeCount; // optional badge

  CurvedNavItem({
    required this.svgAsset,
    required this.label,
    this.activeColor,
    this.badgeCount,
  });
}

/// Curved navigation bar widget with center docked FAB support
class CurvedNavBar extends StatelessWidget {
  final List<CurvedNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final double height;
  final double notchRadius;

  const CurvedNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.height = 90, // Increased height from 80 to 90
    this.notchRadius = 30, // Slightly increased for better FAB fit
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final inactive = scheme.onSurfaceVariant.withOpacity(0.65);

    return BottomAppBar(
      height: height,
      color: Theme.of(context).bottomAppBarTheme.color ?? Colors.grey.shade200,
      surfaceTintColor: Theme.of(context).bottomAppBarTheme.surfaceTintColor,
      elevation: Theme.of(context).bottomAppBarTheme.elevation ?? 8,

      // This creates the circular notch for the FAB
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0, // Increased margin for better FAB spacing

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0), // Add horizontal padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final it = items[i];
            final active = i == currentIndex;
            final color = active ? (it.activeColor ?? scheme.primary) : inactive;

            return Expanded(
              child: _NavButton(
                svgAsset: it.svgAsset,
                label: it.label,
                color: color,
                active: active,
                badgeCount: it.badgeCount,
                onTap: () => onTap(i),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Nav button widget (SVG + label)
class _NavButton extends StatelessWidget {
  final String svgAsset;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  final int? badgeCount;

  const _NavButton({
    required this.svgAsset,
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12), // Increased vertical padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 26, // Increased from 22 to 26
                  width: 26, // Increased from 22 to 26
                  child: SvgPicture.asset(
                    svgAsset,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                    fit: BoxFit.contain,
                  ),
                ),

              ],
            ),
            // const SizedBox(height: 2), // Increased from 4 to 6
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith( // Changed from labelSmall to labelMedium
                color: color,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                fontSize: 11, // Increased from 10 to 11
                // height: 1.2, // Added line height for better spacing
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false, // Prevent text wrapping
            ),
          ],
        ),
      ),
    );
  }
}