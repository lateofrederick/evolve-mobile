import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';

class Message {
  final String text;
  final bool isUser;
  Message({required this.text, required this.isUser});
}

class AiAssistantModal extends StatefulWidget {
  // If opened from a specific visit, we know the Client ID.
  // If from Home, we might need to ask "Which client?".
  // For MVP, let's assume we are querying the "Next Up" client or generic context.
  final int clientId;

  const AiAssistantModal({this.clientId = 1, super.key}); // Default ID 1 for demo

  @override
  State<AiAssistantModal> createState() => _AiAssistantModalState();
}

class _AiAssistantModalState extends State<AiAssistantModal> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiClient _apiClient = ApiClient(); // Should use Provider in real app

  final List<Message> _messages = [
    Message(text: "Hello! I have access to the care plans and history. What do you need to know?", isUser: false),
  ];

  bool _isLoading = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(Message(text: text, isUser: true));
      _isLoading = true;
      _controller.clear();
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    try {
      // CALL THE BACKEND
      final response = await _apiClient.post('/assistant/query', body: {
        "client_id": widget.clientId,
        "query": text
      });

      setState(() {
        _messages.add(Message(text: response['response'], isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(Message(text: "Error connecting to CareFlow Brain: $e", isUser: false));
        _isLoading = false;
      });
    }

    // Scroll again after response
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Keyboard avoidance logic
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.purple.shade100, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(LucideIcons.sparkles, color: Colors.purple, size: 20)
                      ),
                      const SizedBox(width: 12),
                      const Text("CareFlow Assistant", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text("AI-Powered • Confidential • Internal Use Only", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  const Divider(height: 32),
                ],
              ),
            ),

            // Chat Area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: msg.isUser ? AppTheme.primary : Colors.grey.shade100,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: msg.isUser ? const Radius.circular(16) : const Radius.circular(4),
                          bottomRight: msg.isUser ? const Radius.circular(4) : const Radius.circular(16),
                        ),
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(color: msg.isUser ? Colors.white : AppTheme.textMain, height: 1.4),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Loading Indicator
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Thinking...", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),

            // Input Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Ask about medications, history...",
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.primary,
                    child: IconButton(
                      icon: const Icon(LucideIcons.send, color: Colors.white, size: 18),
                      onPressed: _sendMessage,
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