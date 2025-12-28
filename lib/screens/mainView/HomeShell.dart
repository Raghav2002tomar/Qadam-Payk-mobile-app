import 'package:bla_bla_car/screens/mainView/provide/ChatProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../service/local_cache.dart';
import '../auth/SignInScreen.dart';
import '../notification/controller/NotificationController.dart';
import '../notification/model/AppNotificationModel.dart';
import '../notification/screens/AnnouncementOverlay.dart';
import '../notification/screens/NotificationScreen.dart';
import '../story/screens/story_main_view.dart';
import 'CurvedNavItem.dart';
import 'ProfileScreen/ProfileScreen.dart';
import 'chat/ChatListScreen.dart';
import 'create/Create_selection.dart';
import '../mainView/search/Search_Screen.dart';
import 'mytrip/MyTripsScreen.dart';
import '../../providers/translate_provider.dart';
class HomeShell extends StatefulWidget {
    final int initialIndex;

    const HomeShell({super.key, this.initialIndex = 0});

    @override
    State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
    int index = 0;
    late List<Widget> screens;
    AppNotification? _announcement;
    List<int> _seenIds = [];

    final GlobalKey<DragFloatingButtonState> fabKey = GlobalKey();

    @override
    void initState() {
        super.initState();
        index = widget.initialIndex;
        WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadAnnouncement();
        });
        Provider.of<ChatProvider>(context, listen: false)
            .fetchConversations(context);
    }


    Future<void> _loadAnnouncement() async {
        _seenIds = await LocalCachenotification.getSeenNotifications();

        final token = await LocalCache.getToken();
        final notifications =
        await NotificationService.fetchNotifications(token!);

        final latest =
        getLatestUnseenNews(notifications, _seenIds);

        if (latest != null) {
            setState(() => _announcement = latest);
        }
    }

    @override
    void didChangeDependencies() {
        super.didChangeDependencies();
        screens = [
            const SearchHome(),
            MyTripsScreen(),
            SelectCrationScreen(status: false),
            Chatlistscreen(),
            ProfileScreen(),
        ];
    }

    @override
    Widget build(BuildContext context) {
        final scheme = Theme.of(context).colorScheme;

        return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
                // fabKey.currentState?.hideBigButton(); // 🔥 TAP ANYWHERE = HIDE BIG
            },
            child: Scaffold(
                extendBody: true,
                body: Stack(
                    children: [

                        screens[index],

                        /// ANNOUNCEMENT ON TOP
                        if (_announcement != null)
                            AnnouncementOverlay(
                                notification: _announcement!,
                                onClose: () async {
                                    await LocalCachenotification.markAsSeen(_announcement!.id);
                                    setState(() => _announcement = null);
                                },
                                onTap: () async {
                                    await LocalCachenotification.markAsSeen(_announcement!.id);
                                    setState(() => _announcement = null);

                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const NotificationScreen(),
                                        ),
                                    );
                                },
                            ),
                        /// 🔥 Always visible draggable button on edge
                        // DragFloatingButton(
                        //     key: fabKey,
                        //     onTap: () {
                        //         setState(() => index = 0);
                        //     },
                        // ),
                    ],
                ),

                floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
                floatingActionButton: FloatingActionButton(
                    onPressed: () => _handleTabChange(2),
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    shape: const CircleBorder(),
                    child: const Icon(Icons.add, size: 32),
                ),

                bottomNavigationBar: CurvedNavBar(
                    currentIndex: index == 2 ? 0 : (index > 2 ? index - 1 : index),
                    onTap: (i) {
                        final newIndex = i >= 2 ? i + 1 : i;
                        _handleTabChange(newIndex);
                    },
                    items: [
                        CurvedNavItem(
                            svgAsset: 'assets/images/search.svg',
                            label: context.watch<TranslateProvider>().t('txt_search'),
                            activeColor: scheme.primary),
                        CurvedNavItem(
                            svgAsset: 'assets/images/tripcom.svg',
                            label: context.watch<TranslateProvider>().t('txt_trips'),
                            activeColor: scheme.primary),
                        CurvedNavItem(
                            svgAsset: 'assets/images/chat.svg',
                            label: context.watch<TranslateProvider>().t('txt_chats'),
                            activeColor: scheme.primary,
                            badgeCount: context.watch<ChatProvider>().totalUnread, // <-- shows unread count
                        ),
                        CurvedNavItem(
                            svgAsset: 'assets/images/profileicon.svg',
                            label: context.watch<TranslateProvider>().t('txt_profile'),
                            activeColor: scheme.primary),
                    ],
                ),
            ),
        );
    }

    Future<void> _handleTabChange(int newIndex) async {
        final loggedIn = await LocalCache.isUserLoggedIn();

        if (newIndex == 0) {
            setState(() => index = 0);
            return;
        }

        if (!loggedIn) {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PhoneNumberScreen()),
            ).then((_) async {
                if (await LocalCache.isUserLoggedIn()) {
                    setState(() => index = newIndex);
                }
            });
            return;
        }

        setState(() => index = newIndex);
    }
}
class DragFloatingButton extends StatefulWidget {
    final VoidCallback onTap;

    const DragFloatingButton({super.key, required this.onTap});

    @override
    State<DragFloatingButton> createState() => DragFloatingButtonState();
}

class DragFloatingButtonState extends State<DragFloatingButton> {
    Offset position = const Offset(330, 500); // default (right side, bottom area)

    @override
    void didChangeDependencies() {
        super.didChangeDependencies();
        final screen = MediaQuery.of(context).size;

        // ALWAYS place button on the right side, bottom 200px
        position = Offset(
            screen.width - 50,   // right side
            screen.height - 180, // bottom offset
        );
    }

    @override
    Widget build(BuildContext context) {
        final screen = MediaQuery.of(context).size;

        return Positioned(
            left: position.dx,
            top: position.dy,
            child: GestureDetector(
                onPanUpdate: (details) {
                    setState(() {
                        position += details.delta;

                        /// Keep inside screen
                        final btnSize = 60.0;
                        position = Offset(
                            position.dx.clamp(0, screen.width - btnSize),
                            position.dy.clamp(80, screen.height - btnSize - 20),
                        );
                    });
                },

                onPanEnd: (_) {
                    setState(() {
                        /// SNAP LEFT / RIGHT EDGE
                        if (position.dx > screen.width / 2) {
                            position = Offset(screen.width - 60, position.dy);
                        } else {
                            position = Offset(10, position.dy);
                        }
                    });
                },

                child: _floatingButton(),
            ),
        );
    }

    Widget _floatingButton() {
        final cs = Theme.of(context).colorScheme;

        return Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
                boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                    ),
                ],
            ),
            child:  InkWell(onTap: (){
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => StoryMainView(),
                    ),
                );
            },
                child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Colors.white, Colors.grey.shade200],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                            BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: Offset(0, 4),
                            ),
                        ],
                    ),
                    child: Image.asset(
                        "assets/images/play_button.png",
                        height: 30,
                        // color: Colors.white, // optional (makes icon white)
                    ),
                ),
            )
        );
    }
}
