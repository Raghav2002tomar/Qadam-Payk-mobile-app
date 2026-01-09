import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../api_service/logger.dart';
import '../../../providers/translate_provider.dart' show TranslateProvider;
import '../../../service/bad_words.dart';
import '../../../service/colors.dart';
import '../../../service/local_cache.dart';

class ChatConversationScreen extends StatefulWidget {
  final String conversationTitle;
  final int conversationId;

  const ChatConversationScreen({
    super.key,
    required this.conversationTitle,
    required this.conversationId,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<dynamic> _messages = [];
  bool _loading = true;
  bool _isSending = false;
  Timer? _refreshTimer;
  int? _otherUserId; // get this from messages API
  bool _isUserBlocked = false;


  bool _containsBadWord(String message) {
    final lowerMessage = message.toLowerCase();

    for (final badWord in badWordsList) {
      if (lowerMessage.contains(badWord)) {
        return true;
      }
    }
    return false;
  }
  final List<String> reportReasons = [
    "Spam / Advertising",
    "Harassment or Abuse",
    "Hate Speech",
    "Sexual Content",
    "Scam / Fraud",
    "Other",
  ];


  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _markAsRead(); // 👈 Mark conversation as read on open

    // Poll for new messages every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchMessages(silent: true);
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollToBottom();
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 🔹 Scroll to bottom smoothly
  void _scrollToBottom({bool animated = true}) {
    if (_scrollController.hasClients) {
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  /// 🔹 Format time
  String _formatTime(String? timeStr) {
    if (timeStr == null) return "";
    try {
      final dt = DateTime.parse(timeStr);
      return DateFormat("hh:mm a").format(dt);
    } catch (e) {
      return timeStr;
    }
  }

  /// 🔹 Fetch Messages from API
  Future<void> _fetchMessages({bool silent = false}) async {
    final token = await LocalCache.getToken();

    try {
      final url = Uri.parse("https://qadampayk.com/api/chat/messages");
      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: {
          "conversation_id": widget.conversationId.toString(),
        },
      );

      if (response.statusCode == 200) {
        // ✅ Fix UTF-8 decoding for Tajik/Russian text
        final result = json.decode(utf8.decode(response.bodyBytes));

        if (result['status'] == true) {
          final newMessages = result['messages'] as List;

          if (newMessages.isNotEmpty) {
            final lastMsg = newMessages.last;
            _otherUserId = lastMsg['sender_id'];
            _findOtherUserId();
            _checkBlockedStatus();
          }

          final hasNewMessages = newMessages.length > _messages.length;

          if (mounted) {
            setState(() {
              _messages = newMessages;
              _loading = false;
            });
          }

          if (hasNewMessages) {
            _markAsRead();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
        }
      } else {
        appLog("Failed to load messages: ${response.body}");
        if (!silent && mounted) setState(() => _loading = false);
      }
    } catch (e) {
      appLog("Error fetching messages: $e");
      if (!silent && mounted) setState(() => _loading = false);
    }
  }
  Future<void> _checkBlockedStatus() async {
    if (_otherUserId == null) return;

    final token = await LocalCache.getToken();
    final url = Uri.parse("https://qadampayk.com/api/blocked-users");

    try {
      final response = await http.get(url, headers: {
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final list = result["data"] as List;

        setState(() {
          _isUserBlocked = list.any((u) => u["blocked_user_id"] == _otherUserId);
        });
      }
    } catch (e) {
      appLog("Check blocked error: $e");
    }
  }

  /// 🔹 Send Message
  // Future<void> _sendMessage() async {
  //   if (_messageController.text.trim().isEmpty || _isSending) return;
  //
  //   final messageText = _messageController.text.trim();
  //   _messageController.clear();
  //   _focusNode.unfocus();
  //
  //   setState(() => _isSending = true);
  //
  //   final token = await LocalCache.getToken();
  //
  //   try {
  //     final url = Uri.parse("https://qadampayk.com/api/chat/send");
  //     final request = http.MultipartRequest("POST", url)
  //       ..headers["Authorization"] = "Bearer $token"
  //       ..fields["conversation_id"] = widget.conversationId.toString()
  //       ..fields["message"] = messageText
  //       ..fields["type"] = "text";
  //
  //     final response = await request.send();
  //
  //     if (response.statusCode == 200) {
  //       final resBody = await response.stream.bytesToString();
  //       final result = json.decode(resBody);
  //
  //       if (result['status'] == true) {
  //         // Add new message locally immediately
  //         setState(() {
  //           _messages.add({
  //             'message': result['message_data']['message'],
  //             'is_me': true,
  //             'send_at': result['message_data']['send_at'],
  //           });
  //         });
  //
  //         // 🔹 Scroll to bottom after sending
  //         WidgetsBinding.instance.addPostFrameCallback((_) {
  //           _scrollToBottom();
  //         });
  //       }
  //     }
  //   } catch (e) {
  //     appLog("Send message error: $e");
  //     // Optionally show error to user
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Failed to send message')),
  //       );
  //     }
  //   } finally {
  //     setState(() => _isSending = false);
  //   }
  // }
  Future<void> _sendMessage() async {
    final rawMessage = _messageController.text.trim();

    if (rawMessage.isEmpty || _isSending) return;

    // ✅ Check bad words
    if (_containsBadWord(rawMessage)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<TranslateProvider>().t('txt_bad_word_warning')
                ?? "Please avoid using offensive words.",
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (_isUserBlocked) return;

      return; // ❌ Do not send message
    }

    final messageText = rawMessage;
    _messageController.clear();
    _focusNode.unfocus();

    setState(() => _isSending = true);

    final token = await LocalCache.getToken();

    try {
      final url = Uri.parse("https://qadampayk.com/api/chat/send");
      final request = http.MultipartRequest("POST", url)
        ..headers["Authorization"] = "Bearer $token"
        ..fields["conversation_id"] = widget.conversationId.toString()
        ..fields["message"] = messageText
        ..fields["type"] = "text";

      final response = await request.send();

      if (response.statusCode == 200) {
        final resBody = await response.stream.bytesToString();
        final result = json.decode(resBody);

        if (result['status'] == true) {
          setState(() {
            _messages.add({
              'message': result['message_data']['message'],
              'is_me': true,
              'send_at': result['message_data']['send_at'],
            });
          });

          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }
      }
    } catch (e) {
      appLog("Send message error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }



  /// ✅ Mark conversation as read
  Future<void> _markAsRead() async {
    final token = await LocalCache.getToken();
    final url = Uri.parse("https://qadampayk.com/api/chat/mark-read");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "conversation_id": widget.conversationId,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result["status"] == true) {
          appLog("✅ Conversation marked as read");
        } else {
          appLog("⚠️ Mark read failed: ${result["message"]}");
        }
      } else {
        appLog("❌ Mark read API error: ${response.body}");
      }
    } catch (e) {
      appLog("❌ Mark read exception: $e");
    }
  }
  void _findOtherUserId() {
    for (final msg in _messages) {
      if (msg['is_me'] == false && msg['sender_id'] != null) {
        _otherUserId = msg['sender_id'];
        return;
      }
    }
  }


  Future<void> _blockUser() async {
    if (_otherUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No user to block.")),
      );
      return;
    }

    final token = await LocalCache.getToken();
    final url = Uri.parse("https://qadampayk.com/api/block-user");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"blocked_user_id": _otherUserId}),
      );

      if (response.statusCode == 200) {
        setState(() => _isUserBlocked = true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<TranslateProvider>().t('txt_user_blocked_success')
                  ?? "User blocked successfully",
            ),
          ),
        );
      }
    } catch (e) {
      appLog("Block user error: $e");
    }
  }
  Future<void> _unblockUser() async {
    if (_otherUserId == null) return;
    final token = await LocalCache.getToken();

    final url = Uri.parse("https://qadampayk.com/api/unblock-user");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"blocked_user_id": _otherUserId}),
      );

      if (response.statusCode == 200) {
        setState(() => _isUserBlocked = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                context.read<TranslateProvider>().t('txt_unblock_user') ?? "User unblocked successfully"
            ),
          ),
        );

      }
    } catch (e) {
      appLog("Unblock user error: $e");
    }
  }

  void _showMessageActions(dynamic message) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final reason in reportReasons)
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.red),
                  title: Text(reason),
                  onTap: () {
                    Navigator.pop(context);
                    _reportMessage(message['id'], reason);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
  Future<void> _reportMessage(int messageId, String reason) async {
    final token = await LocalCache.getToken();
    final url = Uri.parse("https://qadampayk.com/api/chat/report-message");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "message_id": messageId,
          "reason": reason,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<TranslateProvider>().t('txt_report_success')
                  ?? "Message reported successfully.",
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      appLog("Report error: $e");
    }
  }

  List<String> getReportReasons(BuildContext context) {
    final t = context.read<TranslateProvider>();

    return [
      t.t('reason_spam') ?? "Spam / Advertising",
      t.t('reason_harassment') ?? "Harassment or Abuse",
      t.t('reason_hate') ?? "Hate Speech",
      t.t('reason_sexual') ?? "Sexual Content",
      t.t('reason_scam') ?? "Scam / Fraud",
      t.t('reason_other') ?? "Other",
    ];
  }


  void _showReportChatDialog() {
    final reasons = getReportReasons(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.read<TranslateProvider>().t('txt_select_report_reason') ?? "Select Report Reason",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              const Divider(),
              for (final reason in reasons)
                ListTile(
                  leading: const Icon(Icons.report_gmailerrorred, color: Colors.red),
                  title: Text(reason, style: GoogleFonts.notoSans(fontSize: 15)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmReportChat(reason);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
  void _confirmReportChat(String reason) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          context.read<TranslateProvider>().t('txt_report_chat') ?? "Report Chat",
        ),
        content: Text(
          "${context.read<TranslateProvider>().t('txt_confirm_report_reason') ?? "You are reporting this chat for:"}\n\n$reason",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.read<TranslateProvider>().t('txt_cancel') ?? "Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _reportChat(reason);
            },
            child: Text(
              context.read<TranslateProvider>().t('txt_report_chat') ?? "Report",
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reportChat(String reason) async {
    final token = await LocalCache.getToken();
    final url = Uri.parse("https://qadampayk.com/api/chat/report-chat");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "conversation_id": widget.conversationId,
          "reason": reason, // ✅ ADD THIS
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<TranslateProvider>().t('txt_report_success')
                  ?? "Chat reported successfully.",
            ),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    } catch (e) {
      appLog("Report chat error: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              child: Icon(Icons.person,color: Colors.grey,)
              // backgroundImage: AssetImage('assets/images/raghav_avatar.png'),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                widget.conversationTitle,
                style: GoogleFonts.poppins(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == "report") _showReportChatDialog();
                if (value == "block") _blockUser();
                if (value == "unblock") _unblockUser();

              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: "report",
                  child: Text(
                    Provider.of<TranslateProvider>(context, listen: false).t('txt_report_chat')
                        ?? "Report Chat",
                  ),
                ),
                PopupMenuItem(
                  value: _isUserBlocked ? "unblock" : "block",
                  child: Text(_isUserBlocked
                      ? context.read<TranslateProvider>().t('txt_unblock_user') ?? "Unblock User"
                      : context.read<TranslateProvider>().t('txt_block_user') ?? "Block User"
                  ),
                  // child: Text(
                  //   Provider.of<TranslateProvider>(context, listen: false).t('txt_block_user')
                  //       ?? "Block User",
                  // ),
                ),
              ],
            ),

        ],

        backgroundColor: AppTheme.cardBackground,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        elevation: 1,
      ),
      backgroundColor: AppTheme.cardBackground,
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${context.watch<TranslateProvider>().t('txt_start_conversation')}',
                    style: GoogleFonts.notoSans(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${context.watch<TranslateProvider>().t('txt_start_conversation')}',
                    style: GoogleFonts.notoSans(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isSentByMe = message['is_me'] ?? false;
                final msgText = message['message'] ?? "";
                final msgTime = message['send_at'] ?? "";

                return Align(
                  alignment: isSentByMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: isSentByMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth:
                          MediaQuery.of(context).size.width * 0.7,
                        ),
                        margin:
                        const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: isSentByMe
                              ? AppTheme.seedPrimary
                              : Colors.grey.shade200,
                          borderRadius: isSentByMe
                              ? const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          )
                              : const BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          msgText,
                          style: GoogleFonts.notoSans(
                            color: isSentByMe
                                ? Colors.white
                                : AppTheme.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4.0),
                        child: Text(
                          _formatTime(msgTime),
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 11.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                    ],
                  ),
                );
              },
            ),
          ),
          _isUserBlocked
              ? Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    context.read<TranslateProvider>().t('txt_user_is_blocked') ?? "User is blocked"
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: _unblockUser,
                  child: Text(
                      context.read<TranslateProvider>().t('txt_unblock') ?? "Unblock"
                  ),
                ),

              ],
            ),
          )
              : _buildMessageInput()

        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: "${context.watch<TranslateProvider>().t('txt_type_message')}",
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 12.0),
                  filled: true,
                  fillColor: AppTheme.cardBackground,
                ),
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
            const SizedBox(width: 8.0),
            _isSending
                ? Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.seedPrimary.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
                : IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.seedPrimary,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}