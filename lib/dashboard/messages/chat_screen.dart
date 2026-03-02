import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String name;
  const ChatScreen({super.key, required this.name});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const Color orange = Color(0xFFF5A623);

  final List<Map<String, dynamic>> messages = [
    {'me': false, 'text': 'وين وصل الطلب؟'},
    {'me': true, 'text': 'الطلب في الطريق 👍'},
    {'me': false, 'text': 'تمام شكراً'},
  ];

  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: orange,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final m = messages[i];
                return Align(
                  alignment:
                      m['me'] ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: m['me']
                          ? orange.withOpacity(0.9)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      m['text'],
                      style: TextStyle(
                        color: m['me'] ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالة...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: orange,
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;
                    setState(() {
                      messages.add({'me': true, 'text': controller.text});
                      controller.clear();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
