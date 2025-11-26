import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import '../../../service/local_cache.dart';
import '../../auth/SignInScreen.dart';
import '../chat/ChatConversationScreen.dart';
import 'package:http/http.dart' as http;

class ChatProvider extends ChangeNotifier {
  List<dynamic> _conversations = [];
  int _totalUnread = 0;
  bool _loading = true;

  List<dynamic> get conversations => _conversations;
  int get totalUnread => _totalUnread;
  bool get loading => _loading;

  ChatProvider() {
    fetchConversations(context); // Auto fetch on provider init
  }

  /// Fetch all conversations
  Future<void> fetchConversations(context) async {

    _loading = true;
    notifyListeners();

    final token = await LocalCache.getToken();

    try {
      final url = Uri.parse("https://qadampayk.com/api/chat/conversations");
      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == true) {
          _conversations = result['conversations'];
          _totalUnread = _conversations.fold(
            0,
                (sum, convo) => sum + ((convo['unread_count'] ?? 0) as int),
          );
        }
      } else if (response.statusCode == 401) {
        throw Exception("Unauthorized: Invalid or expired token");
      } else if (response.statusCode == 403) {
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PhoneNumberScreen()),
          );
        }
      } else {
        throw Exception(
            "Server Error: ${response.statusCode} - ${response.reasonPhrase}");
      }
    } on SocketException {
      debugPrint("No Internet connection");
    } catch (e) {
      debugPrint("Unexpected error fetching conversations: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Mark a conversation as read
  void markConversationRead(int conversationId) {
    final index = _conversations.indexWhere(
            (c) => c['conversation_id'] == conversationId);
    if (index != -1 && (_conversations[index]['unread_count'] ?? 0) > 0) {
      _totalUnread -= (_conversations[index]['unread_count'] ?? 0) as int;
      _conversations[index]['unread_count'] = 0;
      notifyListeners();
    }
  }

  /// Start chat with a user
  Future<void> startChat({
    required BuildContext context,
    required int otherUserId,
    required String userName,
  }) async {
    final token = await LocalCache.getToken();
    try {
      final url = Uri.parse("https://qadampayk.com/api/chat/start");
      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({"other_user_id": otherUserId}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == true) {
          final conversation = result['conversation'];
          final conversationId = conversation['id'];

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatConversationScreen(
                conversationId: conversationId,
                conversationTitle: userName,
              ),
            ),
          ).then((_) {
            // Mark read when returning from chat
            markConversationRead(conversationId);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Failed to start chat')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to start chat")),
        );
      }
    } catch (e) {
      debugPrint("Error starting chat: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    }
  }
}
