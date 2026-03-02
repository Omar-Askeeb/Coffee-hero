import 'package:flutter/material.dart';

import 'package:app_for_me/dashboard/orders/ordersd_screen.dart';
import '../wallet_screen.dart';
import '../chat_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int index = 0;

  // ✅ استبدال OrdersScreen بـ DashboardOrdersScreen
  final List<Widget> pages = const [
    _AdminDashboardScreen(),
    DashboardOrdersScreen(),
    WalletScreen(),
    ChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Row(
          children: [
            Expanded(child: pages[index]),
            Container(
              width: 280,
              color: const Color(0xFF0B6B63),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
                      child: Text(
                        'لوحة التحكم',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        'Admin Dashboard',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    _NavItem(
                      title: 'الرئيسية',
                      icon: Icons.dashboard_outlined,
                      index: 0,
                      currentIndex: index,
                      onTap: () => setState(() => index = 0),
                    ),
                    _NavItem(
                      title: 'الطلبات',
                      icon: Icons.list_alt_outlined,
                      index: 1,
                      currentIndex: index,
                      onTap: () => setState(() => index = 1),
                    ),
                    _NavItem(
                      title: 'المحفظة',
                      icon: Icons.account_balance_wallet_outlined,
                      index: 2,
                      currentIndex: index,
                      onTap: () => setState(() => index = 2),
                    ),
                    _NavItem(
                      title: 'الرسائل',
                      icon: Icons.chat_bubble_outline,
                      index: 3,
                      currentIndex: index,
                      onTap: () => setState(() => index = 3),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                        ),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.logout),
                        label: const Text('رجوع للتطبيق'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  const _NavItem({
    required this.title,
    required this.icon,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == currentIndex;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: active ? Colors.white24 : null,
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (active) const Icon(Icons.chevron_left, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class _AdminDashboardScreen extends StatelessWidget {
  const _AdminDashboardScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('الرئيسية'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _KpiCard(title: 'طلبات اليوم', value: '—'),
              _KpiCard(title: 'مبيعات اليوم', value: '—'),
              _KpiCard(title: 'عملاء جدد', value: '—'),
              _KpiCard(title: 'الطلبات المتأخرة', value: '—'),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'ملحوظة: هذه صفحة Placeholder. ربط البيانات من Firebase يكون لاحقاً.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;

  const _KpiCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        elevation: 1.5,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
