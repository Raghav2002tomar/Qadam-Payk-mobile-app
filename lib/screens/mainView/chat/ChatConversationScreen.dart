import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../service/colors.dart'; // Your import

class ChatConversationScreen extends StatefulWidget {
  final String conversationTitle; // e.g., "Chat with Raghav"

  const ChatConversationScreen({super.key, required this.conversationTitle});

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    // Sample messages: {'text': String, 'isSentByMe': bool, 'timestamp': String}
    {'text': 'Hi, is this product still available?', 'isSentByMe': true, 'timestamp': '11:20 PM'},
    {'text': 'Yes, it is! What size do you need?', 'isSentByMe': false, 'timestamp': '11:21 PM'},
    {'text': 'Medium, please. Any discounts?', 'isSentByMe': true, 'timestamp': '11:22 PM'},
    {'text': 'Sure, use code SAVE10 for 10% off.', 'isSentByMe': false, 'timestamp': '11:23 PM'},
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add({
          'text': _messageController.text,
          'isSentByMe': true,
          'timestamp': '${TimeOfDay.now().hour}:${TimeOfDay.now().minute} ${TimeOfDay.now().period == DayPeriod.am ? 'AM' : 'PM'}',
        });
        _messageController.clear();
      });
      // TODO: Add logic to send message via API or backend
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: const AssetImage('assets/images/raghav_avatar.png'), // Replace with your asset or NetworkImage for Raghav's profile
              backgroundColor: AppTheme.seedSecondary,
            ),
            const SizedBox(width: 12.0),
            Text(
              widget.conversationTitle,
              style: GoogleFonts.poppins(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Icon(Icons.more_vert),
          SizedBox(width: 4,),
        ],
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      backgroundColor: AppTheme.cardBackground, // Light background for the screen
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isSentByMe = message['isSentByMe'];
                return Align(
                  alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: isSentByMe
                              ? AppTheme.seedPrimary // Sent messages in primary green
                              : AppTheme.seedSecondary.withOpacity(0.2), // Received in light secondary
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
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          message['text'],
                          style: GoogleFonts.poppins(
                            color: isSentByMe ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        message['timestamp'],
                        style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // IconButton(
                //   icon: const Icon(Icons.attach_file, color: AppTheme.textSecondary),
                //   onPressed: () {
                //     // TODO: Handle attachment (e.g., image picker)
                //   },
                // ),
                const SizedBox(width: 4.0),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: GoogleFonts.poppins(color: AppTheme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: AppTheme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: AppTheme.seedPrimary, width: 2.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      filled: true,
                      fillColor: AppTheme.cardBackground,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.seedPrimary, // Send button in primary green
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12.0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
