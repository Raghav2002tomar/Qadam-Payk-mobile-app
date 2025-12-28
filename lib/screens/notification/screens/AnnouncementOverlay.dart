import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/translate_provider.dart';
import '../model/AppNotificationModel.dart';

class AnnouncementOverlay extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onClose;
  final VoidCallback onTap;

  const AnnouncementOverlay({
    super.key,
    required this.notification,
    required this.onClose,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          /// 🌫 BLURRED BACKGROUND
          GestureDetector(
            onTap: onClose,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                color: Colors.black.withOpacity(0.45),
              ),
            ),
          ),

          /// 🎯 CENTER CARD
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.88,
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: onTap,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 🖼 IMAGE
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(22),
                            ),
                            child: Image.network(
                              "https://qadampayk.com/assets/banner/${notification.image}" ??
                                  "https://upload.wikimedia.org/wikipedia/commons/a/a3/Image-not-found.png",
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),

                          /// ❌ CLOSE BUTTON
                          Positioned(
                            top: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: onClose,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      /// 📰 CONTENT
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              notification.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),

                            /// 👉 CTA
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  context.watch<TranslateProvider>().t('txt_tap_to_read_more'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


AppNotification? getLatestUnseenNews(
    List<AppNotification> notifications,
    List<int> seenIds,
    ) {
  final news = notifications
      .where((n) =>
  (n.type == 99 || n.type == 100) &&
      !seenIds.contains(n.id))
      .toList();

  if (news.isEmpty) return null;

  // Assuming latest is first OR sort by date if needed
  news.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return news.first;
}
