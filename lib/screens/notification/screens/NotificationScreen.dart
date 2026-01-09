
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../api_service/logger.dart';
import '../../../providers/translate_provider.dart';
import '../../../service/local_cache.dart';
import '../controller/NotificationController.dart';
import '../model/AppNotificationModel.dart';
import 'NewsDetailScreen.dart';
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<AppNotification>> _future;
  List<int> _seenIds = [];

  @override
  void initState() {
    super.initState();
    _loadSeen();
    _future = _loadNotifications();
  }

  Future<void> _loadSeen() async {
    _seenIds = await LocalCachenotification.getSeenNotifications();
    setState(() {});
  }


  Future<List<AppNotification>> _loadNotifications() async {
    final token = await LocalCache.getToken(); // your existing method
    return NotificationService.fetchNotifications(token!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.watch<TranslateProvider>().t('txt_notifications'),
        ),
        centerTitle: true,
      ),

      body: FutureBuilder<List<AppNotification>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return  Center(child: Text(      context.watch<TranslateProvider>().t('txt_something_went_wrong'),
            ));
          }

          final notifications = snapshot.data!;

          if (notifications.isEmpty) {
            return  Center(child: Text(      context.watch<TranslateProvider>().t('txt_no_notifications'),
            ));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];

              if (n.type == 99 || n.type == 100) {
                return _newsCard(context, n);
              } else {
                return _normalNotification(n);
              }
            },
          );
        },
      ),
    );
  }

  Widget _normalNotification(AppNotification n) {
    final isSeen = _seenIds.contains(n.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: isSeen ? 0.5 : 2,
      child: ListTile(
        dense: true,
        leading: Stack(
          children: [
            const Icon(Icons.notifications, size: 22),
            if (!isSeen)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              )
          ],
        ),
        title: Text(
          n.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSeen ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Text(
          n.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: isSeen ? Colors.grey : Colors.black87,
          ),
        ),
        trailing: Text(
          n.createdAt.substring(11, 16),
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        onTap: () async {
          await LocalCachenotification.markAsSeen(n.id);
          _loadSeen();
        },
      ),
    );
  }

  Widget _newsCard(BuildContext context, AppNotification n) {
    final isSeen = _seenIds.contains(n.id);
appLog("Qadam-Payk/public/assets/banner${n.image}");
    return InkWell(
      onTap: () async {
        await LocalCachenotification.markAsSeen(n.id);
        _loadSeen();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewsDetailScreen(notification: n),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: isSeen ? 1 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: Image.network(
                "https://qadampayk.com/assets/banner/${n.image}" ??
                    "https://upload.wikimedia.org/wikipedia/commons/a/a3/Image-not-found.png",
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isSeen)
                    Container(
                      margin: const EdgeInsets.only(right: 8, top: 6),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                            isSeen ? FontWeight.w500 : FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          n.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LocalCachenotification {
  static const _seenKey = "seen_notifications";

  static Future<List<int>> getSeenNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_seenKey) ?? [];
    return list.map((e) => int.parse(e)).toList();
  }

  static Future<void> markAsSeen(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_seenKey) ?? [];

    if (!list.contains(id.toString())) {
      list.add(id.toString());
      await prefs.setStringList(_seenKey, list);
    }
  }
}
