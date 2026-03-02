import 'package:flutter/material.dart';

import 'dashboard_home_screen.dart';
import 'orders/ordersd_screen.dart';
import 'products_screen.dart';
import 'more/more_screen.dart';
import 'package:app_for_me/services/notifications_service.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  static const Color orange = Color(0xFFF5A623);

  int _currentIndex = 0;

  // ✅ ملاحظة: طالما القائمة const لازم كل العناصر تكون const
  final List<Widget> _pages = const [
    DashboardHomeScreen(),        // 0
    DashboardOrdersScreen(),      // 1 ✅ بدل OrdersScreen
    ProductsScreen(),             // 2
    MoreScreen(),                 // 3
  ];

  @override
  void initState() {
    super.initState();
    // ✅ هذا يخلي جهاز الداشبورد يستقبل إشعار "طلب جديد" (topic: dashboard_orders)
    NotificationsService.instance.enableDashboardMode(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'لوحة التحكم',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: orange,
        elevation: 0,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: orange,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'الطلبات'),
          BottomNavigationBarItem(icon: Icon(Icons.fastfood), label: 'المنتجات'),
          BottomNavigationBarItem(icon: Icon(Icons.apps), label: 'المزيد'),
        ],
      ),
    );
  }
}
