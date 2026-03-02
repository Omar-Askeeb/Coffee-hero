import 'package:flutter/material.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  static const Color orange = Color(0xFFF5A623);

  // ❗ لازم تكون static const أو داخل build لأن Stateless ما ينفعش يكون عنده fields عادية متغيّرة
  static const List<Map<String, dynamic>> chats = [
    {
      'name': 'محمد علي',
      'last': 'وين وصل الطلب؟',
      'unread': 2,
    },
    {
      'name': 'أحمد سالم',
      'last': 'ممكن تعديل الطلب؟',
      'unread': 0,
    },
    {
      'name': 'سارة',
      'last': 'شكراً على الخدمة',
      'unread': 1,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('الرسائل'),
          backgroundColor: orange,
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            itemBuilder: (_, i) {
              final c = chats[i];
              final int unread = (c['unread'] as int?) ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: orange.withOpacity(0.15),
                    child: Text(
                      (c['name'] as String).substring(0, 1),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
                    ),
                  ),
                  title: Text(
                    c['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(c['last']),
                  trailing: unread > 0
                      ? CircleAvatar(
                          radius: 12,
                          backgroundColor: orange,
                          child: Text(
                            unread.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        )
                      : const Icon(Icons.chevron_left, color: Colors.black45),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(name: c['name']),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
