
import 'package:flutter/material.dart';

import '../model/AppNotificationModel.dart';

class NewsDetailScreen extends StatelessWidget {
  final AppNotification notification;

  const NewsDetailScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          notification.type == 100 ? "News" : "Announcement",
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: notification.image != null
                      ? NetworkImage("https://qadampayk.com/assets/banner/${notification.image!}")
                      : const NetworkImage("https://upload.wikimedia.org/wikipedia/commons/a/a3/Image-not-found.png")
                  as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    notification.createdAt,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    notification.description,
                    style: const TextStyle(fontSize: 16),
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
