import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/services.dart'; // For clipboard functionality

class GeminiChatBot extends StatefulWidget {
  const GeminiChatBot({super.key});

  @override
  State<GeminiChatBot> createState() => _GeminiChatBotState();
}

class _GeminiChatBotState extends State<GeminiChatBot> {
  final TextEditingController _textController = TextEditingController();
  static const apiKey = ""; // Replace securely
  final model = GenerativeModel(model: "gemini-pro", apiKey: apiKey);
  final List<ModelMessage> messages = [];

  Future<void> sendMessage() async {
    final userMessage = _textController.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      messages.add(ModelMessage(
        isCode: false,
        isPrompt: true, 
        message: userMessage, 
        time: DateTime.now()));
    });
    _textController.clear();

    try {
      final content = [Content.text(userMessage)];
      final response = await model.generateContent(content);

      setState(() {
        messages.add(ModelMessage(
          isPrompt: false,
          message: response.text ?? "No response",
          isCode: _isCodeResponse(response.text ?? ""),
          time: DateTime.now(),
        ));
      });
    } catch (e) {
      setState(() {
        messages.add(ModelMessage(
            isPrompt: false,
            message: "Error: Unable to get a response.",
            isCode: false,
            time: DateTime.now()));
      });
    }
  }

  bool _isCodeResponse(String response) {
    return response.contains("import") || response.contains("class") || response.contains("function");
  }

  void clearChats() {
    setState(() {
      messages.clear();
    });
  }

  void clearPrompts() {
    setState(() {
      messages.removeWhere((message) => message.isPrompt);
    });
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Copied to clipboard")),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[100],
      appBar: AppBar(
        title: const Text("AI ChatBot"),
        centerTitle: true,
        backgroundColor: Colors.blue[100],
        elevation: 3,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: clearChats,
            tooltip: "Clear All Chats",
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: clearPrompts,
            tooltip: "Clear All Prompts",
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return UserPrompt(
                  message: message.message,
                  isPrompt: message.isPrompt,
                  isCode: message.isCode,
                  onCopy: message.isCode ? () => copyToClipboard(message.message) : null,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: "Enter a prompt here",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: sendMessage,
                    child: const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UserPrompt extends StatelessWidget {
  const UserPrompt({
    super.key,
    required this.message,
    required this.isPrompt,
    required this.isCode,
    this.onCopy,
  });

  final String message;
  final bool isPrompt;
  final bool isCode;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isPrompt ? Colors.green : Colors.grey,
        borderRadius: BorderRadius.circular(12),
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 16,
              color: isPrompt ? Colors.white : Colors.black,
            ),
          ),
          if (isCode && onCopy != null)
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text("Copy"),
              ),
            ),
        ],
      ),
    );
  }
}

class ModelMessage {
  final bool isPrompt;
  final String message;
  final bool isCode;
  final DateTime time;

  ModelMessage({
    required this.isPrompt,
    required this.message,
    required this.isCode,
    required this.time,
  });
}
