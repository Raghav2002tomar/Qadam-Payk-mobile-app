import 'package:bla_bla_car/screens/mainView/provide/ChatProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../service/local_cache.dart';
import '../auth/SignInScreen.dart';
import 'CurvedNavItem.dart';
import 'ProfileScreen/ProfileScreen.dart';
import 'chat/ChatListScreen.dart';
import 'create/Add_vehical.dart';
import 'create/Create_selection.dart';
import '../mainView/search/Search_Screen.dart';
import 'mytrip/MyTripsScreen.dart';
import 'mytrip/RideStatusScreen.dart';
import '../../providers/translate_provider.dart';

// class HomeShell extends StatefulWidget {
//     const HomeShell({super.key});

class HomeShell extends StatefulWidget {
    final int initialIndex; // <-- ADD THIS

    const HomeShell({super.key, this.initialIndex = 0}); // <-- DEFAULT 0 (Search)



    @override
    State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
    int index = 0;
    late List<Widget> screens;
    @override
    void didChangeDependencies() {
        super.didChangeDependencies();

        screens = [
            const SearchHome(),
            // const RideStatusScreen(),
            MyTripsScreen(),
            SelectCrationScreen(status: false,),
            Chatlistscreen(),
            // Center(child: Text(context.watch<TranslateProvider>().t('txt_notifications'))),
            ProfileScreen(),
        ];
    }


    @override
    void initState() {
        super.initState();
        index = widget.initialIndex; // <-- SET DEFAULT TAB HERE
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        chatProvider.fetchConversations(context);
    }


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
                    MaterialPageRoute(builder: (_) => const PhoneNumberScreen())
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
                            child: const Icon(Icons.add, size: 32)
                        )
                    )
                ]
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
                        label: context.watch<TranslateProvider>().t('txt_search'),
                        activeColor: scheme.primary
                    ),
                    CurvedNavItem(
                        svgAsset: 'assets/images/tripcom.svg',
                        label: context.watch<TranslateProvider>().t('txt_trips'),
                        activeColor: scheme.primary
                    ),
                    CurvedNavItem(
                        svgAsset: 'assets/images/chat.svg',
                        label: context.watch<TranslateProvider>().t('txt_chats'),
                        activeColor: scheme.primary,
                        badgeCount: context.watch<ChatProvider>().totalUnread, // <-- shows unread count
                    ),



                    CurvedNavItem(
                        svgAsset: 'assets/images/profileicon.svg',
                        label: context.watch<TranslateProvider>().t('txt_profile'),
                        activeColor: scheme.primary
                    )
                ]
            )
        );
    }
}
