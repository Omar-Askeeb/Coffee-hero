// lib/chat_screen.dart
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_Msg> _msgs = <_Msg>[
    _Msg(fromMe: false, text: 'مرحباً! كيف نقدر نساعدك؟'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final t = _controller.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _msgs.add(_Msg(fromMe: true, text: t));
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('الدردشة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _msgs.length,
              itemBuilder: (context, i) {
                final m = _msgs[i];
                return Align(
                  alignment: m.fromMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: m.fromMe ? const Color(0xFFF5A623) : const Color(0xFFF3F4F8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(
                        color: m.fromMe ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.send, color: Color(0xFFF5A623)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالتك...',
                        filled: true,
                        fillColor: const Color(0xFFF3F4F8),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  const _Msg({required this.fromMe, required this.text});
  final bool fromMe;
  final String text;
}
