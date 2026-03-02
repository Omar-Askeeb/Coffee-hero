import 'package:flutter/material.dart';

import '../categories/categories_screen.dart';
import '../customers_screen.dart';
import '../messages/messages_screen.dart';
import '../reports/reports.dart';
import '../settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const Color orange = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    final items = <_MoreItem>[
      _MoreItem(
        title: 'الأقسام',
        icon: Icons.category,
        builder: (_) => const CategoriesScreen(),
      ),
      _MoreItem(
        title: 'العملاء',
        icon: Icons.people,
        builder: (_) => const CustomersScreen(),
      ),
      _MoreItem(
        title: 'الرسائل',
        icon: Icons.chat,
        builder: (_) => const MessagesScreen(),
      ),
      _MoreItem(
        title: 'التقارير',
        icon: Icons.bar_chart,
        builder: (_) => const ReportsScreen(),
      ),
      _MoreItem(
        title: 'الإعدادات',
        icon: Icons.settings,
        builder: (_) => const SettingsScreen(),
      ),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (_, i) {
        final it = items[i];
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: it.builder),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: orange.withOpacity(0.15),
                  child: Icon(it.icon, color: orange, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  it.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MoreItem {
  final String title;
  final IconData icon;
  final WidgetBuilder builder;

  _MoreItem({
    required this.title,
    required this.icon,
    required this.builder,
  });
}
