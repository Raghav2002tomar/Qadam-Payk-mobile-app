import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../service/local_cache.dart';
import '../../../providers/translate_provider.dart';
import '../provide/ChatProvider.dart';
import 'ChatConversationScreen.dart';
import '../../../service/colors.dart';

class Chatlistscreen extends StatefulWidget {
  const Chatlistscreen({super.key});

  @override
  State<Chatlistscreen> createState() => _ChatlistscreenState();
}

class _ChatlistscreenState extends State<Chatlistscreen> with RouteAware {

  @override
  void initState() {
    super.initState();
    // Fetch conversations after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).fetchConversations(context);
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date).inDays;

      if (diff == 0 && date.day == now.day) {
        return "Today ${DateFormat.jm().format(date)}";
      } else if (diff == 1 || (now.day - date.day == 1 && now.month == date.month)) {
        return "Yesterday ${DateFormat.jm().format(date)}";
      } else {
        return DateFormat("dd MMM, hh:mm a").format(date);
      }
    } catch (e) {
      return dateStr ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${context.watch<TranslateProvider>().t('txt_chats')}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: AppTheme.activeGreen,
      ),
      body: chatProvider.loading
          ? const Center(child: CircularProgressIndicator())
          : chatProvider.conversations.isEmpty
          ?  Center(child: Text("${context.watch<TranslateProvider>().t('txt_no_conversation_found')}"))
          : ListView.separated(
        itemCount: chatProvider.conversations.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final convo = chatProvider.conversations[index];
          final imageUrl = convo['other_user_image'] != null
              ? "https://qadampayk.com/assets/profile_image/${convo['other_user_image']}"
              : null;

          return ListTile(
            leading: CircleAvatar(
              radius: 26,
              backgroundImage: imageUrl != null
                  ? NetworkImage(imageUrl)
                  : const AssetImage("assets/images/default_avatar.png") as ImageProvider,
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    convo['other_user_name'] ?? "Unknown User",
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatDate(convo['last_message_time']),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            subtitle: Text(
              convo['last_message'] ?? "${context.watch<TranslateProvider>().t('txt_no_message_yet')}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            trailing: (convo['unread_count'] ?? 0) > 0
                ? CircleAvatar(
              radius: 12,
              backgroundColor: Colors.red,
              child: Text(
                convo['unread_count'].toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
                : null,
            onTap: () async {
              final conversationId = convo['conversation_id'];
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatConversationScreen(
                    conversationId: conversationId,
                    conversationTitle: convo['other_user_name'] ?? "Chat",
                  ),
                ),
              );

              // Mark as read after returning from chat
              chatProvider.markConversationRead(conversationId);
            },
          );
        },
      ),
    );
  }
}
